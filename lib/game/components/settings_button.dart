import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../ants_adventure_game.dart';

/// 설정 버튼 컴포넌트
class SettingsButton extends SpriteComponent with TapCallbacks {
  final AntsAdventureGame game;

  SettingsButton({
    required Vector2 position,
    required Vector2 size,
    required this.game,
  }) : super(
          position: position,
          size: size,
        );

  @override
  Future<void> onLoad() async {
    // 설정 아이콘 이미지 로드
    sprite = await Sprite.load('settings.png');
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.showSettingsDialog();
  }
}
