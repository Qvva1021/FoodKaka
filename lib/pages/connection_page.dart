import 'package:material_ui/material_ui.dart';

import '../services/ai_service.dart';
import '../theme.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});
  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _service = AiService();
  final _url = TextEditingController(), _token = TextEditingController();
  bool _busy = true;
  String _status = '正在读取连接设置…';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final connection = await _service.connection();
      if (!mounted) return;
      _url.text = connection?.url ?? '';
      _token.text = connection?.token ?? '';
      setState(() {
        _busy = false;
        _status = connection == null ? '尚未配置 AI 服务' : '已保存连接，点击测试以查看服务状态';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '读取连接失败，请重新填写并保存';
        });
      }
    }
  }

  Future<void> _save(bool test) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = test ? '正在测试服务连接…' : '正在保存…';
    });
    try {
      final connection = ServiceConnection(_url.text, _token.text);
      await _service.saveConnection(connection);
      final result = test ? await _service.health(connection) : '连接已安全保存在本机';
      if (mounted) setState(() => _status = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error is AiException ? error.message : '保存失败，请重试',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI 服务连接')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '手机与电脑连接同一局域网，电脑运行识别服务。电脑关闭后仍可手动记账。',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _url,
          enabled: !_busy,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '电脑服务地址',
            hintText: 'http://192.168.1.10:8000',
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _token,
          enabled: !_busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: '个人访问令牌',
            helperText: '填写 FOODKAKA_TOKEN，模型 API 密钥只放电脑端',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : () => _save(false),
          child: const Text('保存连接'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _save(true),
          child: const Text('保存并测试连接'),
        ),
        const SizedBox(height: 16),
        Text(_status, key: const Key('connection_status')),
      ],
    ),
  );
}
