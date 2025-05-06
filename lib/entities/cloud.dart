import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'game_entity.dart';
import '../services/image_service.dart';

class Cloud extends GameEntity {
  static const double SPEED = 50.0;  // 개미핥기기 속도의 절반
  
  Cloud() : super(objectType: GameObjectType.cloud);
  
  @override
  Future<void> onLoad() async {
    size = Vector2(60, 30);
    paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - 250) + 100,  // 벌과 같은 범위의 y좌표
    );
    
    // 커스텀 이미지를 로드하지 않도록 수정
    debugMode = false; // 디버그 모드 비활성화
  }
  
  @override
  void render(Canvas canvas) {
    // 항상 구름 모양으로 그리기
    // 구름의 중앙 부분
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // 구름의 여러 원형 부분 그리기
    canvas.drawCircle(Offset(centerX - 15, centerY), 15, paint);
    canvas.drawCircle(Offset(centerX, centerY - 5), 18, paint);
    canvas.drawCircle(Offset(centerX + 15, centerY), 15, paint);
    canvas.drawCircle(Offset(centerX - 5, centerY + 5), 12, paint);
    canvas.drawCircle(Offset(centerX + 10, centerY + 3), 14, paint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isStopped) return;
    
    position.x -= SPEED * dt;
    
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
} 