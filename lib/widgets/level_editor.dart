import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../game/ants_adventure_game.dart';
import '../game/game_config.dart';

class LevelEditor extends StatefulWidget {
  const LevelEditor({Key? key}) : super(key: key);

  @override
  _LevelEditorState createState() => _LevelEditorState();
}

class _LevelEditorState extends State<LevelEditor> {
  final ImageService _imageService = ImageService();

  // 현재 배치된 에셋들 (타입별로 하나씩만 저장하거나 여러개 가능하게 할지 결정)
  // 유저 요구사항: "에셋이 위치된 높이값을 저장할 수 있어" -> 타입별 대표 높이 저장으로 해석
  Map<GameObjectType, Offset?> _placedPositions = {};

  GameObjectType? _selectedType;
  Offset? _draggingPosition;
  bool _isValidPosition = true;

  // 새 파라미터들
  double _globalDifficulty = 1.0;
  Map<GameObjectType, double> _spawnIntervals = {
    GameObjectType.bee: GameConfig.defaultBeeSpawnInterval,
    GameObjectType.anteater: GameConfig.defaultAnteaterSpawnInterval,
  };
  Map<GameObjectType, double> _baseSpeeds = {
    GameObjectType.ant: 1.0,
    GameObjectType.bee: 1.0,
    GameObjectType.anteater: 1.0,
    GameObjectType.car: 1.0,
    GameObjectType.airplane: 1.0,
  };

  // 에셋 크기 정의 (ImageService에서 가져오거나 하드코딩)
  final Map<GameObjectType, Size> _assetSizes = {
    GameObjectType.ant: const Size(32, 18),
    GameObjectType.bee: const Size(32, 12),
    GameObjectType.anteater: const Size(70, 28),
    GameObjectType.cloud: const Size(60, 30),
    GameObjectType.car: const Size(50, 25),
    GameObjectType.airplane: const Size(60, 30),
  };

  Map<GameObjectType, String?> _imagePaths = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    for (var type in GameObjectType.values) {
      if (type == GameObjectType.cloud || type == GameObjectType.ant) continue;
      _imagePaths[type] = await _imageService.getImagePath(type);
      final height = await _imageService.getCustomHeight(type);
      if (height != null) {
        // 초기 X 위치는 중앙 근처로 설정
        _placedPositions[type] = Offset(100.0 + (type.index * 50), height);
      }
    }

    // 만약 현재 슬롯 정보가 있다면 해당 데이터로 초기화 가능 (Optional)
    if (AntsAdventureGame.selectedSlotIndex != null) {
      final data = await _imageService
          .loadSlotData(AntsAdventureGame.selectedSlotIndex!);
      if (data != null) {
        setState(() {
          _placedPositions =
              Map.from(data['heights'] as Map<GameObjectType, double>).map(
                  (key, value) => MapEntry(
                      key,
                      Offset(100.0 + (key.index * 50),
                          value))); // Convert double height back to Offset
          _baseSpeeds = Map.from(data['speeds'] as Map<GameObjectType, double>);
          _spawnIntervals =
              Map.from(data['intervals'] as Map<GameObjectType, double>);
          _globalDifficulty = data['globalDifficulty'] as double;
        });
      }
    }

    setState(() {});
  }

  void _onAssetTap(GameObjectType type) {
    setState(() {
      if (_selectedType == type) {
        _selectedType = null;
      } else {
        _selectedType = type;
      }
    });
  }

  void _updateDragging(Offset localPos, Size previewSize) {
    if (_selectedType == null) return;

    final assetSize = _assetSizes[_selectedType]!;

    // 화면 밖으로 나가는지 체크 (경계값)
    bool outOfBounds = false;
    if (localPos.dx < assetSize.width / 2 ||
        localPos.dx > previewSize.width - assetSize.width / 2 ||
        localPos.dy < 30 + assetSize.height / 2 || // 천장 30
        localPos.dy > previewSize.height - 50 - assetSize.height / 2) {
      // 바닥 50
      outOfBounds = true;
    }

    // 다른 에셋과 겹치는지 체크
    bool overlapping = false;
    final currentRect = Rect.fromCenter(
      center: localPos,
      width: assetSize.width,
      height: assetSize.height,
    );

    _placedPositions.forEach((type, pos) {
      if (type != _selectedType && pos != null) {
        final otherSize = _assetSizes[type]!;
        final otherRect = Rect.fromCenter(
          center: pos,
          width: otherSize.width,
          height: otherSize.height,
        );
        if (currentRect.overlaps(otherRect)) {
          overlapping = true;
        }
      }
    });

    setState(() {
      _draggingPosition = localPos;
      _isValidPosition = !outOfBounds && !overlapping;
    });
  }

  void _placeAsset() {
    if (_selectedType != null &&
        _draggingPosition != null &&
        _isValidPosition) {
      setState(() {
        _placedPositions[_selectedType!] = _draggingPosition;
        _draggingPosition = null;
      });
    } else {
      setState(() {
        _draggingPosition = null;
      });
    }
  }

  Future<void> _saveLayout() async {
    // 슬롯 선택 다이얼로그 표시
    _showSaveSlotDialog();
  }

  Future<void> _showSaveSlotDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장할 슬롯 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              final slotIndex = index + 1;
              return ListTile(
                title: Text('슬롯 $slotIndex'),
                onTap: () async {
                  final heights = _placedPositions.map((key, value) =>
                      MapEntry(key, value?.dy ?? 150.0)); // 기본값 150

                  await _imageService.saveSlotData(
                    slotIndex: slotIndex,
                    heights: heights,
                    speeds: _baseSpeeds,
                    intervals: _spawnIntervals,
                    globalDifficulty: _globalDifficulty,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // 슬롯 다이얼로그 닫기
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('슬롯 $slotIndex에 저장되었습니다.')),
                    );
                    Navigator.pop(context); // 에디터 닫기
                  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 만들기 (레벨 에디터)'),
        backgroundColor: Colors.deepPurple,
        actions: [
          TextButton(
            onPressed: _saveLayout,
            child: const Text('저장',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단: 게임 배경 프리뷰 (60%)
          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (details) => _updateDragging(
                      details.localPosition, constraints.biggest),
                  onPanUpdate: (details) => _updateDragging(
                      details.localPosition, constraints.biggest),
                  onPanEnd: (_) => _placeAsset(),
                  child: Container(
                    color: const Color(0xFF5F9EAB), // 기본 배경색
                    child: Stack(
                      children: [
                        // 천장
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(height: 30, color: Colors.grey),
                        ),
                        // 바닥
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(height: 50, color: Colors.grey),
                        ),
                        // 배치된 에셋들
                        ..._placedPositions.entries
                            .where((e) => e.value != null)
                            .map((e) {
                          return _buildAssetWidget(e.key, e.value!,
                              isGhost: false);
                        }).toList(),
                        // 드래그 중인 고스트
                        if (_selectedType != null && _draggingPosition != null)
                          _buildAssetWidget(_selectedType!, _draggingPosition!,
                              isGhost: true),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 하단: 에셋 팔레트 (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('설정 및 에셋 팔레트',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // 전역 난이도 설정
                    _buildSettingsRow(
                      label: '전역 난이도 배율',
                      value: _globalDifficulty,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (val) =>
                          setState(() => _globalDifficulty = val),
                    ),

                    const Divider(),
                    const SizedBox(height: 8),

                    // 선택된 에셋에 대한 추가 설정
                    if (_selectedType != null) ...[
                      Text('${_getTypeNameKorean(_selectedType!)} 설정',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_spawnIntervals.containsKey(_selectedType))
                        _buildSettingsRow(
                          label: '스폰 간격 (초)',
                          value: _spawnIntervals[_selectedType!]!,
                          min: 0.5,
                          max: 10.0,
                          onChanged: (val) => setState(
                              () => _spawnIntervals[_selectedType!] = val),
                        ),
                      if (_baseSpeeds.containsKey(_selectedType))
                        _buildSettingsRow(
                          label: '기본 속도 배율',
                          value: _baseSpeeds[_selectedType!]!,
                          min: 0.5,
                          max: 5.0,
                          onChanged: (val) =>
                              setState(() => _baseSpeeds[_selectedType!] = val),
                        ),
                      const Divider(),
                    ],

                    const Text('에셋 선택하여 설정하기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: GameObjectType.values
                          .where((t) =>
                              t != GameObjectType.cloud &&
                              t != GameObjectType.ant)
                          .map((type) {
                        final isSelected = _selectedType == type;
                        return InkWell(
                          onTap: () => _onAssetTap(type),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.deepPurple.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(child: _buildPreviewIcon(type)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewIcon(GameObjectType type) {
    final path = _imagePaths[type];
    if (path != null) {
      return Image.file(File(path), width: 40, height: 40, fit: BoxFit.contain);
    }
    return Image.asset(_getAssetPathForType(type),
        width: 40, height: 40, fit: BoxFit.contain);
  }

  Widget _buildAssetWidget(GameObjectType type, Offset position,
      {required bool isGhost}) {
    final size = _assetSizes[type]!;
    final path = _imagePaths[type];

    Color color = Colors.transparent;
    if (isGhost) {
      color = _isValidPosition
          ? Colors.green.withOpacity(0.5)
          : Colors.red.withOpacity(0.5);
    }

    return Positioned(
      left: position.dx - size.width / 2,
      top: position.dy - size.height / 2,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: color,
          border: isGhost
              ? Border.all(
                  color: _isValidPosition ? Colors.green : Colors.red, width: 2)
              : null,
        ),
        child: Opacity(
          opacity: isGhost ? 0.7 : 1.0,
          child: path != null
              ? Image.file(File(path), fit: BoxFit.fill)
              : Image.asset(_getAssetPathForType(type), fit: BoxFit.fill),
        ),
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
        return ''; // Cloud is filtered out, but keeping for completeness if it were ever used.
      default:
        return '';
    }
  }

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

  Widget _buildSettingsRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 25,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
              width: 30,
              child: Text(value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
