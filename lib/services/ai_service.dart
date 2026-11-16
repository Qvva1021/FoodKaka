import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../data/food_store.dart';

class AiException implements Exception {
  const AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ServiceConnection {
  const ServiceConnection(this.url, this.token);
  final String url, token;
  Uri validate() {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['', '/'].contains(uri.path)) {
      throw const AiException('请输入完整服务地址，例如 http://192.168.1.10:8000');
    }
    final ip = InternetAddress.tryParse(uri.host);
    final bytes = ip?.rawAddress;
    final lan =
        uri.host == 'localhost' ||
        (bytes != null &&
            bytes.length == 4 &&
            (bytes[0] == 10 ||
                bytes[0] == 127 ||
                (bytes[0] == 192 && bytes[1] == 168) ||
                (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31)));
    if (uri.scheme == 'http' && !lan) {
      throw const AiException('HTTP 仅允许局域网 IP；外网服务必须使用 HTTPS');
    }
    if (token.trim().length < 24 ||
        token.trim().length > 256 ||
        token.contains('\n') ||
        token.contains('\r')) {
      throw const AiException('请输入服务端的个人访问令牌（至少 24 个字符），不要填写模型 API 密钥');
    }
    return uri;
  }
}

class Recognition {
  const Recognition(this.foods, this.notes);
  final List<FoodItem> foods;
  final String notes;
  factory Recognition.parse(dynamic data) {
    if (data is! Map ||
        data['foods'] is! List ||
        (data['foods'] as List).length > 50 ||
        data['notes'] is! String) {
      throw const AiException('服务返回的识别结果格式无效');
    }
    final foods = <FoodItem>[];
    for (final food in data['foods']) {
      if (food is! Map || food['name'] is! String || food['calories'] is! num) {
        throw const AiException('服务返回的食物明细无效');
      }
      final item = FoodItem(food['name'], (food['calories'] as num).toDouble());
      try {
        item.validate();
      } on FormatException {
        throw const AiException('服务返回的热量或食物名称无效');
      }
      foods.add(item);
    }
    final sum = foods.fold<double>(0, (value, food) => value + food.calories);
    final total = data['total_calories'];
    if (!sum.isFinite ||
        total is! num ||
        !total.isFinite ||
        (sum - total).abs() > 0.01) {
      throw const AiException('识别合计与食物明细不一致，请重新识别');
    }
    return Recognition(foods, data['notes']);
  }
}

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _storage = FlutterSecureStorage();

  Future<ServiceConnection?> connection() async {
    final text = await _storage.read(key: 'ai_connection');
    if (text == null) return null;
    final data = jsonDecode(text) as Map;
    return ServiceConnection(data['url'] as String, data['token'] as String);
  }

  Future<void> saveConnection(ServiceConnection connection) async {
    connection.validate();
    await _storage.write(
      key: 'ai_connection',
      value: jsonEncode({
        'url': connection.url.trim(),
        'token': connection.token.trim(),
      }),
    );
  }

  Future<bool> hasConsent() async =>
      await _storage.read(key: 'photo_consent') == 'yes';
  Future<void> saveConsent() =>
      _storage.write(key: 'photo_consent', value: 'yes');

  Future<dynamic> _request(
    ServiceConnection connection,
    String path, [
    Uint8List? image,
  ]) async {
    final uri = connection.validate().replace(path: path);
    try {
      return await (() async {
        final request = http.Request(image == null ? 'GET' : 'POST', uri)
          ..followRedirects = false;
        request.headers['Authorization'] = 'Bearer ${connection.token.trim()}';
        if (image != null) {
          request.headers['Content-Type'] = 'image/jpeg';
          request.bodyBytes = image;
        }
        final response = await _client.send(request);
        final bytes = BytesBuilder();
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 128 * 1024) {
            throw const AiException('服务返回内容过大');
          }
          bytes.add(chunk);
        }
        final dynamic data = jsonDecode(utf8.decode(bytes.takeBytes()));
        if (response.statusCode != 200) {
          final detail = data is Map ? data['detail'] : null;
          throw AiException(
            detail is String && detail.length < 500 ? detail : '识别服务暂不可用，请稍后重试',
          );
        }
        return data;
      })().timeout(Duration(seconds: image == null ? 10 : 60));
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw const AiException('连接超时，请检查电脑服务或手动记账');
    } on FormatException {
      throw const AiException('服务返回格式无效，请检查服务地址');
    } catch (_) {
      throw const AiException('无法连接服务，请确认电脑已开机、同一局域网和服务地址');
    }
  }

  Future<String> health(ServiceConnection connection) async {
    final data = await _request(connection, '/health');
    if (data is! Map || data['status'] != 'ok' || data['message'] is! String) {
      throw const AiException('健康检查返回无效');
    }
    return data['message'];
  }

  Future<Recognition> recognize(Uint8List image) async {
    final settings = await connection();
    if (settings == null) throw const AiException('请先在“我的”中设置 AI 服务连接');
    if (image.isEmpty || image.length > 5 * 1024 * 1024) {
      throw const AiException('图片为空或超过 5 MB，请重新选择');
    }
    return Recognition.parse(await _request(settings, '/recognize', image));
  }

  void close() => _client.close();
}
