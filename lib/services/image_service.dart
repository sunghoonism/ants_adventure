import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../game/game_config.dart';
export '../game/game_config.dart' show GameObjectType;

/// 이미지 관리 서비스
class ImageService {
  static final ImageService _instance = ImageService._internal();
  final ImagePicker _picker = ImagePicker();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  /// 오브젝트 타입별 가로세로 비율 가져오기
  CropAspectRatio _getAspectRatioForType(GameObjectType type) {
    switch (type) {
      case GameObjectType.ant:
        return const CropAspectRatio(ratioX: 32, ratioY: 18); // 1.78
      case GameObjectType.bee:
        return const CropAspectRatio(ratioX: 32, ratioY: 12); // 2.67
      case GameObjectType.anteater:
        return const CropAspectRatio(ratioX: 70, ratioY: 28); // 2.5
      case GameObjectType.cloud:
        return const CropAspectRatio(ratioX: 2, ratioY: 1); // 60:30
      case GameObjectType.car:
        return const CropAspectRatio(ratioX: 50, ratioY: 25);
      case GameObjectType.airplane:
        return const CropAspectRatio(ratioX: 60, ratioY: 30);
      default:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
    }
  }

  /// 오브젝트 타입별 픽셀 크기 가져오기
  Size getPixelSizeForType(GameObjectType type) {
    switch (type) {
      case GameObjectType.ant:
        return const Size(32, 18);
      case GameObjectType.bee:
        return const Size(32, 12);
      case GameObjectType.anteater:
        return const Size(70, 28);
      case GameObjectType.cloud:
        return const Size(60, 30);
      case GameObjectType.car:
        return const Size(50, 25);
      case GameObjectType.airplane:
        return const Size(60, 30);
      default:
        return const Size(32, 32);
    }
  }

  /// 오브젝트 타입별 이름 가져오기
  String _getTypeNameKorean(GameObjectType type) {
    switch (type) {
      case GameObjectType.ant:
        return '개미';
      case GameObjectType.bee:
        return '벌';
      case GameObjectType.anteater:
        return '개미핥기';
      case GameObjectType.cloud:
        return '구름';
      case GameObjectType.car:
        return '자동차';
      case GameObjectType.airplane:
        return '비행기';
      default:
        return '기타';
    }
  }

  /// 이미지 선택 및 저장 (크롭 기능 포함)
  Future<String?> pickAndSaveImage(GameObjectType type) async {
    try {
      // 1. 갤러리에서 이미지 선택 (크기 제한 없음)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return null;

      // 2. 이미지 크롭
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: _getAspectRatioForType(type),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '${_getTypeNameKorean(type)} 이미지 크롭',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true, // 비율 고정
          ),
          IOSUiSettings(
            title: '${_getTypeNameKorean(type)} 이미지 크롭',
            aspectRatioLockEnabled: true, // 비율 고정
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      // 크롭 취소 시
      if (croppedFile == null) return null;

      // 3. 앱 내부 디렉토리에 이미지 저장
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          '${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${appDir.path}/$fileName';

      // 크롭된 이미지 파일 복사
      await File(croppedFile.path).copy(filePath);

      // 4. 이미지 경로 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(type.toString(), filePath);

      return filePath;
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      return null;
    }
  }

  /// 그린 이미지 저장
  Future<String?> saveDrawnImage(GameObjectType type, Uint8List bytes) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'drawn_${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${appDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      // 이미지 경로 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(type.toString(), filePath);

      return filePath;
    } catch (e) {
      debugPrint('그린 이미지 저장 오류: $e');
      return null;
    }
  }

  /// 오브젝트 타입별 높이 저장
  Future<void> saveCustomHeight(GameObjectType type, double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${type}_height', height);
  }

  /// 오브젝트 타입별 높이 가져오기
  Future<double?> getCustomHeight(GameObjectType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${type}_height');
  }

  // --- 슬롯 기반 저장 기능 ---

  /// 특정 슬롯에 데이터 저장
  Future<void> saveSlotData({
    required int slotIndex,
    required Map<GameObjectType, double> heights,
    required Map<GameObjectType, double> speeds,
    required Map<GameObjectType, double> intervals,
    required double globalDifficulty,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = 'slot_${slotIndex}_';

    // 저장 시간 기록
    await prefs.setString(
        '${prefix}save_time', DateTime.now().toIso8601String());

    // 높이 저장
    for (var entry in heights.entries) {
      await prefs.setDouble('${prefix}${entry.key}_height', entry.value);
    }

    // 속도 저장
    for (var entry in speeds.entries) {
      await prefs.setDouble('${prefix}${entry.key}_speed', entry.value);
    }

    // 간격 저장
    for (var entry in intervals.entries) {
      await prefs.setDouble('${prefix}${entry.key}_interval', entry.value);
    }

    // 전역 난이도 저장
    await prefs.setDouble('${prefix}global_difficulty', globalDifficulty);
  }

  /// 특정 슬롯에서 데이터 로드
  Future<Map<String, dynamic>?> loadSlotData(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = 'slot_${slotIndex}_';

    if (!prefs.containsKey('${prefix}save_time')) return null;

    final Map<GameObjectType, double> heights = {};
    final Map<GameObjectType, double> speeds = {};
    final Map<GameObjectType, double> intervals = {};

    for (var type in GameObjectType.values) {
      final height = prefs.getDouble('${prefix}${type}_height');
      if (height != null) heights[type] = height;

      final speed = prefs.getDouble('${prefix}${type}_speed');
      if (speed != null) speeds[type] = speed;

      final interval = prefs.getDouble('${prefix}${type}_interval');
      if (interval != null) intervals[type] = interval;
    }

    final globalDifficulty =
        prefs.getDouble('${prefix}global_difficulty') ?? 1.0;
    final saveTime = prefs.getString('${prefix}save_time');

    return {
      'heights': heights,
      'speeds': speeds,
      'intervals': intervals,
      'globalDifficulty': globalDifficulty,
      'saveTime': saveTime,
    };
  }

  /// 슬롯에 데이터가 있는지 확인
  Future<bool> hasSlotData(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('slot_${slotIndex}_save_time');
  }

  /// 슬롯 데이터 삭제
  Future<void> clearSlotData(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = 'slot_${slotIndex}_';
    final keys = prefs.getKeys().where((key) => key.startsWith(prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// 커스텀 설정 존재 여부 확인
  Future<bool> hasCustomHeights() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in GameObjectType.values) {
      if (prefs.containsKey('${type}_height')) return true;
    }
    return false;
  }

  /// 모든 커스텀 설정 초기화
  Future<void> clearCustomSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in GameObjectType.values) {
      await prefs.remove('${type}_height');
    }
  }

  /// 저장된 이미지 경로 가져오기
  Future<String?> getImagePath(GameObjectType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(type.toString());
  }

  /// 저장된 이미지를 File 객체로 가져오기
  Future<File?> getImageFile(GameObjectType type) async {
    final String? path = await getImagePath(type);
    if (path == null) return null;

    final File file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// 특정 유형의 이미지 초기화
  Future<void> resetImage(GameObjectType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(type.toString());

    // 기존 이미지 파일도 삭제
    final String? path = await getImagePath(type);
    if (path != null) {
      final File file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('이미지 파일 삭제 오류: $e');
        }
      }
    }
  }

  /// 모든 이미지 초기화
  Future<void> resetAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in GameObjectType.values) {
      await prefs.remove(type.toString());
    }
  }
}
