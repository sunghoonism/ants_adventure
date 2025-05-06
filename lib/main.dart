import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/ants_adventure_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 시작
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ants Adventure',
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AntsAdventureGame _game;

  @override
  void initState() {
    super.initState();
    _game = AntsAdventureGame();
  }

  @override
  Widget build(BuildContext context) {
    // 빌드 후 BuildContext 전달
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.setBuildContext(context);
    });

    return Scaffold(
      body: GameWidget(
        game: _game,
      ),
    );
  }
}
