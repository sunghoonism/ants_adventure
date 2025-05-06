import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'obstacle.dart';
import '../../services/image_service.dart';

class Bee extends Obstacle {
  // 상수값 정의
  static const double BASE_SPEED = 300.0;
  static const double BEE_WIDTH = 32.0;
  static const double BEE_HEIGHT = 12.0;
  static const int FRAMES_COUNT = 4;
  static const double FRAME_STEP_TIME = 0.1;
  static const double Y_POSITION_MIN = 40.0;
  static const double Y_POSITION_RANGE = 150.0;
  
  // 벌 애니메이션 컴포넌트
  SpriteAnimationComponent? beeAnimation;
  bool hasAnimation = false;
  
  Bee({double speedMultiplier = 1.0}) : super(
    speed: BASE_SPEED * speedMultiplier, 
    objectType: GameObjectType.bee
  );
  
  @override
  bool get hasDefaultSprite => hasAnimation;
  
  @override
  Future<void> onLoad() async {
    // 크기 및 색상 설정
    size = Vector2(BEE_WIDTH, BEE_HEIGHT);
    paint = Paint()..color = Colors.yellow;
    
    // 위치 설정
    final random = math.Random();
    position = Vector2(
      gameRef.size.x,
      random.nextDouble() * (gameRef.size.y - Y_POSITION_RANGE) + Y_POSITION_MIN,
    );
    
    // 부모 클래스의 onLoad 호출하여 커스텀 이미지 로드
    await super.onLoad();
    
    // 커스텀 이미지가 없을 경우에만 애니메이션 생성
    if (!hasCustomImage) {
      // 기본 스프라이트 애니메이션 생성
      await createDefaultAnimation();
    }
  }
  
  @override
  Future<void> createDefaultAnimation() async {
    try {
      // 벌 애니메이션 로드
      final beeSpriteSheet = await gameRef.images.load('obstacles/bee.png');
      final beeAnim = SpriteAnimation.fromFrameData(
        beeSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: FRAMES_COUNT,
          textureSize: Vector2(BEE_WIDTH, BEE_HEIGHT),
          stepTime: FRAME_STEP_TIME,
        ),
      );
      
      // 사이즈 조정 (벌 이미지에 맞춤)
      size = Vector2(BEE_WIDTH, BEE_HEIGHT);
      
      // 애니메이션 컴포넌트 생성 및 추가
      beeAnimation = SpriteAnimationComponent(
        animation: beeAnim,
        size: size,
        position: Vector2.zero(),
      );
      
      // 커스텀 이미지가 있으면 애니메이션 숨기기
      if (hasCustomImage) {
        beeAnimation!.opacity = 0;
      }
      
      add(beeAnimation!);
      
      hasAnimation = true;
    } catch (e) {
      print('벌 애니메이션 로드 실패: $e');
      hasAnimation = false;
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (hasCustomImage && customImage != null) {
      // 커스텀 이미지가 있으면 기본 렌더링만 사용
      super.render(canvas);
    } else if (hasAnimation) {
      // 애니메이션만 자동 렌더링 (SpriteAnimationComponent가 처리)
      // 여기서는 아무 것도 하지 않음
    } else {
      // 둘 다 없는 경우 기본 사각형 렌더링
      super.render(canvas);
    }
  }
  
  @override
  Future<void> updateCustomImage() async {
    // 기존 상태 저장
    final bool previousHasCustomImage = hasCustomImage;
    
    // 부모 메소드 호출하여 커스텀 이미지 업데이트
    await super.updateCustomImage();
    
    // 애니메이션이 있으면 커스텀 이미지 상태에 따라 표시 여부 업데이트
    if (hasAnimation && beeAnimation != null) {
      // 커스텀 이미지가 있으면 애니메이션 숨기기
      beeAnimation!.opacity = hasCustomImage ? 0 : 1;
      print('벌 애니메이션 ${hasCustomImage ? "숨김" : "표시"} 처리됨');
      
      // 상태가 변경된 경우에만 로깅
      if (previousHasCustomImage != hasCustomImage) {
        print('벌 커스텀 이미지 상태 변경: $previousHasCustomImage -> $hasCustomImage');
      }
    }
  }
  
  @override
  void onOutOfBounds() {
    gameRef.updateScore(10);
    removeFromParent();
  }
} 