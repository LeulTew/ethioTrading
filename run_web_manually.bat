@echo off
echo Building Flutter web app in HTML mode...
flutter clean
flutter pub get

set FLUTTER_WEB_RENDERER=html
echo Building web output...
flutter build web --release

echo Serving the built app on localhost:8080...
cd build\web
python -m http.server 8080

pause 