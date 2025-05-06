import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

/// 이미지 설정 대화상자
class ImageSettingsDialog extends StatefulWidget {
  const ImageSettingsDialog({Key? key}) : super(key: key);

  @override
  _ImageSettingsDialogState createState() => _ImageSettingsDialogState();
}

class _ImageSettingsDialogState extends State<ImageSettingsDialog> {
  final ImageService _imageService = ImageService();
  
  // 각 게임 오브젝트 타입별 이미지 파일 경로
  Map<GameObjectType, String?> imagePaths = {};
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }
  
  /// 저장된 모든 이미지 로드
  Future<void> _loadSavedImages() async {
    // 마운트된 상태인지 확인 후 setState 호출
    if (mounted) {
      setState(() => isLoading = true);
    } else {
      isLoading = true;
    }
    
    try {
      // cloud 타입을 제외한 나머지 오브젝트 이미지 로드
      for (var type in GameObjectType.values) {
        if (type != GameObjectType.cloud) {
          imagePaths[type] = await _imageService.getImagePath(type);
        }
      }
      
      // 마운트된 상태인지 다시 확인
      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('이미지 로드 오류: $e');
      
      // 오류 발생 시에도 마운트 상태 확인
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  /// 새 이미지 선택
  Future<void> _pickImage(GameObjectType type) async {
    try {
      final String? path = await _imageService.pickAndSaveImage(type);
      
      // 이미지 선택 후 마운트 상태 확인
      if (path != null && mounted) {
        setState(() {
          imagePaths[type] = path;
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
    }
  }
  
  /// 이미지 초기화
  Future<void> _resetAllImages() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 이미지 초기화'),
        content: const Text('정말로 모든 커스텀 이미지를 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 먼저 대화상자 닫기
              
              try {
                // cloud는 제외하고 초기화
                for (var type in GameObjectType.values) {
                  if (type != GameObjectType.cloud) {
                    await _imageService.resetImage(type);
                  }
                }
                
                // 마운트된 상태인지 확인 후 이미지 다시 로드
                if (mounted) {
                  await _loadSavedImages();
                }
              } catch (e) {
                debugPrint('이미지 초기화 오류: $e');
              }
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 350,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('게임 오브젝트 이미지 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // 개미 이미지 설정
                _buildImageSelector(GameObjectType.ant, '개미 캐릭터'),
                
                // 벌 이미지 설정
                _buildImageSelector(GameObjectType.bee, '벌'),
                
                // 개미핥기 이미지 설정
                _buildImageSelector(GameObjectType.anteater, '개미핥기'),
                
                // 구름 이미지 설정은 제거
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _resetAllImages,
                      child: const Text('모두 초기화'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
  
  /// 각 이미지 선택기 위젯 생성
  Widget _buildImageSelector(GameObjectType type, String label) {
    final String? imagePath = imagePaths[type];
    final bool hasImage = imagePath != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 이미지 미리보기 또는 기본 아이콘
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.file(File(imagePath), fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_not_supported, size: 30),
          ),
          const SizedBox(width: 16),
          
          // 레이블 및 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  hasImage ? '이미지가 설정되었습니다' : '이미지를 선택해주세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasImage ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // 이미지 선택 버튼
          ElevatedButton(
            onPressed: () => _pickImage(type),
            child: Text(hasImage ? '변경' : '선택'),
          ),
        ],
      ),
    );
  }
} 