@echo off
echo 개미 모험 - 스프라이트 이미지 생성기
echo ==================================
cd ..\..\
if not exist assets\images\ant mkdir assets\images\ant
echo 디렉토리 준비 완료!
flutter run -d windows lib/tools/generate_sprites.dart
echo.
echo 스프라이트 이미지 생성 완료!
dir assets\images\ant
pause 