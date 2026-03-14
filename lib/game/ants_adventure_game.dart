import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import '../entities/ant.dart';
import '../entities/cloud.dart';
import '../entities/obstacles/bee.dart';
import '../entities/obstacles/anteater.dart';
import '../services/audio_service.dart';
import '../widgets/settings_dialog.dart';
import 'game_config.dart';
import 'managers/game_state_manager.dart';
import 'managers/object_manager.dart';
import 'managers/ui_manager.dart';

class AntsAdventureGame extends FlameGame
    with HasCollisionDetection, TapCallbacks {
  final AudioService _audioService = AudioService();

  // Managers
  late final GameStateManager gameStateManager;
  late final ObjectManager objectManager;
  late final UIManager uiManager;

  // Entities
  late Ant ant;

  BuildContext? _buildContext;

  // Getters for compatibility and easier access
  int get score => gameStateManager.score;
  int get level => gameStateManager.level;
  bool get isGameOver => gameStateManager.isGameOver;
  bool get isGameStarted => gameStateManager.isGameStarted;
  GameDifficulty get difficulty => gameStateManager.difficulty;
  double get difficultyMultiplier => gameStateManager.difficultyMultiplier;

  // Static fields wrapper for compatibility
  static bool get useCustomSettings => useCustomSettingsStatic;
  static set useCustomSettings(bool value) => useCustomSettingsStatic = value;

  static bool useCustomSettingsStatic = false;
  static Map<GameObjectType, double> customHeights = {};
  static Map<GameObjectType, double> customSpeeds = {};
  static Map<GameObjectType, double> customIntervals = {};
  static double customGlobalDifficulty = 1.0;
  static int? selectedSlotIndex;

  // Instance proxies for managers
  bool get useCustomSettingsInstance => useCustomSettingsStatic;

  // 게임 외부에서 BuildContext 설정
  void setBuildContext(BuildContext context) {
    _buildContext = context;
  }

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // Initialize Managers
    gameStateManager = GameStateManager();
    objectManager = ObjectManager(this);
    uiManager = UIManager(this);

    await _audioService.init();

    await images.loadAll([
      'ant/walking.png',
      'ant/flying.png',
      'settings.png',
    ]);

    objectManager.resetCloudInterval();

    // 앱 시작 시 초기 환경 및 UI 설정
    _addEnvironment(isMainScreen: true);
    uiManager.showStartupUI();
  }

  /// 게임 환경(배경, 천장, 바닥) 추가
  void _addEnvironment({bool isMainScreen = false}) {
    // 배경 추가
    Color backgroundColor = isMainScreen
        ? const Color(0xFF6FB6DD)
        : _getDifficultyBackgroundColor();

    add(
      RectangleComponent(
        size: size,
        position: Vector2.zero(),
        paint: Paint()..color = backgroundColor,
        priority: -10, // 가장 뒤에 위치
      ),
    );

    // 천장 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 30),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey,
        priority: -5,
      ),
    );

    // 바닥 추가
    add(
      RectangleComponent(
        size: Vector2(size.x, 50),
        position: Vector2(0, size.y - 50),
        paint: Paint()..color = Colors.grey,
        priority: -5,
      ),
    );
  }

  Color _getDifficultyBackgroundColor() {
    switch (gameStateManager.difficulty) {
      case GameDifficulty.veryEasy:
        return const Color(0xFFA7E9FF);
      case GameDifficulty.easy:
        return const Color(0xFF87CEEB);
      case GameDifficulty.normal:
        return const Color(0xFF5F9EAB);
      case GameDifficulty.hard:
        return const Color(0xFF2A6A8A);
    }
  }

  /// 게임 시작
  void startGame(GameDifficulty selectedDifficulty) {
    print('게임 시작: 난이도 ${selectedDifficulty.toString().split('.').last}');

    // BGM 재생
    _audioService.playBgmForDifficulty(selectedDifficulty);

    // 이전 게임 요소 정리
    uiManager.clearUI();
    objectManager.clearObjects();
    objectManager.reset();

    // 게임 상태 초기화 및 설정
    gameStateManager.reset();
    gameStateManager.setDifficulty(selectedDifficulty);
    gameStateManager.isGameStarted = true;

    // 게임 환경 및 오브젝트 추가
    _addEnvironment();

    // 개미 생성
    ant = Ant();
    add(ant);

    // UI 표시
    uiManager.showGameHUD();
  }

  @override
  void update(double dt) {
    super.update(dt);
    objectManager.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameStateManager.isGameOver || !gameStateManager.isGameStarted) {
      super.onTapDown(event);
      return;
    }

    // 설정 버튼 영역만 확인 (상단 우측)
    final buttonSize = 40.0;
    final buttonMargin = 10.0;
    final settingsButtonArea = Rect.fromLTWH(size.x - buttonSize - buttonMargin,
        buttonMargin, buttonSize, buttonSize);

    final tapPosition = event.canvasPosition;

    // 설정 버튼 영역이 아닌 경우에만 점프 실행
    if (!settingsButtonArea.contains(Offset(tapPosition.x, tapPosition.y))) {
      ant.jump();
    }

    super.onTapDown(event);
  }

  void updateScore(int points) {
    if (gameStateManager.isGameOver) return;

    gameStateManager.addScore(points);
    uiManager.updateScore(gameStateManager.score);

    if (gameStateManager.checkLevelUp()) {
      uiManager.updateLevel(gameStateManager.level);
      gameStateManager.updateDifficulty();
    }
  }

  void gameOver() {
    if (gameStateManager.isGameOver) return;

    gameStateManager.isGameOver = true;
    _audioService.stopBgm();

    uiManager.showGameOverUI();

    // 모든 게임 엔티티 정지
    children.whereType<Bee>().forEach((bee) => bee.stop());
    children.whereType<Anteater>().forEach((anteater) => anteater.stop());
    children.whereType<Cloud>().forEach((cloud) => cloud.stop());
  }

  void restartGame() {
    print('게임 재시작 - 메인 메뉴로 이동');

    _audioService.stopBgm();

    // 정리
    uiManager.clearUI();
    objectManager.clearObjects();
    objectManager.reset();
    gameStateManager.reset();
    gameStateManager.isGameStarted = false; // 명시적으로 false 설정

    // 메인 화면으로 복귀
    _addEnvironment(isMainScreen: true);
    uiManager.showStartupUI();
  }

  /// 메인 메뉴로 완전히 돌아가기 (게임 세션 완전히 종료)
  void returnToMainMenu() {
    print('메인 메뉴로 돌아가기');
    _audioService.stopBgm();
    uiManager.clearUI();
    objectManager.clearObjects();
    objectManager.reset();
    gameStateManager.reset();
    gameStateManager.isGameStarted = false;

    // 메인 화면으로 복귀 (UI와 함께)
    _addEnvironment(isMainScreen: true);
    uiManager.showStartupUI();
  }

  /// 설정 대화상자 표시
  void showSettingsDialog() {
    if (_buildContext != null) {
      final bool wasGameOver = gameStateManager.isGameOver;

      pauseEngine();

      showDialog(
        context: _buildContext!,
        builder: (context) => SettingsDialog(game: this),
      ).then((_) {
        _updateAllGameObjects();

        if (wasGameOver) {
          gameStateManager.isGameOver = true;
        }

        resumeEngine();
      });
    }
  }

  /// 모든 게임 오브젝트 이미지 업데이트
  Future<void> _updateAllGameObjects() async {
    try {
      if (gameStateManager.isGameStarted) {
        if (children.contains(ant)) {
          await ant.updateCustomImage();
        }

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
      } else {
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
