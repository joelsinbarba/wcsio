/* import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class Ember<T extends FlameGame> extends SpriteAnimationComponent
    with HasGameReference<T> {
  Ember({super.position, Vector2? size, super.key})
      : super(
          size: size ?? Vector2.all(50),
          anchor: Anchor.center,
          priority: 0,
        );

  final _defaultColor = Colors.red;
  late TreeShadow shadow;
  @override
  void update(double dt) {
    //size += Vector2(10, 10) * dt;
    // TODO: implement update
    super.update(dt);
  }

  @mustCallSuper
  @override
  void onLoad() async {
    final defaultPaint = Paint()
      ..color = _defaultColor
      ..style = PaintingStyle.stroke;
    animation = await game.loadSpriteAnimation(
      'animations/ember.png',
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: Vector2.all(16),
        stepTime: 0.15,
      ),
    );
    priority = 10;
    shadow = TreeShadow();
    shadow.anchor = Anchor.center;
    shadow.position = Vector2(size.x / 2, size.y / 2);
    add(shadow);
    shadow.growing = true;
    shadow.myParent = this;
  }
}

class TreeShadow extends PositionComponent {
  TreeShadow() : super(priority: 0);
  bool growing = false;
  double radius = 0;
  double maxradius = 100;
  Ember? myParent;

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
      ..drawCircle(Offset(size.x / 2, size.y / 2), radius, backBorderPaint1)
      ..drawRect(Rect.fromLTWH(0, 0, size.x, size.y), backBorderPaint);
    ;
    super.render(canvas);
  }
}
 */