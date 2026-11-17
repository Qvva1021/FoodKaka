"""Create a local personal release key once; never replace an existing identity."""
import os
from pathlib import Path
import secrets
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def create_signing(root=ROOT):
    key = root / 'android' / 'upload-keystore.jks'
    settings = root / 'android' / 'key.properties'
    if key.exists() or settings.exists():
        raise FileExistsError('Signing files already exist. Preserve or restore them; do not generate a replacement.')
    java_home = os.environ.get('JAVA_HOME')
    keytool = str(Path(java_home) / 'bin' / 'keytool.exe') if java_home else shutil.which('keytool')
    if not keytool:
        raise RuntimeError('A JDK with keytool is required.')
    store_password, key_password = secrets.token_urlsafe(32), secrets.token_urlsafe(32)
    env = {**os.environ, 'FOODKAKA_STORE_PASS': store_password, 'FOODKAKA_KEY_PASS': key_password}
    subprocess.run([keytool, '-genkeypair', '-keystore', str(key), '-alias', 'foodkaka',
                    '-keyalg', 'RSA', '-keysize', '3072', '-validity', '10000', '-storetype', 'JKS',
                    '-storepass:env', 'FOODKAKA_STORE_PASS', '-keypass:env', 'FOODKAKA_KEY_PASS',
                    '-dname', 'CN=FoodKaKa, O=Personal, C=CN'], env=env, check=True)
    # Exclusive creation protects an existing local signing configuration.
    with settings.open('x', encoding='utf-8', newline='\n') as file:
        file.write(f'storeFile=upload-keystore.jks\nkeyAlias=foodkaka\nstorePassword={store_password}\nkeyPassword={key_password}\n')
    print('Personal signing files created locally; secret values are not displayed.')


if __name__ == '__main__':
    create_signing()
