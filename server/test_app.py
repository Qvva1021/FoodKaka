import asyncio
import io
import json
import os
import unittest
from unittest.mock import AsyncMock, patch

import httpx
from fastapi import HTTPException
from fastapi.testclient import TestClient
from PIL import Image

from server import app as relay

TOKEN = 'foodkaka-test-token-for-local-tests-only'
HEADERS = {'Authorization': 'Bearer ' + TOKEN, 'Content-Type': 'image/jpeg'}
ENV = {'FOODKAKA_TOKEN': TOKEN, 'AI_PROVIDER': 'gemini', 'GEMINI_API_KEY': 'unit-test-key',
       'GEMINI_MODEL': 'gemini-3.5-flash-lite', 'GEMINI_FREE_TIER_CONFIRMED': 'true'}


def photo():
    output = io.BytesIO()
    image = Image.new('RGB', (64, 64), 'white')
    exif = Image.Exif()
    exif[270] = 'test metadata to remove'
    image.save(output, 'JPEG', exif=exif)
    return output.getvalue()


class RelayTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, ENV)
        self.env.start()
        self.addCleanup(self.env.stop)
        self.client = TestClient(relay.app)
        self.addCleanup(self.client.close)

    def test_authentication_and_health_readiness(self):
        self.assertEqual(self.client.get('/health').status_code, 401)
        self.assertTrue(self.client.get('/health', headers=HEADERS).json()['ready'])
        with patch.dict(os.environ, {'GEMINI_FREE_TIER_CONFIRMED': 'false'}):
            self.assertFalse(self.client.get('/health', headers=HEADERS).json()['ready'])
            self.assertEqual(self.client.post('/recognize', headers=HEADERS, content=photo()).status_code, 503)

    def test_upload_success_and_recomputed_total(self):
        text = '```json\n' + json.dumps({'foods': [{'name': '米饭', 'calories': 230}, {'name': '鸡蛋', 'calories': 180}], 'total_calories': 999, 'notes': '测试样例'}) + '\n```'
        with patch.object(relay, 'request_model', AsyncMock(return_value=text)) as model:
            response = self.client.post('/recognize', headers=HEADERS, content=photo())
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()['total_calories'], 410)
            model.assert_awaited_once()

    def test_invalid_and_oversized_images_never_call_model(self):
        with patch.object(relay, 'request_model', AsyncMock()) as model:
            self.assertEqual(self.client.post('/recognize', headers=HEADERS, content=b'not an image').status_code, 415)
            self.assertEqual(self.client.post('/recognize', headers=HEADERS, content=b'x' * (relay.MAX_BYTES + 1)).status_code, 413)
            self.assertEqual(self.client.post('/recognize', headers={**HEADERS, 'Content-Type': 'text/plain'}, content=photo()).status_code, 415)
            model.assert_not_awaited()

    def test_exif_removed_and_image_readable(self):
        cleaned = relay.clean_image(photo())
        with Image.open(io.BytesIO(cleaned)) as image:
            self.assertEqual(image.format, 'JPEG')
            self.assertEqual(dict(image.getexif()), {})

    def test_malformed_model_results_rejected(self):
        for calories in [-1, float('inf'), float('nan'), True, '230']:
            with self.subTest(calories=calories):
                with self.assertRaises(ValueError):
                    relay.normalize_result(json.dumps({'foods': [{'name': '食物', 'calories': calories}]}))
        with patch.object(relay, 'request_model', AsyncMock(return_value='invalid JSON')):
            self.assertEqual(self.client.post('/recognize', headers=HEADERS, content=photo()).status_code, 502)
        self.assertEqual(relay.normalize_result('{"foods":[],"total_calories":0,"notes":"不是食物"}')['foods'], [])

    def test_gemini_quota_exhaustion_has_no_paid_fallback(self):
        calls = []
        def handler(request):
            calls.append(request)
            return httpx.Response(429, json={'error': {'message': 'quota'}})
        original = httpx.AsyncClient
        with patch.object(relay.httpx, 'AsyncClient', side_effect=lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs)):
            with self.assertRaises(HTTPException) as error:
                asyncio.run(relay.request_model(photo()))
        self.assertEqual(error.exception.status_code, 429)
        self.assertEqual(len(calls), 1)
        self.assertIn('/gemini-3.5-flash-lite:generateContent', str(calls[0].url))

    def test_openrouter_only_free_visual_models_and_no_fallback(self):
        calls = []
        def handler(request):
            calls.append(request)
            if request.method == 'GET':
                return httpx.Response(200, json={'data': [{'id': 'example/vision:free', 'architecture': {'input_modalities': ['image', 'text']}, 'pricing': {'prompt': '0', 'completion': '0'}}]})
            body = json.loads(request.content)
            self.assertFalse(body['provider']['allow_fallbacks'])
            self.assertNotIn('models', body)
            return httpx.Response(200, json={'choices': [{'message': {'content': '{"foods":[],"total_calories":0,"notes":"测试"}'}}]})
        original = httpx.AsyncClient
        with patch.dict(os.environ, {'AI_PROVIDER': 'openrouter', 'OPENROUTER_API_KEY': 'test-key', 'OPENROUTER_MODEL': 'example/vision:free'}):
            with patch.object(relay.httpx, 'AsyncClient', side_effect=lambda **kwargs: original(transport=httpx.MockTransport(handler), **kwargs)):
                self.assertIn('foods', asyncio.run(relay.request_model(photo())))
            with patch.dict(os.environ, {'OPENROUTER_MODEL': 'example/paid'}):
                with self.assertRaises(HTTPException):
                    relay.model_settings()
        self.assertEqual(len(calls), 2)


if __name__ == '__main__':
    unittest.main()
