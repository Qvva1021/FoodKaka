import 'package:material_ui/material_ui.dart';

import '../data/food_store.dart';
import '../theme.dart';

class MealList extends StatelessWidget {
  const MealList({
    super.key,
    required this.meals,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Meal> meals;
  final ValueChanged<Meal> onEdit, onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (meals.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '还没有记录，每一餐都值得好好记下',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ),
        ),
      for (final type in mealTypes)
        for (final meal in meals.where((m) => m.type == type))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$type · ${kcal(meal.total)} kcal',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final food in meal.foods)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(food.name)),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${kcal(food.calories)} kcal',
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => onEdit(meal),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('修改'),
                        ),
                        TextButton.icon(
                          onPressed: () => onDelete(meal),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('删除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    ],
  );
}
