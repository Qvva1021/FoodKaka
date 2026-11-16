import 'package:sqflite/sqflite.dart';

const mealTypes = ['早餐', '午餐', '晚餐', '加餐'];
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String kcal(double value) => value.toStringAsFixed(0);

class Profile {
  const Profile(this.nickname, this.height, this.weight, this.budget);
  final String nickname;
  final double height, weight, budget;
  double get bmi => weight / ((height / 100) * (height / 100));
  void validate() {
    if (nickname.trim().isEmpty ||
        nickname.trim().length > 40 ||
        !height.isFinite ||
        height < 30 ||
        height > 300 ||
        !weight.isFinite ||
        weight < 1 ||
        weight > 1000 ||
        !budget.isFinite ||
        budget <= 0 ||
        budget > 100000) {
      throw const FormatException('请检查昵称、身高、体重与预算的有效范围');
    }
  }
}

class FoodItem {
  const FoodItem(this.name, this.calories);
  final String name;
  final double calories;
  void validate() {
    if (name.trim().isEmpty ||
        name.trim().length > 100 ||
        !calories.isFinite ||
        calories < 0) {
      throw const FormatException('食物名称不能为空，热量必须是有限的非负数');
    }
  }
}

class Meal {
  const Meal({
    this.id,
    required this.date,
    required this.type,
    required this.foods,
  });
  final int? id;
  final DateTime date;
  final String type;
  final List<FoodItem> foods;
  double get total => foods.fold(0, (sum, food) => sum + food.calories);
}

class DayLog {
  const DayLog(this.date, this.budget, this.meals);
  final DateTime date;
  final double budget;
  final List<Meal> meals;
  double get total => meals.fold(0, (sum, meal) => sum + meal.total);
  double get remaining => budget - total;
}

class FoodStore {
  FoodStore(this.db, {DateTime Function()? now}) : now = now ?? DateTime.now;
  final Database db;
  final DateTime Function() now;

  static Future<FoodStore> open({
    String? path,
    DateTime Function()? now,
  }) async {
    final db = await openDatabase(
      path ?? '${await getDatabasesPath()}/foodkaka.db',
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE user_profile (id INTEGER PRIMARY KEY CHECK(id = 1), nickname TEXT NOT NULL, height_cm REAL NOT NULL CHECK(height_cm > 0), default_budget REAL NOT NULL CHECK(default_budget > 0), updated_at TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE weight_records (id INTEGER PRIMARY KEY, weight_kg REAL NOT NULL CHECK(weight_kg > 0), record_date TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE daily_budgets (id INTEGER PRIMARY KEY, budget_date TEXT NOT NULL UNIQUE, budget_kcal REAL NOT NULL CHECK(budget_kcal > 0))',
        );
        await db.execute(
          "CREATE TABLE meal_records (id INTEGER PRIMARY KEY, meal_date TEXT NOT NULL, meal_type TEXT NOT NULL CHECK(meal_type IN ('早餐','午餐','晚餐','加餐')), created_at TEXT NOT NULL)",
        );
        await db.execute(
          'CREATE TABLE food_items (id INTEGER PRIMARY KEY, meal_id INTEGER NOT NULL REFERENCES meal_records(id) ON DELETE CASCADE, food_name TEXT NOT NULL CHECK(length(trim(food_name)) > 0), calories REAL NOT NULL CHECK(calories >= 0))',
        );
        await db.execute(
          'CREATE INDEX meals_by_date ON meal_records(meal_date)',
        );
        await db.execute('CREATE INDEX foods_by_meal ON food_items(meal_id)');
      },
    );
    return FoodStore(db, now: now);
  }

  Future<Profile?> profile() async {
    final rows = await db.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) return null;
    final weights = await db.query(
      'weight_records',
      orderBy: 'record_date DESC, id DESC',
      limit: 1,
    );
    final row = rows.single;
    return Profile(
      row['nickname'] as String,
      (row['height_cm'] as num).toDouble(),
      (weights.single['weight_kg'] as num).toDouble(),
      (row['default_budget'] as num).toDouble(),
    );
  }

  // Fill unused days before changing the default so their old budgets remain intact.
  Future<void> _fillBudgets(Transaction tx, double budget) async {
    final rows = await tx.query(
      'daily_budgets',
      orderBy: 'budget_date DESC',
      limit: 1,
    );
    final today = DateTime(now().year, now().month, now().day);
    var day = rows.isEmpty
        ? today
        : DateTime.parse(rows.single['budget_date'] as String);
    final batch = tx.batch();
    while (!day.isAfter(today)) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO daily_budgets(budget_date,budget_kcal) VALUES (?,?)',
        [dateKey(day), budget],
      );
      day = DateTime(day.year, day.month, day.day + 1);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveProfile(Profile profile) async {
    profile.validate();
    await db.transaction((tx) async {
      final old = await tx.query('user_profile', where: 'id = 1');
      await _fillBudgets(
        tx,
        old.isEmpty
            ? profile.budget
            : (old.single['default_budget'] as num).toDouble(),
      );
      final row = {
        'nickname': profile.nickname.trim(),
        'height_cm': profile.height,
        'default_budget': profile.budget,
        'updated_at': now().toIso8601String(),
      };
      if (old.isEmpty) {
        await tx.insert('user_profile', {'id': 1, ...row});
      } else {
        await tx.update('user_profile', row, where: 'id = 1');
      }
      final weight = await tx.query(
        'weight_records',
        orderBy: 'record_date DESC, id DESC',
        limit: 1,
      );
      if (weight.isEmpty ||
          (weight.single['weight_kg'] as num).toDouble() != profile.weight) {
        await tx.insert('weight_records', {
          'weight_kg': profile.weight,
          'record_date': dateKey(now()),
        });
      }
      await tx.update(
        'daily_budgets',
        {'budget_kcal': profile.budget},
        where: 'budget_date = ?',
        whereArgs: [dateKey(now())],
      );
    });
  }

  Future<double> _ensureBudget(Transaction tx, DateTime date) async {
    final profile = await tx.query('user_profile', where: 'id = 1');
    if (profile.isEmpty) throw StateError('请先填写个人资料');
    await _fillBudgets(
      tx,
      (profile.single['default_budget'] as num).toDouble(),
    );
    var rows = await tx.query(
      'daily_budgets',
      where: 'budget_date = ?',
      whereArgs: [dateKey(date)],
    );
    if (rows.isEmpty) {
      final earliest = await tx.query(
        'daily_budgets',
        orderBy: 'budget_date',
        limit: 1,
      );
      await tx.insert('daily_budgets', {
        'budget_date': dateKey(date),
        'budget_kcal': earliest.single['budget_kcal'],
      });
      rows = earliest;
    }
    return (rows.single['budget_kcal'] as num).toDouble();
  }

  Future<DayLog> day(DateTime date) => db.transaction((tx) async {
    final budget = await _ensureBudget(tx, date);
    final rows = await tx.query(
      'meal_records',
      where: 'meal_date = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'created_at, id',
    );
    final meals = <Meal>[];
    for (final row in rows) {
      final foods = await tx.query(
        'food_items',
        where: 'meal_id = ?',
        whereArgs: [row['id']],
        orderBy: 'id',
      );
      meals.add(
        Meal(
          id: row['id'] as int,
          date: date,
          type: row['meal_type'] as String,
          foods: foods
              .map(
                (f) => FoodItem(
                  f['food_name'] as String,
                  (f['calories'] as num).toDouble(),
                ),
              )
              .toList(),
        ),
      );
    }
    return DayLog(date, budget, meals);
  });

  Future<void> saveMeal(Meal meal) async {
    if (!mealTypes.contains(meal.type) ||
        meal.foods.isEmpty ||
        !meal.total.isFinite ||
        dateKey(meal.date).compareTo(dateKey(now())) > 0) {
      throw const FormatException('请填写有效餐次、日期和至少一种食物');
    }
    for (final food in meal.foods) {
      food.validate();
    }
    await db.transaction((tx) async {
      await _ensureBudget(tx, meal.date);
      final values = {'meal_date': dateKey(meal.date), 'meal_type': meal.type};
      final int id;
      if (meal.id == null) {
        id = await tx.insert('meal_records', {
          ...values,
          'created_at': now().toIso8601String(),
        });
      } else {
        id = meal.id!;
        if (await tx.update(
              'meal_records',
              values,
              where: 'id = ?',
              whereArgs: [id],
            ) !=
            1) {
          throw StateError('这条记录已不存在，请返回刷新');
        }
        await tx.delete('food_items', where: 'meal_id = ?', whereArgs: [id]);
      }
      for (final food in meal.foods) {
        await tx.insert('food_items', {
          'meal_id': id,
          'food_name': food.name.trim(),
          'calories': food.calories,
        });
      }
    });
  }

  Future<void> deleteMeal(int id) => db.transaction((tx) async {
    await tx.delete('meal_records', where: 'id = ?', whereArgs: [id]);
  });
}
