import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class BtnComponent<T extends FlameGame> extends PositionComponent
    with HasGameReference<T> {
  BtnComponent(
    this.text,
  ) : super(priority: 0);
  Offset? startPosition;
  Offset? endPosition;
  String text;
  late TextComponent mainText;
  late TextComponent strokeText;

  final header = TextPaint(
    style: const TextStyle(
      fontFamily: 'Fredoka',
      // fontSize: 18.0,
      fontSize: 12.0,
      color: Colors.white,
    ),
  );

  final headerStroke = TextPaint(
    style: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Fredoka',
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..strokeWidth = 6
          ..color = Colors.black),
  );

  final regular = TextPaint(
    style: const TextStyle(
      fontFamily: 'Fredoka',
      // fontSize: 18.0,
      fontSize: 32.0,
      color: Colors.white,
    ),
  );

  final stroke = TextPaint(
    style: TextStyle(
        fontSize: 32.0,
        fontFamily: 'Fredoka',
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Colors.black),
  );

  void updateText(String t) {
    text = t;
    strokeText.text = text;
    mainText.text = text;
  }

  @override
  FutureOr<void> onLoad() async {
    add(SpriteComponent(
      // anchor: Anchor.center,
      position: Vector2(
          10,
          game.camera.viewport.size.y -
              MediaQueryData.fromView(
                      ui.PlatformDispatcher.instance.implicitView!)
                  .padding
                  .bottom -
              74 -
              20),
      sprite: await game.loadSprite('animations/btns.png',
          srcSize: Vector2.all(81), srcPosition: Vector2(488, 0)),
      size: Vector2.all(74),
    ));

    // await addAll([strokeText, mainText]);
    return super.onLoad();
  }
}
