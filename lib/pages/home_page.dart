import 'package:material_ui/material_ui.dart';

import '../data/food_store.dart';
import '../theme.dart';
import '../widgets/rice_ball.dart';
import '../widgets/meal_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.log,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final Profile profile;
  final DayLog log;
  final VoidCallback onAdd;
  final ValueChanged<Meal> onEdit, onDelete;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.date.month}月${log.date.day}日 · 今天',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                Text(
                  '嗨，${profile.nickname}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text('好好吃饭，慢慢记录', style: TextStyle(color: muted)),
              ],
            ),
          ),
          const RiceBall(size: 58),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                log.remaining < 0 ? '今天超出预算' : '今日剩余额度',
                style: const TextStyle(color: muted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox.square(
                dimension: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: (log.total / log.budget).clamp(0, 1),
                        strokeWidth: 12,
                        backgroundColor: mint,
                        color: peach,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              kcal(log.remaining.abs()),
                              key: const Key('remaining'),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Text('kcal', style: TextStyle(color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 8,
                children: [
                  Text('已摄入 ${kcal(log.total)} kcal'),
                  Text('预算 ${kcal(log.budget)} kcal'),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('拍一餐'),
      ),
      const Text(
        '拍照识别将在第三阶段开放',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 12),
      ),
      Center(
        child: TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('手动添加'),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        '今天吃了什么',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      MealList(meals: log.meals, onEdit: onEdit, onDelete: onDelete),
    ],
  );
}
