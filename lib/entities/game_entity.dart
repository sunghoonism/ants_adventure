import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/ants_adventure_game.dart';

/// 게임의 모든 엔티티의 기본 클래스
abstract class GameEntity extends RectangleComponent with HasGameRef<AntsAdventureGame> {
  bool isStopped = false;
  
  @override
  Future<void> onLoad() async {
    // 디버그 모드 비활성화
    debugMode = false;
  }
  
  void stop() {
    isStopped = true;
  }
} 