import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../data/food_store.dart';
import '../services/ai_service.dart';
import '../theme.dart';
import 'meal_editor.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key, required this.store});
  final FoodStore store;
  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _picker = ImagePicker();
  final _service = AiService();
  final _temporaryFiles = <String>{};
  Uint8List? _image;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recover();
  }

  Future<void> _recover() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.exception != null) throw response.exception!;
      if (mounted && response.files?.isNotEmpty == true) {
        await _prepare(response.files!.first);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '上次拍照未完成，请重新拍摄或选图');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cleanup() async {
    for (final path in _temporaryFiles.toList()) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        /* Cache files can also be reclaimed by Android. */
      }
      _temporaryFiles.remove(path);
    }
  }

  Future<void> _prepare(XFile file) async {
    final cache = await getTemporaryDirectory();
    final source = File(file.path).absolute;
    if (source.path.startsWith(
      '${cache.absolute.path}${Platform.pathSeparator}',
    )) {
      _temporaryFiles.add(source.path);
    }
    try {
      if (await file.length() > 20 * 1024 * 1024) {
        throw const AiException('原图过大，请选择小于 20 MB 的图片');
      }
      final bytes = await FlutterImageCompress.compressWithList(
        await file.readAsBytes(),
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const AiException('图片压缩后仍过大，请重新选择');
      }
      if (mounted) {
        setState(() {
          _image = bytes;
          _error = null;
        });
      }
    } finally {
      await _cleanup();
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _image = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (file != null) await _prepare(file);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AiException
              ? error.message
              : '无法打开相机或相册，请检查权限后重试',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recognize() async {
    if (_busy || _image == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await _service.connection() == null) {
        throw const AiException('请先在“我的 → AI 服务连接”中填写电脑服务地址');
      }
      if (!await _service.hasConsent()) {
        if (!mounted) return;
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('发送餐食照片进行识别？'),
            content: const Text(
              '照片会发送到你配置的电脑服务及所选第三方模型。免费模型服务可能将图片用于产品改进。只发送当前餐食照片，不发送身高、体重或历史记录。请避免拍到人像或敏感内容。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('同意并识别'),
              ),
            ],
          ),
        );
        if (accepted != true) return;
        await _service.saveConsent();
      }
      final result = await _service.recognize(_image!);
      if (!mounted) return;
      if (result.foods.isEmpty) {
        setState(
          () =>
              _error = result.notes.isEmpty ? '没有辨认出食物，请重拍或手动添加' : result.notes,
        );
        return;
      }
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MealEditor(
            store: widget.store,
            date: widget.store.now(),
            initialFoods: result.foods,
            notes: result.notes,
          ),
        ),
      );
      if (mounted && saved == true) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AiException
              ? error.message
              : '识别失败，没有保存记录。可以重试或手动添加。',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _service.close();
    unawaited(_cleanup());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('拍一餐')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('拍清楚整份食物，热量会先供你确认，不会自动记账。', style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('拍照'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('从相册选择'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(_image!, height: 280, fit: BoxFit.contain),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('正在处理，请稍候…', textAlign: TextAlign.center),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_error!),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy || _image == null ? null : _recognize,
          child: const Text('识别这一餐'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealEditor(
                        store: widget.store,
                        date: widget.store.now(),
                      ),
                    ),
                  );
                  if (mounted && saved == true) {
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
          child: const Text('改为手动添加'),
        ),
        const Text(
          '单张照片无法准确判断重量和油糖用量，请在下一页核对、修改后保存。',
          style: TextStyle(color: muted),
        ),
      ],
    ),
  );
}
