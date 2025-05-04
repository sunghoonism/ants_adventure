import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import '../entities/ant.dart';
import '../entities/cloud.dart';
import '../entities/obstacles/bullet.dart';
import '../entities/obstacles/worm.dart';

class AntsAdventureGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Ant ant;
  late TextComponent scoreText;
  TextComponent? gameOverText;
  int score = 0;
  double bulletTimer = 0.0;
  double wormTimer = 0.0;
  double cloudTimer = 0.0;
  double cloudSpawnInterval = 0.0;
  bool isGameOver = false;
  
  @override
  Future<void> onLoad() async {
    // 디버그 모드 비활성화
    debugMode = false;
    
    // 구름 생성 간격 초기화 (2~5초 사이)
    resetCloudInterval();
    
    // 배경 설정
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF87CEEB),
      ),
    );
    
    // 천장 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 30),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 바닥 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 50),
        position: Vector2(0, size.y - 50),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 개미 생성 및 추가
    ant = Ant();
    add(ant);
    
    // 점수 텍스트
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
  }
  
  void resetCloudInterval() {
    // 2~5초 사이의 랜덤한 시간 간격
    cloudSpawnInterval = 2.0 + math.Random().nextDouble() * 3.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;
    
    // 총알 생성 타이머
    bulletTimer += dt;
    if (bulletTimer >= 1.0) {
      bulletTimer = 0.0;
      add(Bullet());
    }
    
    // 지렁이 생성 타이머
    wormTimer += dt;
    if (wormTimer >= 10.0) {
      wormTimer = 0.0;
      add(Worm());
    }
    
    // 구름 생성 타이머
    cloudTimer += dt;
    if (cloudTimer >= cloudSpawnInterval) {
      cloudTimer = 0.0;
      add(Cloud());
      resetCloudInterval();  // 새로운 간격으로 재설정
    }
  }
  
  @override
  bool onTapDown(TapDownInfo info) {
    if (isGameOver) {
      restartGame();
      return true;
    }
    ant.jump();
    return true;
  }
  
  void updateScore(int points) {
    if (isGameOver) return;
    score += points;
    scoreText.text = 'Score: $score';
  }
  
  void gameOver() {
    if (isGameOver) return;  // 중복 호출 방지
    
    isGameOver = true;
    
    // 게임오버 메시지 표시
    gameOverText = TextComponent(
      text: 'GAME OVER\nTap to restart',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gameOverText!);
    
    // 모든 총알과 지렁이의 움직임 정지
    children.whereType<Bullet>().forEach((bullet) => bullet.stop());
    children.whereType<Worm>().forEach((worm) => worm.stop());
    children.whereType<Cloud>().forEach((cloud) => cloud.stop());
  }
  
  void restartGame() {
    isGameOver = false;
    if (gameOverText != null) {
      gameOverText!.removeFromParent();
      gameOverText = null;
    }
    score = 0;
    scoreText.text = 'Score: 0';
    ant.reset();
    // 모든 총알과 지렁이 및 구름 제거
    children.whereType<Bullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<Worm>().forEach((worm) => worm.removeFromParent());
    children.whereType<Cloud>().forEach((cloud) => cloud.removeFromParent());
  }
} 