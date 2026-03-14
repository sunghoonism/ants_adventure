import 'package:flame/components.dart';
import '../ants_adventure_game.dart';
import '../../entities/obstacles/bee.dart';
import '../../entities/obstacles/anteater.dart';
import '../../entities/cloud.dart';
import '../../entities/ant.dart';
import '../../services/image_service.dart';
import '../game_config.dart';
import 'dart:math' as math;

class ObjectManager {
  final AntsAdventureGame game;
  double beeTimer = 0.0;
  double anteaterTimer = 0.0;
  double cloudTimer = 0.0;
  double cloudSpawnInterval = 0.0;

  double beeSpawnInterval = GameConfig.defaultBeeSpawnInterval;
  double anteaterSpawnInterval = GameConfig.defaultAnteaterSpawnInterval;

  ObjectManager(this.game);

  void reset() {
    beeTimer = 0.0;
    anteaterTimer = 0.0;
    cloudTimer = 0.0;
    resetCloudInterval();
  }

  void resetCloudInterval() {
    cloudSpawnInterval = 2.0 + math.Random().nextDouble() * 3.0;
  }

  void update(double dt) {
    if (!game.isGameStarted || game.isGameOver) return;

    // GameStateManager를 통해 difficultyMultiplier 가져오기
    // 하지만 현재 GameStateManager가 아직 연결되지 않음.
    // 일단 game.difficultyMultiplier 사용 (리팩토링 시점에 연결 필요)

    // 벌 생성
    beeTimer += dt;
    double currentBeeInterval = beeSpawnInterval;
    if (AntsAdventureGame.useCustomSettings &&
        AntsAdventureGame.customIntervals.containsKey(GameObjectType.bee)) {
      currentBeeInterval =
          AntsAdventureGame.customIntervals[GameObjectType.bee]!;
    }

    if (beeTimer >= currentBeeInterval / game.difficultyMultiplier) {
      beeTimer = 0.0;
      double speedMul = game.difficultyMultiplier;
      if (AntsAdventureGame.useCustomSettings &&
          AntsAdventureGame.customSpeeds.containsKey(GameObjectType.bee)) {
        speedMul *= AntsAdventureGame.customSpeeds[GameObjectType.bee]!;
      }
      final bee = Bee(speedMultiplier: speedMul);
      if (AntsAdventureGame.useCustomSettings) {
        _applyCustomHeight(bee);
      }
      game.add(bee);
    }

    // 개미핥기 생성
    anteaterTimer += dt;
    double currentAnteaterInterval = anteaterSpawnInterval;
    if (AntsAdventureGame.useCustomSettings &&
        AntsAdventureGame.customIntervals
            .containsKey(GameObjectType.anteater)) {
      currentAnteaterInterval =
          AntsAdventureGame.customIntervals[GameObjectType.anteater]!;
    }

    if (anteaterTimer >= currentAnteaterInterval / game.difficultyMultiplier) {
      anteaterTimer = 0.0;
      double speedMul = game.difficultyMultiplier;
      if (AntsAdventureGame.useCustomSettings &&
          AntsAdventureGame.customSpeeds.containsKey(GameObjectType.anteater)) {
        speedMul *= AntsAdventureGame.customSpeeds[GameObjectType.anteater]!;
      }
      final anteater = Anteater(speedMultiplier: speedMul);
      if (AntsAdventureGame.useCustomSettings) {
        _applyCustomHeight(anteater);
      }
      game.add(anteater);
    }

    // 구름 생성
    cloudTimer += dt;
    if (cloudTimer >= cloudSpawnInterval) {
      cloudTimer = 0.0;
      final cloud = Cloud();
      if (AntsAdventureGame.useCustomSettings) {
        _applyCustomHeight(cloud);
      }
      game.add(cloud);
      resetCloudInterval();
    }
  }

  void _applyCustomHeight(PositionComponent component) {
    GameObjectType? type;
    if (component is Bee) type = GameObjectType.bee;
    if (component is Anteater) type = GameObjectType.anteater;
    if (component is Cloud) type = GameObjectType.cloud;

    if (type != null) {
      final height = AntsAdventureGame.customHeights[type];
      if (height != null) {
        component.y = height;
      }
    }
  }

  void clearObjects() {
    game.children.whereType<Bee>().forEach((bee) => bee.removeFromParent());
    game.children
        .whereType<Anteater>()
        .forEach((anteater) => anteater.removeFromParent());
    game.children
        .whereType<Cloud>()
        .forEach((cloud) => cloud.removeFromParent());
    game.children.whereType<Ant>().forEach((ant) => ant.removeFromParent());
  }
}
