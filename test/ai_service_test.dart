import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:food_kaka/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const token = 'foodkaka-local-test-token-at-least-24';
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('服务地址只允许局域网HTTP或HTTPS，个人令牌与模型密钥分离', () {
    expect(
      const ServiceConnection(
        'http://192.168.1.10:8000',
        token,
      ).validate().host,
      '192.168.1.10',
    );
    for (final url in [
      'http://example.com',
      'http://192.168.1.1/path',
      'https://user:pass@example.com',
    ]) {
      expect(
        () => ServiceConnection(url, token).validate(),
        throwsA(isA<AiException>()),
      );
    }
    expect(
      () => const ServiceConnection('https://example.com', 'short').validate(),
      throwsA(isA<AiException>()),
    );
  });
  test('仅发送图片、不发送资料，识别结果校验并保留可修改明细', () async {
    final service = AiService(
      client: MockClient((request) async {
        expect(request.url.path, '/recognize');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.bodyBytes, [1, 2, 3]);
        return http.Response(
          jsonEncode({
            'foods': [
              {'name': '米饭', 'calories': 230},
            ],
            'total_calories': 230,
            'notes': '估算样例',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.close);
    await service.saveConnection(
      const ServiceConnection('http://10.0.2.2:8000', token),
    );
    final result = await service.recognize(Uint8List.fromList([1, 2, 3]));
    expect(result.foods.single.calories, 230);
    expect(result.foods.single.name, '米饭');
    expect(await service.hasConsent(), isFalse);
    await service.saveConsent();
    expect(await service.hasConsent(), isTrue);
  });
  test('缺少配置、模型配额错误和不一致合计均不会伪造结果', () async {
    final service = AiService(
      client: MockClient(
        (_) async => http.Response('{"detail":"quota exhausted"}', 429),
      ),
    );
    addTearDown(service.close);
    await expectLater(
      service.recognize(Uint8List.fromList([1])),
      throwsA(isA<AiException>()),
    );
    await service.saveConnection(
      const ServiceConnection('http://10.0.2.2:8000', token),
    );
    await expectLater(
      service.recognize(Uint8List.fromList([1])),
      throwsA(isA<AiException>()),
    );
    expect(
      () => Recognition.parse({
        'foods': [
          {'name': '米饭', 'calories': -1},
        ],
        'total_calories': -1,
        'notes': '',
      }),
      throwsA(isA<AiException>()),
    );
    expect(
      () => Recognition.parse({
        'foods': [
          {'name': '米饭', 'calories': 230},
        ],
        'total_calories': 500,
        'notes': '',
      }),
      throwsA(isA<AiException>()),
    );
  });
}
