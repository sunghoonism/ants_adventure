import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 간단한 스프라이트 시트 생성기
class SpriteGenerator {
  /// 걷기 애니메이션 스프라이트 시트 생성
  static Future<void> generateWalkingSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 전체 캔버스 크기 (4프레임)
    final width = 32 * 4;
    final height = 18;
    
    // 배경 (투명)
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);
    
    // 개미 그리기
    final antPaint = Paint()..color = Colors.black;
    
    // 프레임 1: 기본 자세
    _drawAntFrame(canvas, 0, antPaint, 0);
    
    // 프레임 2: 왼쪽 다리 움직임
    _drawAntFrame(canvas, 1, antPaint, 1);
    
    // 프레임 3: 기본 자세
    _drawAntFrame(canvas, 2, antPaint, 0);
    
    // 프레임 4: 오른쪽 다리 움직임
    _drawAntFrame(canvas, 3, antPaint, 2);
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // assets 폴더로 저장
      final String assetPath = 'assets/images/ant/walking.png';
      final File assetFile = File(assetPath);
      
      // 파일 디렉토리가 있는지 확인
      final Directory directory = Directory(assetFile.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 기존 파일이 있으면 삭제
      if (await assetFile.exists()) {
        print('기존 걷기 스프라이트 시트 파일 삭제...');
        await assetFile.delete();
      }
      
      // 스프라이트 시트 저장
      await assetFile.writeAsBytes(pngBytes);
      
      // 파일이 정상적으로 생성되었는지 확인
      if (await assetFile.exists()) {
        print('걷기 스프라이트 시트 생성 완료: ${assetFile.absolute.path}');
        print('파일 크기: ${await assetFile.length()} 바이트');
      } else {
        print('오류: 걷기 스프라이트 시트 생성 실패!');
      }
    }
  }
  
  /// 날개짓 애니메이션 스프라이트 시트 생성
  static Future<void> generateFlyingSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 전체 캔버스 크기 (4프레임)
    final width = 32 * 4;
    final height = 18;
    
    // 배경 (투명)
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);
    
    // 개미 그리기
    final antPaint = Paint()..color = Colors.black;
    final wingPaint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // 프레임 1: 날개 위치 1
    _drawAntWithWingsFrame(canvas, 0, antPaint, wingPaint, 0);
    
    // 프레임 2: 날개 위치 2
    _drawAntWithWingsFrame(canvas, 1, antPaint, wingPaint, 1);
    
    // 프레임 3: 날개 위치 3
    _drawAntWithWingsFrame(canvas, 2, antPaint, wingPaint, 2);
    
    // 프레임 4: 날개 위치 4
    _drawAntWithWingsFrame(canvas, 3, antPaint, wingPaint, 3);
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // assets 폴더로 저장
      final String assetPath = 'assets/images/ant/flying.png';
      final File assetFile = File(assetPath);
      
      // 파일 디렉토리가 있는지 확인
      final Directory directory = Directory(assetFile.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 기존 파일이 있으면 삭제
      if (await assetFile.exists()) {
        print('기존 날개짓 스프라이트 시트 파일 삭제...');
        await assetFile.delete();
      }
      
      // 스프라이트 시트 저장
      await assetFile.writeAsBytes(pngBytes);
      
      // 파일이 정상적으로 생성되었는지 확인
      if (await assetFile.exists()) {
        print('날개짓 스프라이트 시트 생성 완료: ${assetFile.absolute.path}');
        print('파일 크기: ${await assetFile.length()} 바이트');
      } else {
        print('오류: 날개짓 스프라이트 시트 생성 실패!');
      }
    }
  }
  
  /// 벌 애니메이션 스프라이트 시트 생성
  static Future<void> generateBeeSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 전체 캔버스 크기 (4프레임)
    final width = 32 * 4;
    final height = 12; // 32에서 12로 변경 (위아래 여백 10픽셀씩 제거)
    
    // 배경 (투명)
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);
    
    // 벌 그리기
    final beePaint = Paint()..color = Color(0xFFFFD700);  // 황금색
    final blackPaint = Paint()..color = Colors.black;
    
    // 4개 프레임의 벌 애니메이션
    for (int i = 0; i < 4; i++) {
      _drawBeeFrame(canvas, i, beePaint, blackPaint, i);
    }
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // assets 폴더로 저장
      final String assetPath = 'assets/images/obstacles/bee.png';
      final File assetFile = File(assetPath);
      
      // 파일 디렉토리가 있는지 확인
      final Directory directory = Directory(assetFile.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 기존 파일이 있으면 삭제
      if (await assetFile.exists()) {
        print('기존 벌 스프라이트 시트 파일 삭제...');
        await assetFile.delete();
      }
      
      // 스프라이트 시트 저장
      await assetFile.writeAsBytes(pngBytes);
      
      // 파일이 정상적으로 생성되었는지 확인
      if (await assetFile.exists()) {
        print('벌 스프라이트 시트 생성 완료: ${assetFile.absolute.path}');
        print('파일 크기: ${await assetFile.length()} 바이트');
      } else {
        print('오류: 벌 스프라이트 시트 생성 실패!');
      }
    }
  }
  
  /// 개미핥기 스프라이트 시트 생성
  static Future<void> generateAnteaterSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 전체 캔버스 크기 (4프레임)
    final width = 48 * 4;  // 개미핥기는 더 크게
    final height = 28; // 32에서 28로 변경 (위쪽 여백 4픽셀 제거)
    
    // 배경 (투명)
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);
    
    // 개미핥기 그리기
    final bodyPaint = Paint()..color = Color(0xFF8B4513);  // 갈색
    final nosePaint = Paint()..color = Color(0xFFA0522D);  // 짙은 갈색
    
    // 4개 프레임의 개미핥기 애니메이션
    for (int i = 0; i < 4; i++) {
      _drawAnteaterFrame(canvas, i, bodyPaint, nosePaint, i);
    }
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // assets 폴더로 저장
      final String assetPath = 'assets/images/obstacles/anteater.png';
      final File assetFile = File(assetPath);
      
      // 파일 디렉토리가 있는지 확인
      final Directory directory = Directory(assetFile.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 기존 파일이 있으면 삭제
      if (await assetFile.exists()) {
        print('기존 개미핥기 스프라이트 시트 파일 삭제...');
        await assetFile.delete();
      }
      
      // 스프라이트 시트 저장
      await assetFile.writeAsBytes(pngBytes);
      
      // 파일이 정상적으로 생성되었는지 확인
      if (await assetFile.exists()) {
        print('개미핥기 스프라이트 시트 생성 완료: ${assetFile.absolute.path}');
        print('파일 크기: ${await assetFile.length()} 바이트');
      } else {
        print('오류: 개미핥기 스프라이트 시트 생성 실패!');
      }
    }
  }
  
  /// 걷기 애니메이션의 개미 프레임 그리기 (오른쪽 방향)
  static void _drawAntFrame(Canvas canvas, int frameIndex, Paint paint, int legPosition) {
    final frameX = frameIndex * 32.0;
    final centerX = frameX + 16.0;
    final centerY = 10.0; // 여백을 늘려서 18픽셀 높이 내에서 중앙 위치 조정
    
    // 개미 몸체 (좌우로 길게)
    // 머리
    canvas.drawCircle(Offset(centerX + 8, centerY), 4, paint);
    
    // 가슴 (중간 부분)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, centerY), width: 8, height: 7), paint);
    
    // 배 (뒷 부분)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 8, centerY), width: 10, height: 8), paint);
    
    // 더듬이 (머리 위에 배치, 길이 늘림)
    canvas.drawLine(Offset(centerX + 7, centerY - 2), Offset(centerX + 12, centerY - 6), paint);
    canvas.drawLine(Offset(centerX + 9, centerY - 2), Offset(centerX + 14, centerY - 5), paint);
    
    // 날개 (걸을 때는 살짝 보이게)
    final wingPaint = Paint()..color = Colors.black.withOpacity(0.3);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, centerY - 3), width: 8, height: 2), wingPaint);
    
    // 다리 (가슴에 4개, 배에 2개)
    final legOffsetY = legPosition == 0 ? 0 : (legPosition == 1 ? 1 : -1);
    
    // 가슴 앞쪽 다리 (2개)
    canvas.drawLine(Offset(centerX + 3, centerY + 2), Offset(centerX + 6, centerY + 8 + legOffsetY), paint);
    canvas.drawLine(Offset(centerX + 3, centerY + 2), Offset(centerX + 8, centerY + 7), paint);
    
    // 가슴 뒤쪽 다리 (2개)
    canvas.drawLine(Offset(centerX - 1, centerY + 3), Offset(centerX - 3, centerY + 8 - legOffsetY), paint);
    canvas.drawLine(Offset(centerX - 1, centerY + 3), Offset(centerX + 1, centerY + 9), paint);
    
    // 배 부분 다리 (2개)
    canvas.drawLine(Offset(centerX - 6, centerY + 3), Offset(centerX - 8, centerY + 9 + legOffsetY), paint);
    canvas.drawLine(Offset(centerX - 6, centerY + 3), Offset(centerX - 10, centerY + 8), paint);
  }
  
  /// 날개짓 애니메이션의 개미 프레임 그리기 (오른쪽 방향)
  static void _drawAntWithWingsFrame(Canvas canvas, int frameIndex, Paint bodyPaint, Paint wingPaint, int wingPosition) {
    final frameX = frameIndex * 32.0;
    final centerX = frameX + 16.0;
    final centerY = 10.0; // 높이를 18픽셀로 맞추기 위해 중앙 위치 조정
    
    // 개미 몸체 (좌우로 길게)
    // 머리
    canvas.drawCircle(Offset(centerX + 8, centerY), 4, bodyPaint);
    
    // 가슴 (중간 부분)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, centerY), width: 8, height: 7), bodyPaint);
    
    // 배 (뒷 부분)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 8, centerY), width: 10, height: 8), bodyPaint);
    
    // 더듬이 (머리 위에 배치, 길이 늘림)
    canvas.drawLine(Offset(centerX + 7, centerY - 2), Offset(centerX + 12, centerY - 6), bodyPaint);
    canvas.drawLine(Offset(centerX + 9, centerY - 2), Offset(centerX + 14, centerY - 5), bodyPaint);
    
    // 다리 (접은 상태, 가슴에 4개, 배에 2개)
    // 가슴 앞쪽 다리 (2개)
    canvas.drawLine(Offset(centerX + 3, centerY + 3), Offset(centerX + 5, centerY + 5), bodyPaint);
    canvas.drawLine(Offset(centerX + 2, centerY + 3), Offset(centerX + 4, centerY + 6), bodyPaint);
    
    // 가슴 뒤쪽 다리 (2개)
    canvas.drawLine(Offset(centerX - 1, centerY + 3), Offset(centerX - 3, centerY + 5), bodyPaint);
    canvas.drawLine(Offset(centerX - 1, centerY + 3), Offset(centerX + 1, centerY + 6), bodyPaint);
    
    // 배 부분 다리 (2개)
    canvas.drawLine(Offset(centerX - 6, centerY + 3), Offset(centerX - 8, centerY + 5), bodyPaint);
    canvas.drawLine(Offset(centerX - 6, centerY + 3), Offset(centerX - 9, centerY + 6), bodyPaint);
    
    // 날개 그리기 (위치에 따라 다름, 파닥거리는 모습을 더 선명하게)
    double wingAngle = 0;
    double wingOpacity = 0.7; // 더 선명하게
    
    switch (wingPosition) {
      case 0:
        wingAngle = -0.4; // 더 많이 위로
        break;
      case 1:
        wingAngle = -0.1; // 거의 수평
        break;
      case 2:
        wingAngle = 0.4; // 더 많이 아래로
        break;
      case 3:
        wingAngle = 0.1; // 거의 수평 (다시)
        break;
    }
    
    // 왼쪽 날개 (더 크게)
    final leftWingPaint = Paint()..color = Colors.black.withOpacity(wingOpacity);
    final leftWingPath = Path();
    leftWingPath.moveTo(centerX - 2, centerY - 2);
    leftWingPath.lineTo(centerX - 8, centerY - 8 + (wingAngle * 10));
    leftWingPath.lineTo(centerX - 10, centerY - 2 + (wingAngle * 6));
    leftWingPath.close();
    canvas.drawPath(leftWingPath, leftWingPaint);
    
    // 오른쪽 날개는 제거함
  }
  
  /// 벌 프레임 그리기 (왼쪽 방향)
  static void _drawBeeFrame(Canvas canvas, int frameIndex, Paint yellowPaint, Paint blackPaint, int wingPosition) {
    final frameX = frameIndex * 32.0;
    final centerX = frameX + 16.0;
    final centerY = 6.0; // 16에서 6으로 변경 (중앙 위치 조정, 위아래 여백 10픽셀씩 제거)
    
    // 벌 몸체 (타원형)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, centerY), width: 15, height: 10), yellowPaint);
    
    // 벌 줄무늬
    for (int i = 0; i < 3; i++) {
      double stripeX = centerX - 3 + (i * 3);
      canvas.drawRect(
        Rect.fromLTWH(stripeX, centerY - 4, 2, 8),
        blackPaint,
      );
    }
    
    // 벌 머리 (왼쪽 방향)
    canvas.drawCircle(Offset(centerX - 8, centerY), 4, blackPaint);
    
    // 벌의 눈
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(centerX - 9, centerY - 1), 1, eyePaint);
    
    // 더듬이 (왼쪽 방향)
    canvas.drawLine(Offset(centerX - 10, centerY - 2), Offset(centerX - 12, centerY - 4), blackPaint);
    
    // 벌침
    canvas.drawLine(Offset(centerX + 7, centerY), Offset(centerX + 10, centerY), blackPaint);
    
    // 벌의 날개 위치 (프레임에 따라 다름)
    double wingOffset = 0;
    switch (wingPosition % 4) {
      case 0: wingOffset = -2; break;
      case 1: wingOffset = -1; break;
      case 2: wingOffset = 0; break;
      case 3: wingOffset = -1; break;
    }
    
    // 벌의 날개
    final wingPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // 위쪽 날개
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY - 5 + wingOffset), width: 12, height: 5),
      wingPaint,
    );
    
    // 아래쪽 날개
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + 2, centerY + 2 + wingOffset), width: 10, height: 4),
      wingPaint,
    );
  }
  
  /// 개미핥기 프레임 그리기 (왼쪽 방향)
  static void _drawAnteaterFrame(Canvas canvas, int frameIndex, Paint bodyPaint, Paint nosePaint, int legPosition) {
    final frameX = frameIndex * 48.0; // 개미핥기는 더 큰 프레임
    final centerX = frameX + 24.0;
    final centerY = 14.0; // 16에서 14로 변경 (중앙 위치 조정, 위쪽 여백 4픽셀 제거)
    
    // 개미핥기 몸체 (더 큰 타원형)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, centerY), width: 30, height: 14), bodyPaint);
    
    // 개미핥기 머리 (왼쪽 방향)
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 12, centerY - 2), width: 12, height: 8), bodyPaint);
    
    // 개미핥기 코 (길고 가는 형태)
    final nosePath = Path();
    nosePath.moveTo(centerX - 18, centerY - 2);
    nosePath.lineTo(centerX - 30, centerY - 3);
    nosePath.lineTo(centerX - 30, centerY);
    nosePath.lineTo(centerX - 18, centerY - 1);
    nosePath.close();
    canvas.drawPath(nosePath, nosePaint);
    
    // 개미핥기 눈
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 14, centerY - 4), 1.5, eyePaint);
    
    // 귀
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 10, centerY - 7), width: 4, height: 6), bodyPaint);
    
    // 다리 (4개) - 프레임에 따라 다른 위치
    final legOffsetY = (legPosition % 4) * 0.7;
    
    // 앞다리
    canvas.drawLine(Offset(centerX - 12, centerY + 7), Offset(centerX - 15, centerY + 14 - legOffsetY), bodyPaint);
    canvas.drawLine(Offset(centerX - 5, centerY + 7), Offset(centerX - 7, centerY + 14 + legOffsetY), bodyPaint);
    
    // 뒷다리
    canvas.drawLine(Offset(centerX + 5, centerY + 7), Offset(centerX + 3, centerY + 14 - legOffsetY), bodyPaint);
    canvas.drawLine(Offset(centerX + 12, centerY + 7), Offset(centerX + 15, centerY + 14 + legOffsetY), bodyPaint);
    
    // 꼬리
    final tailPath = Path();
    tailPath.moveTo(centerX + 15, centerY);
    tailPath.quadraticBezierTo(centerX + 20, centerY - 5, centerX + 18, centerY - 10);
    canvas.drawPath(tailPath, bodyPaint);
  }
  
  /// 모든 스프라이트 시트 생성
  static Future<void> generateAllSprites() async {
    // 걷기 애니메이션 스프라이트 생성
    await generateWalkingSprite();
    
    // 날개짓 애니메이션 스프라이트 생성
    await generateFlyingSprite();
    
    // 벌 애니메이션 스프라이트 생성
    await generateBeeSprite();
    
    // 개미핥기 애니메이션 스프라이트 생성
    await generateAnteaterSprite();
    
    print('모든 스프라이트 생성 완료');
  }
} 