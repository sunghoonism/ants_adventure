import 'dart:io';
import 'package:flutter/material.dart';
import 'sprite_generator.dart';

/// 스프라이트 생성 도구
/// 
/// 이 도구는 개발 시에만 사용하며, 애셋 폴더에 스프라이트 이미지를 생성합니다.
/// main 함수를 실행하여 스프라이트 이미지를 생성할 수 있습니다.
void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  print('스프라이트 이미지 생성 도구 시작...');
  
  // 애셋 디렉토리 확인 및 생성
  final Directory antDir = Directory('assets/images/ant');
  if (!await antDir.exists()) {
    await antDir.create(recursive: true);
    print('assets/images/ant 디렉토리 생성 완료');
  }
  
  final Directory obstaclesDir = Directory('assets/images/obstacles');
  if (!await obstaclesDir.exists()) {
    await obstaclesDir.create(recursive: true);
    print('assets/images/obstacles 디렉토리 생성 완료');
  }
  
  // 모든 스프라이트 생성
  await SpriteGenerator.generateAllSprites();
  
  print('모든 스프라이트 이미지 생성 완료');
  exit(0); // 프로그램 종료
} 