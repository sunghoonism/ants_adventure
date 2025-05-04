import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'game_entity.dart';

class Cloud extends GameEntity {
  static const double SPEED = 50.0;  // 지렁이 속도의 절반
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    size = Vector2(60, 30);
    paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - 250) + 100,  // 총알과 같은 범위의 y좌표
    );
  }
  
  @override
  void render(Canvas canvas) {
    // 사각형 대신 둥근 구름 모양 그리기
    final cloudPath = Path();
    
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