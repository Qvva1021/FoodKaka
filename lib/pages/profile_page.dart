import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/rice_ball.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        '我的小档案',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text('从认识自己开始', style: TextStyle(color: muted)),
      const SizedBox(height: 24),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              RiceBall(size: 64),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '你好，主人',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('你的专属饮食记账本', style: TextStyle(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _detail('身高', '待填写'),
              const Divider(height: 28),
              _detail('体重', '待填写'),
              const Divider(height: 28),
              _detail('BMI', '—'),
              const Divider(height: 28),
              _detail('每日热量预算', '待设置'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '个人资料填写与 BMI 计算将在第二阶段开放。',
        style: TextStyle(color: muted, height: 1.6),
      ),
      const SizedBox(height: 28),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined, color: muted),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 服务尚未接入',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text('第三阶段开放；本地记账将独立运行。', style: TextStyle(color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),
      const Text(
        '饭咔咔 FoodKaKa · 第一阶段',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );

  Widget _detail(String label, String value) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 24,
    runSpacing: 8,
    children: [
      Text(label, style: const TextStyle(fontSize: 16)),
      Text(value, style: const TextStyle(color: muted, fontSize: 16)),
    ],
  );
}
