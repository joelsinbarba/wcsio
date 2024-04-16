import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:super_dash/game/components/ember.dart';
import 'package:super_dash/game/components/item_effect.dart';
import 'package:super_dash/game/entities/item.dart';

class RequesterSprite<T extends FlameGame> extends SpriteComponent
    with HasGameReference<T> {
  RequesterSprite(this.text, {super.position, Vector2? size, super.key})
      : super(
          size: size ?? Vector2.all(120),
          anchor: Anchor.center,
          priority: 0,
        );

  GItemType? itemType;
  ColorEffect? myColorEffect;
  late TextComponent mainText;
  late TextComponent strokeText;
  final _defaultColor = Colors.red;
  String text;

  final textPaint = TextPaint(
    style: const TextStyle(
      fontFamily: 'Fredoka',
      // fontSize: 18.0,
      fontSize: 64.0,
      color: Colors.white,
    ),
  );

  final strokePaint = TextPaint(
    style: TextStyle(
        fontSize: 64.0,
        fontFamily: 'Fredoka',
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = Colors.black),
  );

  static final Paint backBorderPaint = Paint()
    ..color = const Color(0xffff00000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20;
  @override
  void update(double dt) {
    //size += Vector2(10, 10) * dt;
    // TODO: implement update
    super.update(dt);
  }

  void updateText(String newText) {
    if (newText == '0') newText = "Done";
    game.world.add(
      ItemEffect(
        type: ItemType.acorn,
        position: position.clone(),
      )
        ..priority = 100
        ..size = Vector2.all(500) /* ..size = Vector2.all(tileSize * 5) */,
    );
    text = newText;
    mainText.text = text;
    strokeText.text = text;
  }

  @mustCallSuper
  @override
  void onLoad() async {
    final defaultPaint = Paint()
      ..color = _defaultColor
      ..style = PaintingStyle.stroke;

    String spriteName = 'animations/containers.png';

    switch (itemType) {
      case GItemType.typeA:
        spriteName = 'animations/containers.png';
        break;
      case GItemType.typeB:
        spriteName = 'animations/organic.png';
        break;
      case GItemType.typeC:
        spriteName = 'animations/waste.png';
        break;
      default:
    }

    // tHIS IS NOT USEFUL, just needed
    sprite = await game.loadSprite(
      spriteName,
      srcSize: Vector2.all(10),
      srcPosition: Vector2(100, 0),
    );

    add(
      SpriteComponent(
        anchor: Anchor.center,
        // position: Vector2.all(),
        sprite: await game.loadSprite(
          'animations/requestBubble.png',
          srcSize: Vector2(112, 115),
          srcPosition: Vector2(0, 0),
        ),
        size: Vector2.all(180),
      ),
    );

    add(
      SpriteComponent(
        anchor: Anchor.center,
        // position: Vector2.all(),
        sprite: await game.loadSprite(
          spriteName,
          srcSize: Vector2.all(100),
          srcPosition: Vector2(100, 0),
        ),
        position: Vector2(0, -16),
        size: Vector2.all(120),
      ),
    );

    /*   text = TextComponent(
      anchor: Anchor.center,
      text: '',
      position: Vector2.all(40),
      textRenderer: textPaint,
    );
    add(text); */

    mainText = TextComponent(
        text: text,
        textRenderer: textPaint,
        anchor: Anchor.center,
        position: Vector2.all(40));
    strokeText = TextComponent(
        text: text,
        textRenderer: strokePaint,
        anchor: Anchor.center,
        position: Vector2.all(40));

    await addAll([strokeText, mainText]);

    int rand = getRandomNumberBetween(5, 8);

    add(
      MoveEffect.by(
        Vector2(0, 20),
        InfiniteEffectController(ZigzagEffectController(period: rand.toDouble())
            /*    NoiseEffectController(
            duration: 5,
            noise: PerlinNoise(
              frequency: 1,
            ),
          ), */
            ),
      ),
    );
  }
}

int getRandomNumberBetween(int min, int max) {
  final random = Random();
  return min + random.nextInt(max - min + 1);
}
