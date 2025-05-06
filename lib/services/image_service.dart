import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

/// 게임 오브젝트 유형
enum GameObjectType {
  ant,
  bee,
  anteater,
  cloud,
}

/// 이미지 관리 서비스
class ImageService {
  static final ImageService _instance = ImageService._internal();
  final ImagePicker _picker = ImagePicker();
  
  factory ImageService() {
    return _instance;
  }
  
  ImageService._internal();
  
  /// 이미지 선택 및 저장
  Future<String?> pickAndSaveImage(GameObjectType type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (image == null) return null;
      
      // 앱 내부 디렉토리에 이미지 저장
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${appDir.path}/$fileName';
      
      // 이미지 파일 복사
      final File newImage = await File(image.path).copy(filePath);
      
      // 이미지 경로 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(type.toString(), filePath);
      
      return filePath;
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      return null;
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