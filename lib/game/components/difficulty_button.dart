import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../ants_adventure_game.dart';
import '../game_config.dart';

/// 난이도 선택 버튼
class DifficultyButton extends RectangleComponent with TapCallbacks {
  final AntsAdventureGame game;
  final GameDifficulty difficulty;
  final String text;
  final Color color;
  final int priority;

  DifficultyButton({
    required Vector2 position,
    required Vector2 size,
    required this.game,
    required this.difficulty,
    required this.text,
    required this.color,
    this.priority = 100,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = color.withOpacity(0.8),
          priority: priority,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 텍스트 그리기
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 30,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    // 텍스트를 중앙에 표시
    textPaint.render(
      canvas,
      text,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    AntsAdventureGame.useCustomSettings = false; // 일반 난이도 선택 시 커스텀 설정 해제
    game.startGame(difficulty);
  }
}
