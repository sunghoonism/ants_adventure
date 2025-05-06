import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'obstacle.dart';
import '../../services/image_service.dart';

class Anteater extends Obstacle {
  // 상수값 정의
  static const double BASE_SPEED = 100.0;
  static const double ANTEATER_WIDTH = 70.0;
  static const double ANTEATER_HEIGHT = 28.0;
  static const int FRAMES_COUNT = 4;
  static const double FRAME_STEP_TIME = 0.15;
  static const double TEXTURE_WIDTH = 48.0;
  static const double TEXTURE_HEIGHT = 28.0;
  static const double FLOOR_OFFSET = 78.0; // 바닥이 50픽셀 두께이고 개미핥기 높이가 28픽셀이므로 조정
  
  // 개미핥기 애니메이션 컴포넌트
  SpriteAnimationComponent? anteaterAnimation;
  bool hasAnimation = false;
  
  Anteater({double speedMultiplier = 1.0}) : super(
    speed: BASE_SPEED * speedMultiplier,
    objectType: GameObjectType.anteater
  );
  
  @override
  bool get hasDefaultSprite => hasAnimation;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(ANTEATER_WIDTH, ANTEATER_HEIGHT);
    paint = Paint()..color = Colors.brown;
    
    // 개미핥기가 바닥 위에 정확히 위치하도록 조정
    position = Vector2(
      gameRef.size.x,
      gameRef.size.y - FLOOR_OFFSET,
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
      // 개미핥기 애니메이션 로드
      final anteaterSpriteSheet = await gameRef.images.load('obstacles/anteater.png');
      final anteaterAnim = SpriteAnimation.fromFrameData(
        anteaterSpriteSheet,
        SpriteAnimationData.sequenced(
          amount: FRAMES_COUNT,
          textureSize: Vector2(TEXTURE_WIDTH, TEXTURE_HEIGHT),
          stepTime: FRAME_STEP_TIME,
        ),
      );
      
      // 사이즈 조정 (개미핥기 이미지에 맞춤)
      size = Vector2(ANTEATER_WIDTH, ANTEATER_HEIGHT);
      
      // 애니메이션 컴포넌트 생성 및 추가
      anteaterAnimation = SpriteAnimationComponent(
        animation: anteaterAnim,
        size: size,
        position: Vector2.zero(),
      );
      
      // 커스텀 이미지가 있으면 애니메이션 숨기기
      if (hasCustomImage) {
        anteaterAnimation!.opacity = 0;
        print('개미핥기 애니메이션 숨김 처리됨 (애니메이션 생성 시)');
      } else {
        anteaterAnimation!.opacity = 1;
      }
      
      add(anteaterAnimation!);
      
      hasAnimation = true;
    } catch (e) {
      print('개미핥기 애니메이션 로드 실패: $e');
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
    if (hasAnimation && anteaterAnimation != null) {
      // 커스텀 이미지가 있으면 애니메이션 숨기기, 없으면 표시
      if (hasCustomImage) {
        anteaterAnimation!.opacity = 0;
        print('개미핥기 애니메이션 숨김 처리됨');
      } else {
        anteaterAnimation!.opacity = 1;
        print('개미핥기 애니메이션 표시 처리됨');
      }
      
      // 상태가 변경된 경우에만 로깅
      if (previousHasCustomImage != hasCustomImage) {
        print('개미핥기 커스텀 이미지 상태 변경: $previousHasCustomImage -> $hasCustomImage');
      }
    }
  }
  
  @override
  void onOutOfBounds() {
    gameRef.updateScore(30);
    removeFromParent();
  }
} 