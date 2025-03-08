@echo off
echo Setting up Flutter web with HTML renderer for Edge...

REM Clean and get dependencies
flutter clean
flutter pub get

REM Set environment variables for HTML renderer
set FLUTTER_WEB_RENDERER=html
set FLUTTER_WEB_USE_SKIA=false

REM Run Flutter on Edge
echo Running Flutter on Edge (HTML renderer)...
flutter run -d edge

pause 