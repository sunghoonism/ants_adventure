/// 게임 난이도 설정
enum GameDifficulty {
  veryEasy, // 매우 쉬움
  easy, // 쉬움
  normal, // 보통
  hard // 어려움
}

/// 게임 설정 상수
class GameConfig {
  static const int scorePerLevel = 200;
  static const double maxDifficultyMultiplier = 30.0;
  static const double defaultBeeSpawnInterval = 1.0;
  static const double defaultAnteaterSpawnInterval = 7.0;
  static const double defaultDifficultyStep = 0.2;
}

enum GameObjectType {
  bee,
  anteater,
  cloud,
  ant,
  car,
  airplane,
}
