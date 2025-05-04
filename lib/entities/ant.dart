import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'game_entity.dart';
import 'obstacles/bullet.dart';
import 'obstacles/worm.dart';

class Ant extends GameEntity with CollisionCallbacks {
  static const double GRAVITY = 500.0;
  static const double JUMP_SPEED = -500.0;
  double velocityY = 0.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    size = Vector2(40, 40);
    paint = Paint()..color = Colors.black;
    position = Vector2(100, gameRef.size.y - 90);
    
    // 충돌 박스 추가
    final hitbox = RectangleHitbox(
      size: Vector2(40, 40),
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
  }
  
  void reset() {
    position = Vector2(100, gameRef.size.y - 90);
    velocityY = 0;
  }
  
  void jump() {
    velocityY = JUMP_SPEED;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    velocityY += GRAVITY * dt;
    position.y += velocityY * dt;
    
    // 천장 충돌 체크 (두께가 30으로 변경됨)
    if (position.y < 30) {
      position.y = 30;
      velocityY = 0;
    }
    
    // 바닥 충돌 체크
    if (position.y > gameRef.size.y - 90) {
      position.y = gameRef.size.y - 90;
      velocityY = 0;
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Bullet || other is Worm) {
      gameRef.gameOver();
    }
  }
} 