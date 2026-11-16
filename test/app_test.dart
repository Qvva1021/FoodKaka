import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_kaka/main.dart';
import 'package:food_kaka/data/food_store.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  late FoodStore store;
  setUp(() async {
    store = await FoodStore.open(path: inMemoryDatabasePath);
  });
  tearDown(() async {
    await store.db.close();
  });

  testWidgets('首次填写资料、BMI实时计算，确认后进入今日', (tester) async {
    await tester.pumpWidget(FoodKaKaApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('先认识一下你'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '小饭团');
    await tester.enterText(fields.at(1), '170');
    await tester.enterText(fields.at(2), '65');
    await tester.enterText(fields.at(3), '1800');
    expect(find.text('BMI：22.5'), findsOneWidget);
    await tester.ensureVisible(find.text('保存并开始记录'));
    await tester.tap(find.text('保存并开始记录'));
    await tester.pumpAndSettle();
    expect(find.text('嗨，小饭团'), findsOneWidget);
    expect(find.byKey(const Key('remaining')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('三页切换、手动输入校验、多食物实时总量及保存', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    await tester.pumpWidget(FoodKaKaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    expect(find.text('饮食记录'), findsOneWidget);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('BMI：22.5'), findsOneWidget);
    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('手动添加'));
    await tester.tap(find.text('手动添加'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确认保存'));
    await tester.tap(find.text('确认保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入食物名称'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '米饭');
    await tester.enterText(find.byType(TextFormField).at(1), '230');
    await tester.ensureVisible(find.text('再加一种食物'));
    await tester.tap(find.text('再加一种食物'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '鸡蛋');
    await tester.enterText(find.byType(TextFormField).at(3), '180');
    await tester.pump();
    expect(find.text('合计 410 kcal'), findsOneWidget);
    await tester.ensureVisible(find.text('确认保存'));
    await tester.tap(find.text('确认保存'));
    await tester.tap(find.text('确认保存'));
    await tester.pumpAndSettle();
    expect((await store.day(DateTime.now())).total, 410);
    expect((await store.day(DateTime.now())).meals, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏与大字体下三页可以布局滚动', (tester) async {
    await store.saveProfile(const Profile('主人', 170, 65, 1800));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AppShell(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['记录', '我的', '今日']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListView).hitTestable(),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
