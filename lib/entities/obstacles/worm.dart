import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'obstacle.dart';

class Worm extends Obstacle {
  static const double SPEED = 100.0;
  
  Worm() : super(speed: SPEED);
  
  @override
  Future<void> onLoad() async {
    size = Vector2(40, 20);
    paint = Paint()..color = Colors.green;
    
    position = Vector2(
      gameRef.size.x,
      gameRef.size.y - 70,
    );
    
    await super.onLoad();
  }
  
  @override
  void onOutOfBounds() {
    gameRef.updateScore(30);
    removeFromParent();
  }
} 