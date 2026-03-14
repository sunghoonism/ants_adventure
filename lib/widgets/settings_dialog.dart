import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../services/audio_service.dart';
import '../game/ants_adventure_game.dart';
import '../game/game_config.dart';
import 'pixel_art_editor.dart';
import 'level_editor.dart';

/// 게임 설정 대화상자 (이미지 및 오디오 설정)
class SettingsDialog extends StatefulWidget {
  final AntsAdventureGame game;
  const SettingsDialog({Key? key, required this.game}) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final ImageService _imageService = ImageService();
  final AudioService _audioService = AudioService();

  // 각 게임 오브젝트 타입별 이미지 파일 경로
  Map<GameObjectType, String?> imagePaths = {};
  bool isLoading = true;
  bool isBgmEnabled = true;

  @override
  void initState() {
    super.initState();
    isBgmEnabled = _audioService.isBgmEnabled;
    _loadSavedImages();
  }

  /// 저장된 모든 이미지 로드
  Future<void> _loadSavedImages() async {
    if (mounted) {
      setState(() => isLoading = true);
    } else {
      isLoading = true;
    }

    try {
      for (var type in GameObjectType.values) {
        if (type != GameObjectType.cloud) {
          imagePaths[type] = await _imageService.getImagePath(type);
        }
      }

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('이미지 로드 오류: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// 이미지 선택 방식 결정 (그리기 vs 사진)
  Future<void> _onSelectImageAction(GameObjectType type) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('이미지 변경 방식 선택'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'draw'),
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.deepPurple),
                SizedBox(width: 12),
                Text('직접 그리기'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'pick'),
            child: const Row(
              children: [
                Icon(Icons.photo_library, color: Colors.blue),
                SizedBox(width: 12),
                Text('사진 선택하기'),
              ],
            ),
          ),
        ],
      ),
    );

    if (result == 'draw') {
      await _openPixelEditor(type);
    } else if (result == 'pick') {
      await _pickImage(type);
    }
  }

  /// 픽셀 에디터 열기
  Future<void> _openPixelEditor(GameObjectType type) async {
    final Size gridSize = _imageService.getPixelSizeForType(type);
    final Uint8List? bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => PixelArtEditor(type: type, gridSize: gridSize),
      ),
    );

    if (bytes != null) {
      final String? path = await _imageService.saveDrawnImage(type, bytes);
      if (path != null && mounted) {
        setState(() {
          imagePaths[type] = path;
        });
      }
    }
  }

  /// 새 이미지 선택 (사진 앨범)
  Future<void> _pickImage(GameObjectType type) async {
    try {
      final String? path = await _imageService.pickAndSaveImage(type);
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
              Navigator.pop(context);
              try {
                for (var type in GameObjectType.values) {
                  if (type != GameObjectType.cloud) {
                    await _imageService.resetImage(type);
                  }
                }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        width: 380,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('게임 설정',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // 오디오 설정 섹션
                    _buildSectionHeader('오디오 설정'),
                    SwitchListTile(
                      title: const Text('배경음악 (BGM)'),
                      subtitle:
                          Text(isBgmEnabled ? '음악이 켜져 있습니다' : '음악이 꺼져 있습니다'),
                      value: isBgmEnabled,
                      onChanged: (bool value) async {
                        await _audioService.setBgmEnabled(value);
                        if (mounted) {
                          setState(() {
                            isBgmEnabled = value;
                          });
                        }
                      },
                      secondary: Icon(
                          isBgmEnabled ? Icons.music_note : Icons.music_off),
                    ),

                    const Divider(height: 16), // Divider 높이 축소

                    // 게임 커스텀 섹션
                    _buildSectionHeader('게임 커스터마이징'),
                    _buildCustomizationButtons(),

                    const Divider(height: 16),

                    // 이미지 설정 섹션
                    _buildSectionHeader('이미지 설정', showResetButton: true),
                    // 개미, 벌, 개미핥기, 구름 표시
                    _buildImageSelector(GameObjectType.ant, '개미 캐릭터'),
                    _buildImageSelector(GameObjectType.bee, '벌'),
                    _buildImageSelector(GameObjectType.anteater, '개미핥기'),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 메인 메뉴로 가기 버튼 (제일 밑)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.game.returnToMainMenu();
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('메인 메뉴로 가기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showResetButton = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1.1,
            ),
          ),
          if (showResetButton)
            InkWell(
              onTap: _resetAllImages,
              child: const Row(
                children: [
                  Icon(Icons.refresh, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    '이미지 초기화',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 각 이미지 선택기 위젯 생성
  Widget _buildImageSelector(GameObjectType type, String label) {
    final String? imagePath = imagePaths[type];
    final bool hasImage = imagePath != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // 패딩 축소 (8.0 -> 4.0)
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(_getAssetPathForType(type),
                        fit: BoxFit.contain),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  hasImage ? '커스텀 이미지' : '기본 이미지',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasImage ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _onSelectImageAction(type),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 32),
            ),
            child: Text(hasImage ? '변경' : '선택',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 게임 커스터마이징 버튼들 생성
  Widget _buildCustomizationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            label: '게임 만들기',
            icon: Icons.create,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LevelEditor()),
              ).then((_) => _loadSavedImages());
            },
            color: Colors.deepPurple,
          ),
          _buildActionButton(
            label: '게임 열기',
            icon: Icons.play_circle_fill,
            onPressed: () => _showSlotSelectionDialog(context),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getAssetPathForType(GameObjectType type) {
    switch (type) {
      case GameObjectType.ant:
        return 'assets/images/preview/ant.png';
      case GameObjectType.bee:
        return 'assets/images/preview/bee.png';
      case GameObjectType.anteater:
        return 'assets/images/preview/anteater.png';
      case GameObjectType.car:
        return 'assets/images/preview/car.png';
      case GameObjectType.airplane:
        return 'assets/images/preview/airplane.png';
      case GameObjectType.cloud:
        return 'assets/images/preview/cloud_preview.png'; // 구름 프리뷰 이미지 필요 (없으면 기본 이미지 사용하도록 로직 확인)
      default:
        return '';
    }
  }

  /// 슬롯 선택 다이얼로그 (게임 열기용)
  Future<void> _showSlotSelectionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('불러올 슬롯 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              final slotIndex = index + 1;
              return FutureBuilder<bool>(
                future: _imageService.hasSlotData(slotIndex),
                builder: (context, snapshot) {
                  final hasData = snapshot.data ?? false;
                  return ListTile(
                    title: Text('슬롯 $slotIndex'),
                    subtitle: Text(hasData ? '저장된 데이터가 있습니다' : '데이터 없음'),
                    enabled: hasData,
                    onTap: () async {
                      final data = await _imageService.loadSlotData(slotIndex);
                      if (data != null) {
                        AntsAdventureGame.selectedSlotIndex = slotIndex;
                        AntsAdventureGame.useCustomSettings = true;
                        AntsAdventureGame.customHeights =
                            data['heights'] as Map<GameObjectType, double>;
                        AntsAdventureGame.customSpeeds =
                            data['speeds'] as Map<GameObjectType, double>;
                        AntsAdventureGame.customIntervals =
                            data['intervals'] as Map<GameObjectType, double>;
                        AntsAdventureGame.customGlobalDifficulty =
                            data['globalDifficulty'] as double;

                        if (context.mounted) {
                          Navigator.pop(context); // 슬롯 다이얼로그 닫기
                          Navigator.pop(context); // 설정 다이얼로그 닫기

                          // 즉시 게임 시작 (또는 재시작)
                          widget.game.startGame(GameDifficulty.normal);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('슬롯 $slotIndex 데이터를 불러오고 게임을 시작합니다.')),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
