import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/ants_adventure_game.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GameWidget.controlled(
          gameFactory: AntsAdventureGame.new,
        ),
      ),
    ),
  );
}
