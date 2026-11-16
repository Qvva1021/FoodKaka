import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/rice_ball.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late DateTime _today;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateDate();
  }

  void _updateDate() {
    _today = DateTime.now();
    _midnightTimer?.cancel();
    final midnight = DateTime(_today.year, _today.month, _today.day + 1);
    _midnightTimer = Timer(midnight.difference(_today), () {
      if (mounted) setState(_updateDate);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_updateDate);
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_today.month}月${_today.day}日 · 今天',
                  style: const TextStyle(color: muted, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '好好吃饭，慢慢记录',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const RiceBall(size: 58),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '今日剩余额度',
                style: TextStyle(color: muted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox.square(
                dimension: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: 0,
                        strokeWidth: 12,
                        backgroundColor: mint,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '—',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                        ),
                        const Text('kcal', style: TextStyle(color: muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '设置每日预算后，在这里看剩余额度',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 8,
                children: [Text('已摄入  — kcal'), Text('每日预算  — kcal')],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text(
          '拍一餐',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      const Center(child: TextButton(onPressed: null, child: Text('手动添加'))),
      const Text(
        '记账将在第二阶段开放，拍照识别将在第三阶段开放',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: muted),
      ),
      const SizedBox(height: 28),
      const Text(
        '今天吃了什么',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.restaurant_rounded, color: muted, size: 30),
              SizedBox(height: 12),
              Text(
                '还没有记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text('每一餐，都值得好好记下', style: TextStyle(color: muted)),
            ],
          ),
        ),
      ),
    ],
  );
}
