import '../game_config.dart';
import '../ants_adventure_game.dart';

class GameStateManager {
  int score = 0;
  int level = 1;
  bool isGameOver = false;
  bool isGameStarted = false;

  // 난이도 관련 상태
  GameDifficulty difficulty = GameDifficulty.normal;
  double difficultyMultiplier = 1.0;
  double difficultyStep = GameConfig.defaultDifficultyStep;

  // 커스텀 설정 관련 상태
  bool useCustomSettings = false;
  Map<GameObjectType, double> customHeights = {};
  Map<GameObjectType, double> customSpeeds = {};
  double customGlobalDifficulty = 1.0;
  int? selectedSlotIndex;

  void reset() {
    score = 0;
    level = 1;
    isGameOver = false;
    isGameStarted = false;

    // 난이도 초기화
    difficultyMultiplier = 1.0;
  }

  void addScore(int points) {
    if (isGameOver) return;
    score += points;
  }

  bool checkLevelUp() {
    int newLevel = (score ~/ GameConfig.scorePerLevel) + 1;
    if (newLevel > level) {
      level = newLevel;
      return true;
    }
    return false;
  }

  void setDifficulty(GameDifficulty newDifficulty) {
    difficulty = newDifficulty;

    // Static fields from AntsAdventureGame for custom settings
    if (AntsAdventureGame.useCustomSettingsStatic) {
      difficultyMultiplier = AntsAdventureGame.customGlobalDifficulty;

      // Avoid division by zero if multiplier is very small
      if (difficultyMultiplier > 0) {
        difficultyStep = difficultyMultiplier / 10.0;
      } else {
        difficultyStep = 0.02; // Default fallback
      }

      // Sync custom speeds from static source if needed, or rely on Game to pass them?
      // Actually GameStateManager has its own customSpeeds map.
      // Let's populate it from the static source.
      customSpeeds = Map.from(AntsAdventureGame.customSpeeds);

      // Ensure defaults
      for (var type in GameObjectType.values) {
        if (type != GameObjectType.cloud && !customSpeeds.containsKey(type)) {
          customSpeeds[type] = 1.0;
        }
      }
    } else {
      switch (difficulty) {
        case GameDifficulty.veryEasy:
          difficultyStep = 0.0;
          difficultyMultiplier = 0.7;
          break;
        case GameDifficulty.easy:
          difficultyStep = 0.05;
          difficultyMultiplier = 0.8;
          break;
        case GameDifficulty.normal:
          difficultyStep = 0.1;
          difficultyMultiplier = 1.0;
          break;
        case GameDifficulty.hard:
          difficultyStep = 0.2;
          difficultyMultiplier = 1.2;
          break;
      }
    }
  }

  void updateDifficulty() {
    if (difficultyMultiplier < GameConfig.maxDifficultyMultiplier &&
        difficultyStep > 0) {
      difficultyMultiplier += difficultyStep;
      if (difficultyMultiplier > GameConfig.maxDifficultyMultiplier) {
        difficultyMultiplier = GameConfig.maxDifficultyMultiplier;
      }
    }
  }
}
