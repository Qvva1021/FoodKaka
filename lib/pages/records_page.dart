import 'package:material_ui/material_ui.dart';

import '../data/food_store.dart';
import '../theme.dart';
import '../widgets/meal_list.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({
    super.key,
    required this.log,
    required this.onDateChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final DayLog log;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onAdd;
  final ValueChanged<Meal> onEdit, onDelete;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        '饮食记录',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text('把每一天的好好吃饭，留在这里', style: TextStyle(color: muted)),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: log.date,
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
          );
          if (date != null) onDateChanged(date);
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(dateKey(log.date)),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当日摄入 ${kcal(log.total)} kcal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '当日预算 ${kcal(log.budget)} kcal · ${log.remaining < 0 ? '超出' : '剩余'} ${kcal(log.remaining.abs())} kcal',
                style: const TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('补记这一天'),
      ),
      MealList(meals: log.meals, onEdit: onEdit, onDelete: onDelete),
    ],
  );
}
