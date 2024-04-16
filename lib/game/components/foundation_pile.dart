import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Viewport;
import 'package:super_dash/game/entities/pile.dart';

import 'the_card.dart';

class FoundationPile extends PositionComponent
    with ParentIsA<Viewport>
    implements Pile {
  FoundationPile(int intSuit, this.checkWin, {super.position})
      : super(size: Vector2(130, 180));

  final VoidCallback checkWin;

  final List<TheCard> _cards = [];

  //#region Pile API

  bool get isFull => _cards.length == 13;

  @override
  bool canMoveCard(TheCard card, MoveMethod method) =>
      _cards.isNotEmpty && card == _cards.last && method != MoveMethod.tap;

  @override
  bool canAcceptCard(TheCard card) {
    return true;
    /*  final topCardRank = _cards.isEmpty ? 0 : _cards.last.rank.value;
    return card.suit == suit &&
        card.rank.value == topCardRank + 1 &&
        card.attachedCards.isEmpty; */
  }

  @override
  void removeCard(TheCard card, MoveMethod method) {
    assert(canMoveCard(card, method));
    _cards.removeLast();
  }

  @override
  void returnCard(TheCard card) {
    card.position = position;
    card.priority = _cards.indexOf(card);
  }

  @override
  void acquireCard(TheCard card) {
    assert(card.isFaceUp);
    card.position = position;
    card.priority = _cards.length;
    card.pile = this;
    _cards.add(card);
    if (isFull) {
      checkWin(); // Get KlondikeWorld to check all FoundationPiles.
    }
  }

  //#endregion

  //#region Rendering

  final _borderPaint = Paint()
    ..style = PaintingStyle.fill
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);
  // late final _suitPaint = Paint()
  //   ..color = suit.isRed ? const Color(0x3a000000) : const Color(0x64000000)
  //   ..blendMode = BlendMode.luminosity;

/*   @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(
        /* KlondikeGame.cardRRect */ RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 130, 180),
          const Radius.circular(1),
        ),
        _borderPaint);
    // suit.sprite.render(
    //   canvas,
    //   position: size / 2,
    //   anchor: Anchor.center,
    //   size: Vector2.all(KlondikeGame.cardWidth * 0.6),
    //   overridePaint: _suitPaint,
    // );
  } */

  //#endregion
}
