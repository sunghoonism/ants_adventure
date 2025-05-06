import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import '../entities/ant.dart';
import '../entities/cloud.dart';
import '../entities/obstacles/bee.dart';
import '../entities/obstacles/anteater.dart';
import '../services/image_service.dart';
import '../widgets/image_settings_dialog.dart';

/// 게임 난이도 설정
enum GameDifficulty {
  veryEasy, // 매우 쉬움
  easy,    // 쉬움
  normal,  // 보통
  hard     // 어려움
}

class AntsAdventureGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Ant ant;
  late TextComponent scoreText;
  late TextComponent levelText;
  late SettingsButton settingsButton;
  TextComponent? gameOverText;
  int score = 0;
  int level = 1;
  double beeTimer = 0.0;
  double anteaterTimer = 0.0;
  double cloudTimer = 0.0;
  double cloudSpawnInterval = 0.0;
  bool isGameOver = false;
  bool isGameStarted = false;
  BuildContext? _buildContext;
  
  // 난이도 관련 변수
  GameDifficulty difficulty = GameDifficulty.normal;
  double difficultyMultiplier = 1.0;
  static const int SCORE_PER_LEVEL = 200;
  static const double MAX_DIFFICULTY = 30.0;
  double difficultyStep = 0.2; // 난이도에 따라 조정됨
  double beeSpawnInterval = 1.0;
  double anteaterSpawnInterval = 7.0;
  
  // 난이도 선택 버튼
  List<DifficultyButton> difficultyButtons = [];
  
  // 게임 외부에서 BuildContext 설정
  void setBuildContext(BuildContext context) {
    _buildContext = context;
  }
  
  @override
  Future<void> onLoad() async {
    // 디버그 모드 비활성화
    debugMode = false;
    
    // 이미지 에셋 수동 로드
    await images.loadAll([
      'ant/walking.png',
      'ant/flying.png',
      'settings.png',
    ]);
    
    // 구름 생성 간격 초기화 (2~5초 사이)
    resetCloudInterval();
    
    // 메인 화면 배경 설정
    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF6FB6DD), // 메인 화면용 파란색 배경
      ),
    );
    
    // 천장 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 30),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 바닥 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 50),
        position: Vector2(0, size.y - 50),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 시작 화면 아이콘 개미 추가
    Ant iconAnt = Ant();
    iconAnt.position = Vector2(size.x / 2, size.y * 0.75);
    add(iconAnt);
    
    // 이미지 설정 버튼 추가 (게임 시작 전 화면)
    final settingsButtonSize = Vector2(40, 40);
    settingsButton = SettingsButton(
      position: Vector2(size.x - settingsButtonSize.x - 10, 40),
      size: settingsButtonSize,
      game: this,
    );
    add(settingsButton);
    
    // 시작 화면 난이도 버튼 추가
    _addDifficultyButtons();
    
    // 게임 타이틀 추가
    final gameTitle = TextComponent(
      text: '개미의 모험',
      position: Vector2(size.x / 2, size.y * 0.2),
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
    add(gameTitle);
    
    // 이미지 설정 안내 텍스트 추가
    final settingsInfoText = TextComponent(
      text: '오른쪽 상단의 버튼을 눌러\n게임 오브젝트 이미지를 설정할 수 있습니다',
      position: Vector2(size.x / 2, size.y * 0.3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(settingsInfoText);
  }
  
  /// 난이도 설정 버튼 추가
  void _addDifficultyButtons() {
    final buttonWidth = size.x * 0.7;
    final buttonHeight = 50.0;
    final spacing = 15.0;
    final startY = size.y * 0.35;
    
    // 매우 쉬움 난이도 버튼
    final veryEasyButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.veryEasy,
      text: '매우 쉬움',
      color: Colors.lightGreen,
      priority: 100,
    );
    add(veryEasyButton);
    difficultyButtons.add(veryEasyButton);
    
    // 쉬움 난이도 버튼
    final easyButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + buttonHeight + spacing),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.easy,
      text: '쉬움',
      color: Colors.green,
      priority: 100,
    );
    add(easyButton);
    difficultyButtons.add(easyButton);
    
    // 보통 난이도 버튼
    final normalButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + 2 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.normal,
      text: '보통',
      color: Colors.blue,
      priority: 100,
    );
    add(normalButton);
    difficultyButtons.add(normalButton);
    
    // 어려움 난이도 버튼
    final hardButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + 3 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.hard,
      text: '어려움',
      color: Colors.red,
      priority: 100,
    );
    add(hardButton);
    difficultyButtons.add(hardButton);
  }
  
  /// 게임 시작
  void startGame(GameDifficulty selectedDifficulty) {
    print('게임 시작: 난이도 ${selectedDifficulty.toString().split('.').last}');
    
    // 게임 오버 상태였다면 화면 정리
    if (isGameOver) {
      // 게임 오버 메시지와 관련 텍스트 제거
      children.whereType<TextComponent>()
        .where((text) => text.text == 'GAME OVER' || text.text == '모드를 선택하세요')
        .forEach((text) => text.removeFromParent());
      
      gameOverText = null;
      
      // 어두운 오버레이 제거
      children.whereType<RectangleComponent>()
        .where((comp) => comp.paint.color.opacity < 1 && comp.size == size)
        .forEach((comp) => comp.removeFromParent());
      
      // 모든 게임 오브젝트 제거
      children.whereType<Bee>().forEach((bee) => bee.removeFromParent());
      children.whereType<Anteater>().forEach((anteater) => anteater.removeFromParent());
      children.whereType<Cloud>().forEach((cloud) => cloud.removeFromParent());
      
      // 배경색, 천장, 바닥 초기화
      children.whereType<RectangleComponent>().forEach((comp) => comp.removeFromParent());
    }
    
    // 게임 상태 초기화
    isGameOver = false;
    isGameStarted = true;
    score = 0;
    level = 1;
    
    // 선택된 난이도 저장
    difficulty = selectedDifficulty;
    
    // 난이도에 따른 설정
    switch (difficulty) {
      case GameDifficulty.veryEasy:
        difficultyStep = 0.0; // 레벨업 시 속도 변화 없음
        difficultyMultiplier = 0.7; // 매우 느린 초기 속도
        break;
      case GameDifficulty.easy:
        difficultyStep = 0.05; // 레벨업 시 속도 증가율 작음
        difficultyMultiplier = 0.8; // 초기 속도 느림
        break;
      case GameDifficulty.normal:
        difficultyStep = 0.1; // 중간 정도의 속도 증가율
        difficultyMultiplier = 1.0; // 기본 속도
        break;
      case GameDifficulty.hard:
        difficultyStep = 0.2; // 높은 속도 증가율
        difficultyMultiplier = 1.2; // 초기 속도 빠름
        break;
    }
    
    // 메인 메뉴 버튼 제거
    children.whereType<MainMenuButton>().forEach((button) => button.removeFromParent());
    
    // 난이도 버튼 제거
    children.whereType<DifficultyButton>().forEach((button) => button.removeFromParent());
    difficultyButtons.clear();
    
    // 타이틀 제거
    children.whereType<TextComponent>()
      .where((text) => text.text == '개미의 모험' || text.text.contains('오른쪽 상단의 버튼'))
      .forEach((text) => text.removeFromParent());
    
    // 메인 화면 개미 아이콘 제거
    children.whereType<Ant>().forEach((ant) => ant.removeFromParent());
    
    // 설정 버튼 제거 (게임 화면에서 다시 추가됨)
    children.whereType<SettingsButton>().forEach((button) => button.removeFromParent());
    
    // 배경색 변경
    _changeBackgroundColor();
    
    // 게임 오브젝트 추가
    _initializeGameObjects();
    
    // 난이도 표시
    _showDifficultyIndicator();
  }
  
  /// 난이도에 따라 배경색 변경
  void _changeBackgroundColor() {
    // 기존 배경 컴포넌트 찾아서 제거
    children.whereType<RectangleComponent>()
      .where((comp) => comp.position == Vector2.zero() && comp.size == size)
      .forEach((comp) => comp.removeFromParent());
    
    // 난이도에 맞는 새 배경색 추가
    Color backgroundColor;
    switch(difficulty) {
      case GameDifficulty.veryEasy:
        backgroundColor = const Color(0xFFA7E9FF); // 매우 밝은 하늘색
        break;
      case GameDifficulty.easy:
        backgroundColor = const Color(0xFF87CEEB); // 밝은 하늘색
        break;
      case GameDifficulty.normal:
        backgroundColor = const Color(0xFF5F9EAB); // 중간 하늘색
        break;
      case GameDifficulty.hard:
        backgroundColor = const Color(0xFF2A6A8A); // 어두운 하늘색
        break;
    }
    
    // 배경 추가 (맨 아래 레이어에 추가)
    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = backgroundColor,
      ),
    );
    
    // 천장과 바닥 재설정 (배경 위에 추가)
    add(
      RectangleComponent(
        size: Vector2(size.x, 30),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    add(
      RectangleComponent(
        size: Vector2(size.x, 50),
        position: Vector2(0, size.y - 50),
        paint: Paint()..color = Colors.grey,
      ),
    );
  }
  
  /// 현재 난이도 표시
  void _showDifficultyIndicator() {
    String difficultyText;
    Color difficultyColor;
    
    switch(difficulty) {
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
    
    add(difficultyIndicator);
  }
  
  /// 게임 오브젝트 초기화
  void _initializeGameObjects() {
    // 개미 생성 및 추가
    ant = Ant();
    add(ant);
    
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
    add(scoreText);
    
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
    add(levelText);
    
    // 설정 버튼 추가
    final settingsButtonSize = Vector2(40, 40);
    
    settingsButton = SettingsButton(
      position: Vector2(size.x - settingsButtonSize.x - 10, 30),
      size: settingsButtonSize,
      game: this,
    );
    add(settingsButton);
  }
  
  void resetCloudInterval() {
    // 2~5초 사이의 랜덤한 시간 간격
    cloudSpawnInterval = 2.0 + math.Random().nextDouble() * 3.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isGameStarted || isGameOver) return;
    
    // 벌 생성 타이머
    beeTimer += dt;
    if (beeTimer >= beeSpawnInterval / difficultyMultiplier) {
      beeTimer = 0.0;
      add(Bee(speedMultiplier: difficultyMultiplier));
    }
    
    // 개미핥기 생성 타이머
    anteaterTimer += dt;
    if (anteaterTimer >= anteaterSpawnInterval / difficultyMultiplier) {
      anteaterTimer = 0.0;
      add(Anteater(speedMultiplier: difficultyMultiplier));
    }
    
    // 구름 생성 타이머
    cloudTimer += dt;
    if (cloudTimer >= cloudSpawnInterval) {
      cloudTimer = 0.0;
      add(Cloud());
      resetCloudInterval();  // 새로운 간격으로 재설정
    }
  }
  
  @override
  bool onTapDown(TapDownInfo info) {
    if (isGameOver) {
      // 게임 오버 상태에서는 탭으로 재시작하지 않음
      // 대신 난이도 버튼이나 메인메뉴 버튼을 사용해야 함
      return true;
    }
    
    if (!isGameStarted) {
      // 게임 시작 전에는 화면 탭 반응하지 않음 (버튼은 자체적으로 처리됨)
      return true;
    }
    
    // 설정 버튼 영역만 확인
    final buttonSize = 40.0;
    final buttonMargin = 10.0;
    final settingsButtonArea = Rect.fromLTWH(
      size.x - buttonSize - buttonMargin, 
      buttonMargin, 
      buttonSize, 
      buttonSize
    );
    
    final tapPosition = info.eventPosition.global;
    
    // 설정 버튼 영역이 아닌 경우에만 점프 실행
    if (!settingsButtonArea.contains(Offset(tapPosition.x, tapPosition.y))) {
      // 게임 중 탭하면 개미 점프
      ant.jump();
    }
    
    return true;
  }
  
  void updateScore(int points) {
    if (isGameOver) return;
    
    score += points;
    scoreText.text = 'Score: $score';
    
    // 점수에 따른 레벨 업 및 난이도 조정
    int newLevel = (score ~/ SCORE_PER_LEVEL) + 1;
    if (newLevel > level) {
      level = newLevel;
      levelText.text = 'Level: $level';
      
      // 난이도 증가 (최대치 제한)
      if (difficultyMultiplier < MAX_DIFFICULTY && difficultyStep > 0) {
        difficultyMultiplier += difficultyStep;
        if (difficultyMultiplier > MAX_DIFFICULTY) {
          difficultyMultiplier = MAX_DIFFICULTY;
        }
      }
      
      // 레벨업 알림 표시
      _showLevelUpNotification();
    }
  }
  
  void _showLevelUpNotification() {
    final levelUpText = TextComponent(
      text: 'LEVEL UP!',
      position: Vector2(size.x / 2, size.y / 3),
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
    
    add(levelUpText);
    
    // 2초 후 텍스트 제거
    Future.delayed(const Duration(seconds: 2), () {
      if (!isGameOver && levelUpText.isMounted) {
        levelUpText.removeFromParent();
      }
    });
  }
  
  void gameOver() {
    if (isGameOver) return;  // 중복 호출 방지
    
    isGameOver = true;
    
    // 반투명 검은색 배경 추가 (화면을 어둡게 만들기 위함)
    final darkOverlay = RectangleComponent(
      size: size,
      position: Vector2.zero(),
      paint: Paint()..color = Colors.black.withOpacity(0.7),
      priority: 50, // 매우 낮은 우선순위로 설정
    );
    add(darkOverlay);
    
    // 게임오버 메시지 표시 (위치를 상단으로 이동)
    gameOverText = TextComponent(
      text: 'GAME OVER',
      position: Vector2(size.x / 2, 200),
      anchor: Anchor.center,
      priority: 100, // 높은 우선순위 설정
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Color.fromARGB(255, 255, 114, 27),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gameOverText!);
    
    // 재시작 안내 메시지 추가
    final restartText = TextComponent(
      text: '모드를 선택하세요',
      position: Vector2(size.x / 2, 250),
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
    add(restartText);
    
    // 바로 게임을 다시 시작할 수 있는 난이도 버튼 추가
    _addGameOverDifficultyButtons();
    
    // 모든 벌과 개미핥기의 움직임 정지
    children.whereType<Bee>().forEach((bee) => bee.stop());
    children.whereType<Anteater>().forEach((anteater) => anteater.stop());
    children.whereType<Cloud>().forEach((cloud) => cloud.stop());
  }
  
  /// 게임 오버 화면에 난이도 버튼 추가
  void _addGameOverDifficultyButtons() {
    final buttonWidth = size.x * 0.6;
    final buttonHeight = 40.0;
    final spacing = 15.0;
    final startY = size.y * 0.35;
    
    // 매우 쉬움 난이도 버튼
    final veryEasyButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.veryEasy,
      text: '매우 쉬움',
      color: Colors.lightGreen,
      priority: 110, // 어두운 배경보다 높은 우선순위
    );
    add(veryEasyButton);
    
    // 쉬움 난이도 버튼
    final easyButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + buttonHeight + spacing),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.easy,
      text: '쉬움',
      color: Colors.green,
      priority: 110, // 어두운 배경보다 높은 우선순위
    );
    add(easyButton);
    
    // 보통 난이도 버튼
    final normalButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + 2 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.normal,
      text: '보통',
      color: Colors.blue,
      priority: 110, // 어두운 배경보다 높은 우선순위
    );
    add(normalButton);
    
    // 어려움 난이도 버튼
    final hardButton = DifficultyButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + 3 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      difficulty: GameDifficulty.hard,
      text: '어려움',
      color: Colors.red,
      priority: 110, // 어두운 배경보다 높은 우선순위
    );
    add(hardButton);
    
    // 메인 메뉴로 돌아가기 버튼
    final mainMenuButton = MainMenuButton(
      position: Vector2(size.x / 2 - buttonWidth / 2, startY + 4 * (buttonHeight + spacing)),
      size: Vector2(buttonWidth, buttonHeight),
      game: this,
      priority: 110, // 어두운 배경보다 높은 우선순위
    );
    add(mainMenuButton);
  }
  
  void restartGame() {
    print('게임 재시작 - 메인 메뉴로 이동');
    
    // 게임 상태 초기화
    isGameOver = false;
    isGameStarted = false;
    
    // 게임 오버 메시지와 관련 텍스트 제거
    children.whereType<TextComponent>()
      .where((text) => text.text == 'GAME OVER' || text.text == '모드를 선택하세요')
      .forEach((text) => text.removeFromParent());
    
    gameOverText = null;
    
    // 어두운 오버레이 제거
    children.whereType<RectangleComponent>()
      .where((comp) => comp.paint.color.opacity < 1 && comp.size == size)
      .forEach((comp) => comp.removeFromParent());
    
    // 난이도 버튼 제거
    children.whereType<DifficultyButton>().forEach((button) => button.removeFromParent());
    children.whereType<MainMenuButton>().forEach((button) => button?.removeFromParent());
    
    // 점수 리셋
    score = 0;
    level = 1;
    difficultyMultiplier = 1.0;
    
    // 모든 게임 오브젝트 제거
    if (children.contains(ant)) {
      ant.removeFromParent();
    }
    if (children.contains(scoreText)) {
      scoreText.removeFromParent();
    }
    if (children.contains(levelText)) {
      levelText.removeFromParent();
    }
    if (children.contains(settingsButton)) {
      settingsButton.removeFromParent();
    }
    
    // 모든 벌과 개미핥기 및 구름 제거
    children.whereType<Bee>().forEach((bee) => bee.removeFromParent());
    children.whereType<Anteater>().forEach((anteater) => anteater.removeFromParent());
    children.whereType<Cloud>().forEach((cloud) => cloud.removeFromParent());
    
    // 난이도 표시 제거
    children.whereType<TextComponent>()
      .where((text) => text.text.contains("모드"))
      .forEach((text) => text.removeFromParent());
    
    // 배경색, 천장, 바닥 초기화
    children.whereType<RectangleComponent>().forEach((comp) => comp.removeFromParent());
    
    // 메인 화면 배경 추가
    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF6FB6DD), // 메인 화면용 파란색 배경
      ),
    );
    
    // 천장 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 30),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 바닥 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 50),
        position: Vector2(0, size.y - 50),
        paint: Paint()..color = Colors.grey,
      ),
    );
    
    // 시작 화면 아이콘 개미 추가
    Ant iconAnt = Ant();
    iconAnt.position = Vector2(size.x / 2, size.y * 0.75);
    add(iconAnt);
    
    // 이미지 설정 버튼 다시 추가
    final settingsButtonSize = Vector2(40, 40);
    settingsButton = SettingsButton(
      position: Vector2(size.x - settingsButtonSize.x - 10, 30),
      size: settingsButtonSize,
      game: this,
    );
    add(settingsButton);
    
    // 메인 화면으로 돌아가기
    _addDifficultyButtons();
    
    // 게임 타이틀 다시 추가
    final gameTitle = TextComponent(
      text: '개미의 모험',
      position: Vector2(size.x / 2, size.y * 0.2),
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
    add(gameTitle);
    
    // 이미지 설정 안내 텍스트 추가
    final settingsInfoText = TextComponent(
      text: '오른쪽 상단의 버튼을 눌러\n게임 오브젝트 이미지를 설정할 수 있습니다',
      position: Vector2(size.x / 2, size.y * 0.3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(settingsInfoText);
  }
  
  /// 이미지 설정 대화상자 표시
  void showImageSettingsDialog() {
    if (_buildContext != null) {
      // 현재 게임 상태 저장
      final bool wasGameOver = isGameOver;
      
      // 게임 일시 정지
      pauseEngine();
      
      showDialog(
        context: _buildContext!,
        builder: (context) => const ImageSettingsDialog(),
      ).then((_) {
        // 이미지 업데이트
        _updateAllGameObjects();
        
        // 게임 상태 복원
        if (wasGameOver) {
          // 게임 오버 상태였다면 상태 유지
          isGameOver = true;
        }
        
        // 게임 재개
        resumeEngine();
        
        // 게임 오버 상태에서 대화상자를 연 경우, 상태 확인 필요
        if (wasGameOver && !children.contains(gameOverText) && gameOverText != null) {
          // 게임 오버 텍스트가 누락되었다면 다시 추가
          add(gameOverText!);
        }
      });
    }
  }
  
  /// 모든 게임 오브젝트 이미지 업데이트
  Future<void> _updateAllGameObjects() async {
    try {
      // 게임 진행 중이면 실제 게임 캐릭터 업데이트
      if (isGameStarted) {
        // 개미 캐릭터가 존재하는지 확인
        if (children.contains(ant)) {
          await ant.updateCustomImage();
        }
        
        // 기존 장애물 업데이트
        final bees = children.whereType<Bee>().toList();
        for (final bee in bees) {
          if (children.contains(bee)) {
            await bee.updateCustomImage();
          }
        }
        
        final anteaters = children.whereType<Anteater>().toList();
        for (final anteater in anteaters) {
          if (children.contains(anteater)) {
            await anteater.updateCustomImage();
          }
        }
        // 구름은 이미지 업데이트 하지 않음
      } 
      // 게임이 시작되지 않았으면 시작 화면의 개미 아이콘 업데이트
      else {
        // 모든 개미 캐릭터 이미지 업데이트
        final iconAnts = children.whereType<Ant>().toList();
        for (final iconAnt in iconAnts) {
          if (children.contains(iconAnt)) {
            await iconAnt.updateCustomImage();
          }
        }
      }
    } catch (e) {
      print('게임 오브젝트 이미지 업데이트 오류: $e');
    }
  }
}

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
    game.showImageSettingsDialog();
  }
}

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
    game.startGame(difficulty);
  }
}

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