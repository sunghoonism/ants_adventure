import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../game/game_config.dart';

/// 배경음악 관리 서비스
class AudioService {
  static final AudioService _instance = AudioService._internal();
  bool _isBgmEnabled = true;
  String? _currentBgm;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  bool get isBgmEnabled => _isBgmEnabled;

  /// 설정 초기화
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBgmEnabled = prefs.getBool('bgm_enabled') ?? true;

    // 오디오 파일 사전 로드
    await FlameAudio.audioCache.loadAll([
      'very_easy_푸른 지도를 펴면.mp3',
      'easy_푸른 지도를 펴면.mp3',
      'medium_심장이 먼저 달려가.mp3',
      'hard_심장이 먼저 달려가.mp3',
    ]);
  }

  /// BGM 설정 변경 및 저장
  Future<void> setBgmEnabled(bool enabled) async {
    _isBgmEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm_enabled', enabled);

    if (!enabled) {
      stopBgm();
    } else if (_currentBgm != null) {
      playBgm(_currentBgm!);
    }
  }

  /// 특정 난이도에 맞는 BGM 재생
  void playBgmForDifficulty(GameDifficulty difficulty) {
    String bgmFile;
    switch (difficulty) {
      case GameDifficulty.veryEasy:
        bgmFile = 'very_easy_푸른 지도를 펴면.mp3';
        break;
      case GameDifficulty.easy:
        bgmFile = 'easy_푸른 지도를 펴면.mp3';
        break;
      case GameDifficulty.normal:
        bgmFile = 'medium_심장이 먼저 달려가.mp3';
        break;
      case GameDifficulty.hard:
        bgmFile = 'hard_심장이 먼저 달려가.mp3';
        break;
    }

    if (_currentBgm == bgmFile) return;

    _currentBgm = bgmFile;
    if (_isBgmEnabled) {
      playBgm(bgmFile);
    }
  }

  /// BGM 재생
  void playBgm(String fileName) {
    try {
      FlameAudio.bgm.play(fileName, volume: 0.5);
    } catch (e) {
      debugPrint('BGM 재생 오류: $e');
    }
  }

  /// BGM 정지
  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('BGM 정지 오류: $e');
    }
  }

  /// BGM 일시정지 (앱이 백그라운드로 갈 때 등)
  void pauseBgm() {
    if (FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.pause();
    }
  }

  /// BGM 재개
  void resumeBgm() {
    if (_isBgmEnabled && _currentBgm != null) {
      FlameAudio.bgm.resume();
    }
  }
}
