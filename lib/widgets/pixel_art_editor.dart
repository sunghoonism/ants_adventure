import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class PixelArtEditor extends StatefulWidget {
  final GameObjectType type;
  final Size gridSize;

  const PixelArtEditor({
    Key? key,
    required this.type,
    required this.gridSize,
  }) : super(key: key);

  @override
  _PixelArtEditorState createState() => _PixelArtEditorState();
}

class _PixelArtEditorState extends State<PixelArtEditor> {
  late List<List<Color>> _grid;
  Color _selectedColor = Colors.black;
  bool _isEraser = false;

  final List<Color> _palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    _grid = List.generate(
      widget.gridSize.height.toInt(),
      (_) => List.generate(
        widget.gridSize.width.toInt(),
        (_) => Colors.transparent,
      ),
    );
  }

  void _handleTap(int row, int col) {
    setState(() {
      _grid[row][col] = _isEraser ? Colors.transparent : _selectedColor;
    });
  }

  Future<void> _completeDrawing() async {
    final Recorder = ui.PictureRecorder();
    final canvas = Canvas(Recorder);
    final paint = Paint();

    final width = widget.gridSize.width.toInt();
    final height = widget.gridSize.height.toInt();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (_grid[y][x] != Colors.transparent) {
          paint.color = _grid[y][x];
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
            paint,
          );
        }
      }
    }

    final picture = Recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final bytes = byteData.buffer.asUint8List();
      Navigator.pop(context, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String typeName = _getTypeNameKorean(widget.type);

    return Scaffold(
      appBar: AppBar(
        title: Text('$typeName 그리기'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          TextButton(
            onPressed: () => _initGrid(),
            child: const Text('초기화',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _completeDrawing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('완성'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: widget.gridSize.width / widget.gridSize.height,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                        color: Colors.white,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSize =
                              constraints.maxWidth / widget.gridSize.width;
                          return GestureDetector(
                            onPanUpdate: (details) {
                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              final localPos =
                                  box.globalToLocal(details.globalPosition);
                              final col = (localPos.dx / cellSize).floor();
                              final row = (localPos.dy / cellSize).floor();
                              if (row >= 0 &&
                                  row < widget.gridSize.height &&
                                  col >= 0 &&
                                  col < widget.gridSize.width) {
                                _handleTap(row, col);
                              }
                            },
                            onTapDown: (details) {
                              final col =
                                  (details.localPosition.dx / cellSize).floor();
                              final row =
                                  (details.localPosition.dy / cellSize).floor();
                              if (row >= 0 &&
                                  row < widget.gridSize.height &&
                                  col >= 0 &&
                                  col < widget.gridSize.width) {
                                _handleTap(row, col);
                              }
                            },
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.gridSize.width.toInt(),
                              ),
                              itemCount: (widget.gridSize.width *
                                      widget.gridSize.height)
                                  .toInt(),
                              itemBuilder: (context, index) {
                                final row = index ~/ widget.gridSize.width;
                                final col =
                                    index % widget.gridSize.width.toInt();
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _grid[row][col],
                                    border: Border.all(
                                        color: Colors.black12, width: 0.1),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildToolBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolButton(
                  icon: Icons.edit,
                  label: '연필',
                  isSelected: !_isEraser,
                  onPressed: () => setState(() => _isEraser = false),
                ),
                _buildToolButton(
                  icon: Icons.cleaning_services,
                  label: '지우개',
                  isSelected: _isEraser,
                  onPressed: () => setState(() => _isEraser = true),
                ),
                const VerticalDivider(),
                ..._palette.map((color) => GestureDetector(
                      onTap: () => setState(() {
                        _selectedColor = color;
                        _isEraser = false;
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color && !_isEraser
                                ? Colors.deepPurple
                                : Colors.grey,
                            width:
                                _selectedColor == color && !_isEraser ? 3 : 1,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                )),
          ],
        ),
      ),
    );
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
      default:
        return '기타';
    }
  }
}
