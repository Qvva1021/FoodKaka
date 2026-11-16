import 'package:material_ui/material_ui.dart';

import '../data/food_store.dart';

class MealEditor extends StatefulWidget {
  const MealEditor({
    super.key,
    required this.store,
    required this.date,
    this.meal,
    this.initialFoods,
    this.notes,
  });
  final FoodStore store;
  final DateTime date;
  final Meal? meal;
  final List<FoodItem>? initialFoods;
  final String? notes;
  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _FoodFields {
  _FoodFields([FoodItem? food])
    : name = TextEditingController(text: food?.name),
      calories = TextEditingController(text: food?.calories.toString());
  final TextEditingController name, calories;
  void dispose() {
    name.dispose();
    calories.dispose();
  }
}

class _MealEditorState extends State<MealEditor> {
  final _form = GlobalKey<FormState>();
  late DateTime _date;
  late String _type;
  late final List<_FoodFields> _foods;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.meal?.date ?? widget.date;
    _type = widget.meal?.type ?? mealTypes[1];
    _foods =
        (widget.meal?.foods ?? widget.initialFoods)
            ?.map(_FoodFields.new)
            .toList() ??
        [_FoodFields()];
  }

  @override
  void dispose() {
    for (final food in _foods) {
      food.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.saveMeal(
        Meal(
          id: widget.meal?.id,
          date: _date,
          type: _type,
          foods: _foods
              .map((f) => FoodItem(f.name.text, double.parse(f.calories.text)))
              .toList(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，输入已保留，请稍后重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _foods.fold<double>(
      0,
      (sum, f) => sum + (double.tryParse(f.calories.text) ?? 0),
    );
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.meal == null ? '记下一餐' : '修改这一餐')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.notes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('图片估算，确认后才记账。${widget.notes}'),
                ),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(1970),
                          lastDate: widget.store.now(),
                        );
                        if (date != null && mounted) {
                          setState(() => _date = date);
                        }
                      },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dateKey(_date)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '餐次'),
                items: mealTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 20),
              for (final food in _foods)
                Padding(
                  key: ObjectKey(food),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: food.name,
                            enabled: !_saving,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: '食物名称',
                              hintText: '例如：米饭',
                            ),
                            validator: (text) =>
                                text == null || text.trim().isEmpty
                                ? '请输入食物名称'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: food.calories,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: '热量（kcal）',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (text) {
                              final number = double.tryParse(text ?? '');
                              return number == null ||
                                      !number.isFinite ||
                                      number < 0
                                  ? '请输入有限的非负热量'
                                  : null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _saving || _foods.length == 1
                                  ? null
                                  : () {
                                      setState(() => _foods.remove(food));
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                            (_) => food.dispose(),
                                          );
                                    },
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('移除食物'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => setState(() => _foods.add(_FoodFields())),
                icon: const Icon(Icons.add),
                label: const Text('再加一种食物'),
              ),
              const SizedBox(height: 20),
              Text(
                '合计 ${total.isFinite ? kcal(total) : '—'} kcal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '正在保存…' : '确认保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
