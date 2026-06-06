$env:PATH = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;$env:PATH"
$env:JAVA_HOME = "$env:USERPROFILE\.jdks\jdk-17"
$env:PATH = "$env:JAVA_HOME\bin;$env:USERPROFILE\flutter\bin;$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:PATH"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:USERPROFILE\flutter\bin\flutter.bat" config --jdk-dir "$env:USERPROFILE\.jdks\jdk-17" 2>&1 | Out-Null
$sdk = $env:ANDROID_HOME -replace "\\","\\"; $fl = "$env:USERPROFILE\flutter" -replace "\\","\\"
"sdk.dir=$sdk`nflutter.sdk=$fl`nflutter.buildMode=release`nflutter.versionName=1.0.0`nflutter.versionCode=1" | Set-Content "android\local.properties"
Set-Location $PSScriptRoot
flutter clean
flutter pub get
flutter build apk --release
$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) { Write-Host "SUCCESS! $apk" -ForegroundColor Green; Start-Process explorer.exe (Split-Path $apk) } else { Write-Host "Build failed - check errors above" -ForegroundColor Red }
