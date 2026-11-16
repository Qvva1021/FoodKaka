$ErrorActionPreference = 'Stop'
$FlutterArgs = @($args)
if (-not $FlutterArgs.Count) { $FlutterArgs = @('doctor', '-v') }
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolsRoot = Join-Path $projectRoot '.tools'
$flutterCommand = Join-Path $toolsRoot 'flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutterCommand)) {
    throw 'Flutter SDK is missing. See README.md for setup.'
}

$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:PUB_CACHE = Join-Path $toolsRoot 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $toolsRoot 'gradle-cache'
$env:ANDROID_HOME = Join-Path $toolsRoot 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $toolsRoot 'android-user'
$env:ANDROID_AVD_HOME = Join-Path $env:ANDROID_USER_HOME 'avd'
if (-not $env:JAVA_HOME) {
    $javaCommand = Get-Command java -ErrorAction Stop
    $env:JAVA_HOME = Split-Path (Split-Path $javaCommand.Source -Parent) -Parent
}
$env:Path = "$toolsRoot\flutter\bin;$env:ANDROID_HOME\platform-tools;$env:JAVA_HOME\bin;$env:Path"

Push-Location $projectRoot
try {
    & $flutterCommand @FlutterArgs
    $result = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $result
