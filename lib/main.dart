import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameWidget.controlled(
          gameFactory: AntsAdventureGame.new,
        ),
      ),
    ),
  );
}

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
    
    // 천장 추가 (두께 100으로 증가)
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
    
    // 점수 텍스트 (위치를 아래로 이동)
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 30),  // 천장 아래로 이동
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

class Ant extends RectangleComponent with HasGameRef<AntsAdventureGame>, CollisionCallbacks {
  static const double GRAVITY = 500.0;
  static const double JUMP_SPEED = -500.0;
  double velocityY = 0.0;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40);
    paint = Paint()..color = Colors.black;
    position = Vector2(100, gameRef.size.y - 90);
    
    // 충돌 박스 추가 (크기와 위치를 명시적으로 지정)
    final hitbox = RectangleHitbox(
      size: Vector2(40, 40),
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
    
    // 디버그 모드 비활성화
    debugMode = false;
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

class Bullet extends RectangleComponent with HasGameRef<AntsAdventureGame>, CollisionCallbacks {
  static const double SPEED = 300.0;
  bool isStopped = false;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(20, 10);
    paint = Paint()..color = Colors.red;
    
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - 250) + 100,
    );
    
    // 충돌 박스 추가 (크기와 위치를 명시적으로 지정)
    final hitbox = RectangleHitbox(
      size: Vector2(20, 10),
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
    
    // 디버그 모드 비활성화
    debugMode = false;
  }
  
  void stop() {
    isStopped = true;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isStopped) return;
    
    position.x -= SPEED * dt;
    
    if (position.x < -size.x) {
      gameRef.updateScore(10);
      removeFromParent();
    }
  }
}

class Worm extends RectangleComponent with HasGameRef<AntsAdventureGame>, CollisionCallbacks {
  static const double SPEED = 100.0;
  bool isStopped = false;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(40, 20);
    paint = Paint()..color = Colors.green;
    
    position = Vector2(
      gameRef.size.x,
      gameRef.size.y - 70,
    );
    
    // 충돌 박스 추가 (크기와 위치를 명시적으로 지정)
    final hitbox = RectangleHitbox(
      size: Vector2(40, 20),
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
    
    // 디버그 모드 비활성화
    debugMode = false;
  }
  
  void stop() {
    isStopped = true;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isStopped) return;
    
    position.x -= SPEED * dt;
    
    if (position.x < -size.x) {
      gameRef.updateScore(30);
      removeFromParent();
    }
  }
}

class Cloud extends RectangleComponent with HasGameRef<AntsAdventureGame> {
  static const double SPEED = 50.0;  // 지렁이 속도의 절반
  bool isStopped = false;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(60, 30);
    paint = Paint()..color = const Color(0xDDFFFFFF)
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - 250) + 100,  // 총알과 같은 범위의 y좌표
    );
    
    // 디버그 모드 비활성화
    debugMode = false;
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
  
  void stop() {
    isStopped = true;
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
