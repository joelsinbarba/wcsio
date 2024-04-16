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

enum GItemType { typeA, typeB, typeC }

class Ember<T extends FlameGame> extends SpriteComponent
    with HasGameReference<T> {
  Ember({super.position, Vector2? size, super.key})
      : super(
          size: size ?? Vector2.all(60),
          anchor: Anchor.center,
          priority: 10,
        );

  GItemType? itemType;
  ColorEffect? myColorEffect;
  MoveEffect? moveEffect;
  SpriteComponent? glowSprite;
  final _defaultColor = Colors.red;

  static final Paint backBorderPaint = Paint()
    ..color = const Color(0xffff00000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20;
  late TreeShadow shadow;
  @override
  void update(double dt) {
    //size += Vector2(10, 10) * dt;
    // TODO: implement update
    super.update(dt);
  }

  int getRandomNumberBetween(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  @mustCallSuper
  @override
  void onLoad() async {
    itemType = GItemType.values[getRandomNumberBetween(0, 2)];
    final defaultPaint = Paint()
      ..color = _defaultColor
      ..style = PaintingStyle.stroke;

    glowSprite = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2.all(60),
      sprite: await game.loadSprite('animations/shine.png'),
      size: Vector2.all(/* tileSize */ 60 * 4),
    )..opacity = 0;
    add(glowSprite!);
    // remove(component)

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

    int rand = getRandomNumberBetween(0, 4);

    sprite = await game.loadSprite(
      spriteName,
      srcSize: Vector2.all(10),
      srcPosition: Vector2(rand.toDouble() * 100, 0),
    );

    //priority = 10;
    final effect = ColorEffect(
      Colors.black,
      EffectController(duration: .1),
      opacityFrom: 0,
      opacityTo: 0.5,
    )
      ..removeOnFinish = false
      ..pause();
    myColorEffect = effect;

    add(
      SpriteComponent(
        // anchor: Anchor.center,
        // position: Vector2.all(),
        sprite: await game.loadSprite(
          spriteName,
          srcSize: Vector2.all(100),
          srcPosition: Vector2(rand.toDouble() * 100, 0),
        ),
        size: Vector2.all(120),
      )..add(effect),
    );
    moveEffect = MoveEffect.by(
      Vector2(60, 60),
      InfiniteEffectController(
        NoiseEffectController(
          duration: 2,
          noise: PerlinNoise(
            frequency: 1,
          ),
        ),
      ),
    )..removeOnFinish = false;
    moveEffect!.pause();
    add(moveEffect!);
    // add(Bounds()..size = this.size);
    /* await game.loadSpriteAnimation(
      spriteName,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: Vector2.all(100),
        stepTime: 0.5,
      ),
    ); */
  }
}

class TreeShadow extends PositionComponent {
  TreeShadow() : super(priority: 0);
  bool growing = false;
  double radius = 0;
  double maxradius = 100;
  Ember? myParent;
  Offset? startPosition;
  Offset? endPosition;

  static final Paint backBorderPaint = Paint()
    ..color = const Color(0xffff00000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;

  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;

  @override
  FutureOr<void> onLoad() {
    // TODO: implement onLoad
    //myParent?.priority = 100;
    size = Vector2(60, 60);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // if (radius < maxradius && growing) {
    //   radius += /*  Vector2(10, 10) */ 10 * dt;
    //   size = Vector2(radius * 2, radius * 2);
    // }
    // TODO: implement update
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas
        // ..drawCircle(Offset(size.x / 2, size.y / 2), radius, backBorderPaint1)
        // ..drawRect(Rect.fromLTWH(0, 0, size.x, size.y), backBorderPaint);
        .drawLine(
      startPosition!,
      endPosition!,
      backBorderPaint1,
    );
    super.render(canvas);
  }
}

class Bounds extends PositionComponent {
  Bounds() : super(priority: 0);
  Offset? startPosition;
  Offset? endPosition;

  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20;
  @override
  void render(Canvas canvas) {
    /*  canvas
        // ..drawCircle(Offset(size.x / 2, size.y / 2), radius, backBorderPaint1)
        // ..drawRect(Rect.fromLTWH(0, 0, size.x, size.y), backBorderPaint);
        .drawLine(
      startPosition!,
      endPosition!,
      backBorderPaint1,
    ); */
    canvas.drawRect(
      Rect.fromLTWH(x, y, size.x, size.y),
      backBorderPaint1,
    );
    super.render(canvas);
  }
}

class Line extends PositionComponent {
  Line() : super(priority: 0);
  Offset? startPosition;
  Offset? endPosition;

  static final Paint backBorderPaint = Paint()
    ..color = const Color(0xffff00000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 40;

  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 40;

  static final Paint backBorderPaint2 = Paint()
    ..color = const Color(0xffFFFFFF).withOpacity(.8)
    ..style = PaintingStyle.fill
    ..strokeWidth = 40;

  @override
  void render(Canvas canvas) {
    canvas
      // ..drawRect(Rect.fromLTWH(0, 0, size.x, size.y), backBorderPaint);
      ..drawLine(
        startPosition!,
        endPosition!,
        backBorderPaint2,
      ) /* ..drawCircle(startPosition!, 40, backBorderPaint2) */;
    super.render(canvas);
  }
}
