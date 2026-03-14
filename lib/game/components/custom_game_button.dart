import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../ants_adventure_game.dart';
import '../game_config.dart';

/// 커스텀 게임 플레이 버튼
class CustomGameButton extends RectangleComponent with TapCallbacks {
  final AntsAdventureGame game;
  final int priority;

  CustomGameButton({
    required Vector2 position,
    required Vector2 size,
    required this.game,
    this.priority = 100,
  }) : super(
          position: position,
          size: size,
          paint: Paint()
            ..color = (AntsAdventureGame.selectedSlotIndex != null
                    ? Colors.orange
                    : Colors.grey)
                .withOpacity(0.8),
          priority: priority,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final String slotInfo = AntsAdventureGame.selectedSlotIndex != null
        ? '(슬롯 ${AntsAdventureGame.selectedSlotIndex})'
        : '(선택 안됨)';

    // 텍스트 그리기
    final textPaint = TextPaint(
      style: const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    // 텍스트를 중앙에 표시
    textPaint.render(
      canvas,
      '커스텀 게임 플레이 $slotInfo',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (AntsAdventureGame.selectedSlotIndex != null) {
      // 커스텀 설정이 이미 로드되어 있어야 함 (SettingsDialog에서 로드함)
      // 커스텀 설정 활성화
      AntsAdventureGame.useCustomSettings = true;
      game.startGame(
          GameDifficulty.normal); // 난이도는 무시됨(useCustomSettings가 true이므로)
    } else {
      // 슬롯이 선택되지 않은 경우 설정창을 띄워 슬롯을 고르게 유도
      print('커스텀 게임 슬롯이 선택되지 않았습니다. 설정창을 엽니다.');
      game.showSettingsDialog();
    }
  }
}
