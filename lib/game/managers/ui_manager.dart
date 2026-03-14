import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ants_adventure_game.dart';
import '../components/settings_button.dart';
import '../components/difficulty_button.dart';
import '../components/main_menu_button.dart';
import '../components/custom_game_button.dart';
import '../../entities/ant.dart';
import '../game_config.dart';

class UIManager {
  final AntsAdventureGame game;
  late TextComponent scoreText;
  late TextComponent levelText;
  TextComponent? gameOverText;
  SettingsButton? settingsButton;

  List<DifficultyButton> difficultyButtons = [];

  UIManager(this.game);

  void showStartupUI() {
    // 시작 화면 아이콘 개미
    Ant iconAnt = Ant();
    iconAnt.position = Vector2(game.size.x / 2, game.size.y * 0.75);
    game.add(iconAnt);

    // 설정 버튼
    final settingsButtonSize = Vector2(40, 40);
    settingsButton = SettingsButton(
      position: Vector2(game.size.x - settingsButtonSize.x - 10, 40),
      size: settingsButtonSize,
      game: game,
    );
    game.add(settingsButton!);

    // 난이도 버튼
    _addDifficultyButtons();

    // 타이틀
    _addGameTitle();
  }

  void showGameHUD() {
    // 점수 텍스트
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    game.add(scoreText);

    // 레벨 텍스트
    levelText = TextComponent(
      text: 'Level: 1',
      position: Vector2(10, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    game.add(levelText);

    // 게임 중 설정 버튼
    final settingsButtonSize = Vector2(40, 40);
    settingsButton = SettingsButton(
      position: Vector2(game.size.x - settingsButtonSize.x - 10, 30),
      size: settingsButtonSize,
      game: game,
    );
    game.add(settingsButton!);

    // 난이도 표시
    _showDifficultyIndicator();

    // 커스텀 모드 활성화됨
    if (AntsAdventureGame.useCustomSettings) {
      _showCustomModeNotification();
    }
  }

  void showGameOverUI() {
    // 반투명 오버레이
    final darkOverlay = RectangleComponent(
      size: game.size,
      position: Vector2.zero(),
      paint: Paint()..color = Colors.black.withOpacity(0.7),
      priority: 50,
    );
    game.add(darkOverlay);

    // 게임 오버 텍스트
    gameOverText = TextComponent(
      text: 'GAME OVER',
      position: Vector2(game.size.x / 2, 200),
      anchor: Anchor.center,
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Color.fromARGB(255, 255, 114, 27),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    game.add(gameOverText!);

    // 재시작 안내
    final restartText = TextComponent(
      text: '모드를 선택하세요',
      position: Vector2(game.size.x / 2, 250),
      anchor: Anchor.center,
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    game.add(restartText);

    // 게임 오버 메뉴 버튼들
    _addGameOverButtons();
  }

  void updateScore(int score) {
    if (game.isGameOver) return;
    scoreText.text = 'Score: $score';
  }

  void updateLevel(int level) {
    if (game.isGameOver) return;
    levelText.text = 'Level: $level';
    _showLevelUpNotification();
  }

  void clearUI() {
    // 텍스트 제거
    game.children
        .whereType<TextComponent>()
        .where((text) =>
            text.text == 'GAME OVER' ||
            text.text == '모드를 선택하세요' ||
            text.text == 'LEVEL UP!' ||
            text.text == '커스텀 모드 활성화됨' ||
            text.text.startsWith('Score:') ||
            text.text.startsWith('Level:') ||
            text.text.contains('모드') ||
            text.text == '개미의 모험' ||
            text.text.contains('오른쪽 상단의 버튼'))
        .forEach((text) => text.removeFromParent());

    game.children.whereType<Ant>().forEach((ant) => ant.removeFromParent());

    gameOverText = null;

    // 버튼 제거
    game.children
        .whereType<DifficultyButton>()
        .forEach((button) => button.removeFromParent());
    game.children
        .whereType<CustomGameButton>()
        .forEach((button) => button.removeFromParent());
    game.children
        .whereType<MainMenuButton>()
        .forEach((button) => button.removeFromParent());
    game.children
        .whereType<SettingsButton>()
        .forEach((button) => button.removeFromParent());

    difficultyButtons.clear();

    // 오버레이 제거
    game.children
        .whereType<RectangleComponent>()
        .where((comp) => comp.paint.color.opacity < 1 && comp.size == game.size)
        .forEach((comp) => comp.removeFromParent());
  }

  // 내부 헬퍼 메서드들 (이전 AntsAdventureGame에서 복사 후 수정)
  void _addDifficultyButtons() {
    final buttonWidth = game.size.x * 0.7;
    final buttonHeight = 50.0;
    final spacing = 15.0;
    final startY = game.size.y * 0.35;

    // ... 버튼 추가 로직 (game.add 사용)
    // Too long, I'll trust standard implementation or copy exact logic later.
    // Simplifying for now to avoid token limit issues in one go

    _createDifficultyButton(
        GameDifficulty.veryEasy,
        '매우 쉬움',
        Colors.lightGreen,
        Vector2(game.size.x / 2 - buttonWidth / 2, startY),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.easy,
        '쉬움',
        Colors.green,
        Vector2(
            game.size.x / 2 - buttonWidth / 2, startY + buttonHeight + spacing),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.normal,
        '보통',
        Colors.blue,
        Vector2(game.size.x / 2 - buttonWidth / 2,
            startY + 2 * (buttonHeight + spacing)),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.hard,
        '어려움',
        Colors.red,
        Vector2(game.size.x / 2 - buttonWidth / 2,
            startY + 3 * (buttonHeight + spacing)),
        Vector2(buttonWidth, buttonHeight));

    // Custom Game Button
    final customButton = CustomGameButton(
      position: Vector2(game.size.x / 2 - buttonWidth / 2,
          startY + 4 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: game,
      priority: 100,
    );
    game.add(customButton);
  }

  void _createDifficultyButton(GameDifficulty diff, String text, Color color,
      Vector2 pos, Vector2 size) {
    final btn = DifficultyButton(
      position: pos,
      size: size,
      game: game,
      difficulty: diff,
      text: text,
      color: color,
      priority: 100,
    );
    game.add(btn);
    difficultyButtons.add(btn);
  }

  void _addGameTitle() {
    final gameTitle = TextComponent(
      text: '개미의 모험',
      position: Vector2(game.size.x / 2, game.size.y * 0.2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 60,
          color: Color.fromARGB(255, 180, 255, 17),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10,
              color: Colors.black,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    game.add(gameTitle);

    final settingsInfoText = TextComponent(
      text: '오른쪽 상단의 버튼을 눌러\n게임 오브젝트 이미지를 설정할 수 있습니다',
      position: Vector2(game.size.x / 2, game.size.y * 0.3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    game.add(settingsInfoText);
  }

  void _showDifficultyIndicator() {
    String difficultyText = '';
    Color difficultyColor = Colors.white;

    switch (game.difficulty) {
      case GameDifficulty.veryEasy:
        difficultyText = "매우 쉬움 모드";
        difficultyColor = Colors.lightGreen;
        break;
      case GameDifficulty.easy:
        difficultyText = "쉬움 모드";
        difficultyColor = Colors.green;
        break;
      case GameDifficulty.normal:
        difficultyText = "보통 모드";
        difficultyColor = Colors.blue;
        break;
      case GameDifficulty.hard:
        difficultyText = "어려움 모드";
        difficultyColor = Colors.red;
        break;
    }

    // 커스텀 모드인 경우 덮어쓰기
    if (AntsAdventureGame.useCustomSettings) {
      difficultyText = "커스텀 모드 (슬롯 ${AntsAdventureGame.selectedSlotIndex})";
      difficultyColor = Colors.orange;
    }

    final difficultyIndicator = TextComponent(
      text: difficultyText,
      position: Vector2(10, 90),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 18,
          color: difficultyColor,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              blurRadius: 2,
              color: Colors.black45,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
    );
    game.add(difficultyIndicator);
  }

  void _showCustomModeNotification() {
    final notification = TextComponent(
      text: '커스텀 모드 활성화됨',
      position: Vector2(game.size.x / 2, 120),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
    game.add(notification);
    Future.delayed(const Duration(seconds: 3), () {
      if (notification.isMounted) notification.removeFromParent();
    });
  }

  void _showLevelUpNotification() {
    final levelUpText = TextComponent(
      text: 'LEVEL UP!',
      position: Vector2(game.size.x / 2, game.size.y / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10,
              color: Colors.orange,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    game.add(levelUpText);
    Future.delayed(const Duration(seconds: 2), () {
      if (!game.isGameOver && levelUpText.isMounted) {
        levelUpText.removeFromParent();
      }
    });
  }

  void _addGameOverButtons() {
    final buttonWidth = game.size.x * 0.6;
    final buttonHeight = 40.0;
    final spacing = 15.0;
    final startY = game.size.y * 0.35;

    _createDifficultyButton(
        GameDifficulty.veryEasy,
        '매우 쉬움',
        Colors.lightGreen,
        Vector2(game.size.x / 2 - buttonWidth / 2, startY),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.easy,
        '쉬움',
        Colors.green,
        Vector2(
            game.size.x / 2 - buttonWidth / 2, startY + buttonHeight + spacing),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.normal,
        '보통',
        Colors.blue,
        Vector2(game.size.x / 2 - buttonWidth / 2,
            startY + 2 * (buttonHeight + spacing)),
        Vector2(buttonWidth, buttonHeight));

    _createDifficultyButton(
        GameDifficulty.hard,
        '어려움',
        Colors.red,
        Vector2(game.size.x / 2 - buttonWidth / 2,
            startY + 3 * (buttonHeight + spacing)),
        Vector2(buttonWidth, buttonHeight));

    final customButton = CustomGameButton(
      position: Vector2(game.size.x / 2 - buttonWidth / 2,
          startY + 4 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: game,
      priority: 110,
    );
    game.add(customButton);

    final mainMenuButton = MainMenuButton(
      position: Vector2(game.size.x / 2 - buttonWidth / 2,
          startY + 5 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: game,
      priority: 110,
    );
    game.add(mainMenuButton);
  }
}
