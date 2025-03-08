@echo off
echo Cleaning Flutter project...
flutter clean

echo Getting dependencies...
flutter pub get

echo Setting environment variables for HTML renderer...
set FLUTTER_WEB_RENDERER=html

echo Running Flutter web on Chrome...
flutter run -d chrome

pause
