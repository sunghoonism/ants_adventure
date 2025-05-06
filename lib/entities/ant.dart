import 'dart:io';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'game_entity.dart';
import 'obstacles/bee.dart';
import 'obstacles/anteater.dart';
import '../services/image_service.dart';

/// 개미 상태
enum AntState {
  walking,  // 걷기 상태
  flying,   // 날개짓 상태
}

class Ant extends GameEntity with CollisionCallbacks {
  static const double GRAVITY = 500.0;
  static const double JUMP_SPEED = -500.0;
  double velocityY = 0.0;
  static const double ANT_SIZE = 32;
  static const double ANT_HEIGHT = 18;
  static const double BOTTOM_OFFSET = 50;
  static const double CEILING_OFFSET = 30;
  
  // 애니메이션
  late final SpriteAnimationComponent walkingAnimation;
  late final SpriteAnimationComponent flyingAnimation;
  AntState currentState = AntState.walking;
  bool hasAnimations = false;
  
  Ant() : super(objectType: GameObjectType.ant);
  
  @override
  bool get hasDefaultSprite => hasAnimations;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(ANT_SIZE, ANT_HEIGHT);
    paint = Paint()..color = Colors.black;
    position = Vector2(100, gameRef.size.y - BOTTOM_OFFSET + ANT_HEIGHT);
    
    // 충돌 박스 추가
    final hitbox = RectangleHitbox(
      size: Vector2(ANT_SIZE, ANT_HEIGHT),
      position: Vector2.zero(),
      isSolid: true,
    );
    add(hitbox);
    
    // 애니메이션 로드 시도
    await createDefaultAnimation();
    
    // 커스텀 이미지 로드 (상위 클래스 onLoad 호출)
    await super.onLoad();
    
    // 애니메이션 상태 최종 업데이트 (커스텀 이미지 로드 이후)
    _updateAnimationState();
  }
  
  @override
  Future<void> createDefaultAnimation() async {
    try {
      // 걷기 애니메이션
      final walkingSpriteSheet = await gameRef.images.load('ant/walking.png');
      final walkingAnimation = SpriteAnimation.fromFrameData(
        walkingSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,         // 4프레임
          textureSize: Vector2(ANT_SIZE, ANT_HEIGHT),
          stepTime: 0.1,     // 0.1초마다 프레임 변경
        ),
      );
      
      // 날개짓 애니메이션
      final flyingSpriteSheet = await gameRef.images.load('ant/flying.png');
      final flyingAnimation = SpriteAnimation.fromFrameData(
        flyingSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,         // 4프레임
          textureSize: Vector2(ANT_SIZE, ANT_HEIGHT),
          stepTime: 0.05,    // 0.05초마다 프레임 변경 (더 빠른 날개짓)
        ),
      );
      
      // 걷기 애니메이션 컴포넌트 생성 및 추가
      this.walkingAnimation = SpriteAnimationComponent(
        animation: walkingAnimation,
        size: size,
        position: Vector2.zero(),
      );
      add(this.walkingAnimation);
      
      // 날개짓 애니메이션 컴포넌트 생성 및 추가
      this.flyingAnimation = SpriteAnimationComponent(
        animation: flyingAnimation,
        size: size,
        position: Vector2.zero(),
      );
      this.flyingAnimation.opacity = 0; // 초기에는 보이지 않음
      add(this.flyingAnimation);
      
      hasAnimations = true;
      _updateAnimationState();
    } catch (e) {
      print('애니메이션 로드 실패: $e');
      hasAnimations = false;
    }
  }
  
  /// 현재 상태에 따라 애니메이션 업데이트
  void _updateAnimationState() {
    if (!hasAnimations) return;
    
    // 커스텀 이미지가 있으면 모든 애니메이션 숨김
    if (hasCustomImage) {
      walkingAnimation.opacity = 0;
      flyingAnimation.opacity = 0;
      return;
    }
    
    // 커스텀 이미지가 없는 경우에만 상태에 따라 애니메이션 변경
    if (currentState == AntState.walking) {
      walkingAnimation.opacity = 1;
      flyingAnimation.opacity = 0;
    } else {
      walkingAnimation.opacity = 0;
      flyingAnimation.opacity = 1;
    }
  }
  
  void reset() {
    position = Vector2(100, gameRef.size.y - BOTTOM_OFFSET + ANT_HEIGHT);
    velocityY = 0;
    currentState = AntState.walking;
    _updateAnimationState();
  }
  
  void jump() {
    velocityY = JUMP_SPEED;
    currentState = AntState.flying;
    _updateAnimationState();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    velocityY += GRAVITY * dt;
    position.y += velocityY * dt;
    
    // 천장 충돌 체크 (두께가 30으로 변경됨)
    if (position.y < CEILING_OFFSET) {
      position.y = CEILING_OFFSET;
      velocityY = 0;
    }
    
    // 바닥 충돌 체크
    if (position.y > gameRef.size.y - BOTTOM_OFFSET - ANT_HEIGHT) {
      position.y = gameRef.size.y - BOTTOM_OFFSET - ANT_HEIGHT;
      velocityY = 0;
      
      // 바닥에 닿으면 걷기 상태로 변경
      if (currentState == AntState.flying) {
        currentState = AntState.walking;
        _updateAnimationState();
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (hasCustomImage && customImage != null) {
      // 커스텀 이미지가 있으면 기본 렌더링만 사용
      super.render(canvas);
    } else if (hasAnimations) {
      // 애니메이션만 자동 렌더링 (SpriteAnimationComponent가 처리)
      // 여기서는 아무 것도 하지 않음
    } else {
      // 둘 다 없는 경우 기본 사각형 렌더링
      super.render(canvas);
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Bee || other is Anteater) {
      gameRef.gameOver();
    }
  }
  
  @override
  Future<void> updateCustomImage() async {
    bool previousHasCustomImage = hasCustomImage;
    await super.updateCustomImage();
    
    // 커스텀 이미지 상태가 변경된 경우에만 상태 업데이트
    if (previousHasCustomImage != hasCustomImage) {
      _updateAnimationState();
    }
  }
} 