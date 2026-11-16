import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_kaka/data/food_store.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late FoodStore store;
  late Directory directory;
  late DateTime clock;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('foodkaka-test-');
    clock = DateTime(2026, 11, 16, 12);
    store = await FoodStore.open(
      path: '${directory.path}/test.db',
      now: () => clock,
    );
  });
  tearDown(() async {
    await store.db.close();
    await directory.delete(recursive: true);
  });

  test('五张表、BMI、重启后资料和食物持久化', () async {
    await store.saveProfile(const Profile('小饭团', 170, 65, 1800));
    await store.saveMeal(
      Meal(date: clock, type: '早餐', foods: const [FoodItem('早餐', 350)]),
    );
    await store.saveMeal(
      Meal(
        date: clock,
        type: '午餐',
        foods: const [FoodItem('米饭', 230), FoodItem('菜', 470)],
      ),
    );
    expect((await store.profile())!.bmi, closeTo(22.4913, 0.001));
    expect((await store.day(clock)).total, 1050);
    expect((await store.day(clock)).remaining, 750);
    await store.db.close();
    store = await FoodStore.open(
      path: '${directory.path}/test.db',
      now: () => clock,
    );
    expect((await store.profile())!.nickname, '小饭团');
    expect((await store.day(clock)).meals.length, 2);
    final tables = await store.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    expect(tables.length, 5);
  });

  test('修改、移动日期、删除级联与超预算结果', () async {
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    await store.saveMeal(
      Meal(date: clock, type: '午餐', foods: const [FoodItem('一餐', 2000)]),
    );
    var day = await store.day(clock);
    expect(day.remaining, -200);
    final id = day.meals.single.id;
    await store.saveMeal(
      Meal(
        id: id,
        date: clock.subtract(const Duration(days: 1)),
        type: '晚餐',
        foods: const [FoodItem('修正', 500)],
      ),
    );
    expect((await store.day(clock)).total, 0);
    expect(
      (await store.day(clock.subtract(const Duration(days: 1)))).total,
      500,
    );
    await store.deleteMeal(id!);
    expect(await store.db.query('food_items'), isEmpty);
    expect((await store.day(clock.subtract(const Duration(days: 1)))).total, 0);
  });

  test('跨日预算、未打开日期与修改默认预算的快照', () async {
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    clock = DateTime(2026, 11, 19, 12);
    await store.saveProfile(const Profile('主人', 170, 64, 1600));
    expect((await store.day(DateTime(2026, 11, 17))).budget, 1800);
    expect((await store.day(clock)).budget, 1600);
    clock = DateTime(2026, 11, 20);
    expect((await store.day(clock)).budget, 1600);
    await store.day(clock);
    final duplicate = await store.db.rawQuery(
      'SELECT budget_date, count(*) AS c FROM daily_budgets GROUP BY budget_date HAVING c > 1',
    );
    expect(duplicate, isEmpty);
    expect(await store.db.query('weight_records'), hasLength(2));
  });

  test('信任边界拒绝无效输入，不留下空餐次', () async {
    await expectLater(
      store.saveProfile(const Profile('', 0, 65, double.nan)),
      throwsFormatException,
    );
    expect(await store.profile(), isNull);
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    for (final food in [
      const FoodItem('', 10),
      const FoodItem('负数', -1),
      const FoodItem('无穷', double.infinity),
      const FoodItem('无效', double.nan),
    ]) {
      await expectLater(
        store.saveMeal(Meal(date: clock, type: '午餐', foods: [food])),
        throwsFormatException,
      );
    }
    expect(await store.db.query('meal_records'), isEmpty);
  });

  test('事务中的明细写入失败会回滚原有食物和餐次', () async {
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    await store.saveMeal(
      Meal(date: clock, type: '午餐', foods: const [FoodItem('原始', 500)]),
    );
    final original = (await store.day(clock)).meals.single;
    await store.db.execute(
      "CREATE TRIGGER reject_test_food BEFORE INSERT ON food_items WHEN NEW.food_name='失败样例' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      store.saveMeal(
        Meal(
          id: original.id,
          date: clock,
          type: '晚餐',
          foods: const [FoodItem('失败样例', 300)],
        ),
      ),
      throwsA(anything),
    );
    final retained = (await store.day(clock)).meals.single;
    expect(retained.type, '午餐');
    expect(retained.foods.single.name, '原始');
    expect(retained.total, 500);
  });
}
