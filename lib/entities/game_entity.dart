import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/ants_adventure_game.dart';
import '../services/image_service.dart';

/// 게임의 모든 엔티티의 기본 클래스
abstract class GameEntity extends RectangleComponent with HasGameRef<AntsAdventureGame> {
  bool isStopped = false;
  bool hasCustomImage = false;
  ui.Image? customImage;
  final GameObjectType objectType;
  
  GameEntity({required this.objectType});
  
  @override
  Future<void> onLoad() async {
    // 디버그 모드 비활성화
    debugMode = false;
    
    // 커스텀 이미지 로드 시도
    await _tryLoadCustomImage();
  }
  
  /// 커스텀 이미지 로드 시도
  Future<void> _tryLoadCustomImage() async {
    final ImageService imageService = ImageService();
    final File? imageFile = await imageService.getImageFile(objectType);
    
    if (imageFile != null) {
      try {
        final data = await imageFile.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(data);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        
        customImage = frameInfo.image;
        hasCustomImage = true;
      } catch (e) {
        debugPrint('이미지 로드 오류: $e');
        hasCustomImage = false;
      }
    } else {
      hasCustomImage = false;
    }
  }
  
  /// 커스텀 이미지 변경
  Future<void> updateCustomImage() async {
    try {
      customImage = null;
      hasCustomImage = false;
      await _tryLoadCustomImage();
    } catch (e) {
      debugPrint('커스텀 이미지 업데이트 오류: $e');
      hasCustomImage = false;
    }
  }
  
  /// 기본 스프라이트가 있는지 확인
  bool get hasDefaultSprite => false;
  
  /// 기본 애니메이션 생성
  Future<void> createDefaultAnimation() async {}
  
  @override
  void render(Canvas canvas) {
    if (hasCustomImage && customImage != null) {
      // 커스텀 이미지가 있다면 이미지 렌더링
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.x, size.y),
        image: customImage!,
        fit: BoxFit.cover,
      );
    } else {
      // 없으면 기본 렌더링 사용
      super.render(canvas);
    }
  }
  
  void stop() {
    isStopped = true;
  }
} 