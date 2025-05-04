import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_entity.dart';

/// 게임 내 모든 장애물의 기본 클래스
abstract class Obstacle extends GameEntity with CollisionCallbacks {
  final double speed;
  
  Obstacle({required this.speed});
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 충돌 박스 추가
    final hitbox = RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isStopped) return;
    
    position.x -= speed * dt;
    
    checkOutOfBounds();
  }
  
  /// 화면 밖으로 나갔는지 확인
  void checkOutOfBounds() {
    if (position.x < -size.x) {
      onOutOfBounds();
    }
  }
  
  /// 화면 밖으로 나갔을 때 호출되는 메서드
  void onOutOfBounds();
} 