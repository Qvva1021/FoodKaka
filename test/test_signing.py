import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('create_signing', Path(__file__).parents[1] / 'scripts' / 'create_signing.py')
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    def test_existing_identity_is_never_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'android').mkdir()
            key = root / 'android' / 'upload-keystore.jks'
            key.write_bytes(b'existing key')
            with self.assertRaises(FileExistsError):
                signing.create_signing(root)
            self.assertEqual(key.read_bytes(), b'existing key')
            self.assertFalse((root / 'android' / 'key.properties').exists())


if __name__ == '__main__':
    unittest.main()
