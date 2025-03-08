@echo off
echo Building Flutter web app in HTML mode...

REM Set environment variables
set FLUTTER_WEB_RENDERER=html

REM Clean and get dependencies
flutter clean
flutter pub get

REM Build the web app
echo Building web app...
flutter build web --release

echo The web app has been built. You can serve it with one of these options:

echo Option 1: Using Node.js http-server (if installed):
echo npm install -g http-server
echo cd build\web
echo http-server

echo Option 2: Using Python:
echo cd build\web
echo python -m http.server 8080

echo Option 3: Using Flutter's built-in server:
echo flutter run -d chrome --web-port=8080 --web-hostname=127.0.0.1

echo.
echo After server is running, open Edge browser and go to http://localhost:8080

pause 