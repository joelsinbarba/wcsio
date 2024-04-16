import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class Moves<T extends FlameGame> extends PositionComponent
    with HasGameReference<T> {
  Moves(
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
      anchor: Anchor.center,
      position: Vector2.all(0),
      sprite: await game.loadSprite('animations/roundRect.png'),
      size: Vector2(120, 50),
    ));
    add(TextComponent(
        text: 'MOVES',
        textRenderer: headerStroke,
        anchor: Anchor.center,
        position: Vector2(0, -26)));
    add(TextComponent(
        text: 'MOVES',
        textRenderer: header,
        anchor: Anchor.center,
        position: Vector2(0, -26)));

    mainText = TextComponent(
      text: text,
      textRenderer: regular,
      anchor: Anchor.center,
    );
    strokeText = TextComponent(
      text: text,
      textRenderer: stroke,
      anchor: Anchor.center,
    );

    await addAll([strokeText, mainText]);
    return super.onLoad();
  }
/*   @override
  void render(Canvas canvas) {
    canvas
      // ..drawRect(Rect.fromLTWH(0, 0, size.x, size.y), backBorderPaint);
      ..drawLine(
        startPosition!,
        endPosition!,
        backBorderPaint2,
      ) /* ..drawCircle(startPosition!, 40, backBorderPaint2) */;
    super.render(canvas);
  } */
}
