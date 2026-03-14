import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../ants_adventure_game.dart';

/// 메인 메뉴 버튼 컴포넌트
class MainMenuButton extends RectangleComponent with TapCallbacks {
  final AntsAdventureGame game;
  final int priority;

  MainMenuButton({
    required Vector2 position,
    required Vector2 size,
    required this.game,
    this.priority = 100,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = Colors.purple.withOpacity(0.8),
          priority: priority,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 텍스트 그리기
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    // 텍스트를 중앙에 표시
    textPaint.render(
      canvas,
      '메인 메뉴로 돌아가기',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.restartGame();
  }
}
