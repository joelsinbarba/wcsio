import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:super_dash/game/game.dart';

class ItemEffect extends SpriteAnimationComponent
    with HasGameRef<SuperDashGame> {
  ItemEffect({
    required this.type,
    super.position,
  }) : super(removeOnFinish: true, priority: 22);

  final ItemType type;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    if (type == ItemType.egg) {
      animation = await gameRef.loadSpriteAnimation(
        'anim/spritesheet_fx_large.png',
        SpriteAnimationData.sequenced(
          amount: 14,
          amountPerRow: 7,
          textureSize: Vector2.all(192),
          stepTime: .042,
          loop: false,
        ),
      );
      size = Vector2.all(192);
      anchor = Anchor.center;
    } else if (type == ItemType.goldenFeather) {
      animation = await gameRef.loadSpriteAnimation(
        'anim/spritesheet_fx_large.png',
        SpriteAnimationData.sequenced(
          amount: 14,
          amountPerRow: 7,
          textureSize: Vector2.all(192),
          stepTime: .042,
          loop: false,
        ),
      );
      final effect = ColorEffect(
        Colors.blue,
        EffectController(duration: .2),
        opacityTo: 0.6,
      );
      add(effect);
      size = Vector2.all(192);
      anchor = Anchor.center;
    } else {
      animation = await gameRef.loadSpriteAnimation(
        'anim/spritesheet_fx_small.png',
        SpriteAnimationData.sequenced(
          amount: 9,
          amountPerRow: 3,
          textureSize: Vector2.all(64),
          stepTime: .042,
          loop: false,
        ),
      );
      size = Vector2.all(64);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    //final player = gameRef.player;
    // if (player == null) return;

    // position = player.position;
  }
}
