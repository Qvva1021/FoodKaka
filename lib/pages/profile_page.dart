import 'package:material_ui/material_ui.dart';

import '../data/food_store.dart';
import '../theme.dart';
import '../widgets/rice_ball.dart';
import 'connection_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.store,
    required this.profile,
    required this.onSaved,
  });
  final FoodStore store;
  final Profile? profile;
  final Future<void> Function() onSaved;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nickname, _height, _weight, _budget;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.profile?.nickname);
    _height = TextEditingController(text: widget.profile?.height.toString());
    _weight = TextEditingController(text: widget.profile?.weight.toString());
    _budget = TextEditingController(text: widget.profile?.budget.toString());
  }

  @override
  void dispose() {
    for (final field in [_nickname, _height, _weight, _budget]) {
      field.dispose();
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
      await widget.store.saveProfile(
        Profile(
          _nickname.text,
          double.parse(_height.text),
          double.parse(_weight.text),
          double.parse(_budget.text),
        ),
      );
      await widget.onSaved();
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('资料已保存')));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，输入已保留，请重试';
        });
      }
    }
  }

  Widget _number(
    String label,
    TextEditingController controller,
    double min,
    double max,
  ) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      validator: (text) {
        final number = double.tryParse(text ?? '');
        return number == null ||
                !number.isFinite ||
                number < min ||
                number > max
            ? '请输入 $min 到 $max 之间的有效数值'
            : null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final height = double.tryParse(_height.text),
        weight = double.tryParse(_weight.text);
    final bmi =
        height != null &&
            height.isFinite &&
            height >= 30 &&
            weight != null &&
            weight.isFinite &&
            weight > 0
        ? (weight / ((height / 100) * (height / 100))).toStringAsFixed(1)
        : '—';
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.profile == null ? '先认识一下你' : '我的小档案',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Center(child: RiceBall(size: 76)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nickname,
            enabled: !_saving,
            maxLength: 40,
            decoration: const InputDecoration(labelText: '昵称'),
            validator: (text) =>
                text == null || text.trim().isEmpty ? '请输入昵称' : null,
          ),
          _number('身高（cm）', _height, 30, 300),
          _number('体重（kg）', _weight, 1, 1000),
          const SizedBox(height: 16),
          Text(
            'BMI：$bmi',
            key: const Key('bmi'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          _number('每日热量预算（kcal）', _budget, 1, 100000),
          const SizedBox(height: 12),
          const Text(
            '预算由你设置；修改后用于今天及以后，过去日期的预算保持不变。',
            style: TextStyle(color: muted),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving
                  ? '正在保存…'
                  : widget.profile == null
                  ? '保存并开始记录'
                  : '保存资料',
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectionPage()),
            ),
            icon: const Icon(Icons.wifi_outlined),
            label: const Text('AI 服务连接与测试'),
          ),
          const Text(
            '记账始终保存在本机；照片仅在点击识别后联网发送。',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}
