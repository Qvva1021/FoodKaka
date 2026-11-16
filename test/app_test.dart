import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_kaka/main.dart';

void main() {
  testWidgets('三个导航页面可以切换，首阶段没有虚假记录或可提交按钮', (tester) async {
    await tester.pumpWidget(const FoodKaKaApp());
    expect(find.text('好好吃饭，慢慢记录'), findsOneWidget);
    expect(find.text('今日剩余额度'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.text('好好吃饭，慢慢记录'), findsNothing);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的小档案'), findsOneWidget);
    expect(find.text('待填写'), findsNWidgets(2));

    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    expect(find.text('好好吃饭，慢慢记录'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏与大字体下三页仍可布局并滚动', (tester) async {
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
        home: const AppShell(),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final label in ['记录', '我的', '今日']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
