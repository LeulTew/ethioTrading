@echo off
echo Running Flutter app on Edge with HTML renderer...
flutter clean
flutter pub get
flutter run -d edge --web-renderer html --no-sound-null-safety
pause