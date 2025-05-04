import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'obstacle.dart';

class Bullet extends Obstacle {
  static const double SPEED = 300.0;
  
  Bullet() : super(speed: SPEED);
  
  @override
  Future<void> onLoad() async {
    size = Vector2(20, 10);
    paint = Paint()..color = Colors.red;
    
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - 250) + 100,
    );
    
    await super.onLoad();
  }
  
  @override
  void onOutOfBounds() {
    gameRef.updateScore(10);
    removeFromParent();
  }
} 