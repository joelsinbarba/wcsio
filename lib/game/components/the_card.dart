import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/animation.dart';
import 'package:leap/leap.dart';
import 'package:super_dash/game/components/ember.dart';
import 'package:super_dash/game/entities/pile.dart';

import 'foundation_pile.dart';

class TheCard extends PositionComponent
    with DragCallbacks, TapCallbacks, HasWorldReference<LeapWorld> {
  TheCard(/* int intRank, int intSuit, */ CameraComponent camera,
      {this.isBaseCard = false})
      : super(
          size: Vector2(130, 180),
        );

  Pile? pile;

  // A Base Card is rendered in outline only and is NOT playable. It can be
  // added to the base of a Pile (e.g. the Stock Pile) to allow it to handle
  // taps and short drags (on an empty Pile) with the same behavior and
  // tolerances as for regular cards (see KlondikeGame.dragTolerance) and using
  // the same event-handling code, but with different handleTapUp() methods.
  final bool isBaseCard;

  bool _faceUp = false;
  bool _isAnimatedFlip = false;
  bool _isFaceUpView = false;
  bool _isDragging = false;
  Vector2 _whereCardStarted = Vector2(0, 0);

  final List<TheCard> attachedCards = [];

  bool get isFaceUp => _faceUp;
  bool get isFaceDown => !_faceUp;
  void flip() {
    if (_isAnimatedFlip) {
      // Let the animation determine the FaceUp/FaceDown state.
      _faceUp = _isFaceUpView;
    } else {
      // No animation: flip and render the card immediately.
      _faceUp = !_faceUp;
      _isFaceUpView = _faceUp;
    }
  }

  @override
  String toString() => 'THIS BE DA CARD'; // e.g. "Q♠" or "10♦"

  //#region Rendering

  @override
  void render(Canvas canvas) {
    if (isBaseCard) {
      _renderBaseCard(canvas);
      return;
    }
    if (_isFaceUpView) {
      _renderFront(canvas);
    } else {
      _renderBack(canvas);
    }
    // canvas.drawCircle(Offset(size.x / 2, size.y / 2), 1, backBorderPaint1);
    // canvas.drawRRect(
    //     RRect.fromRectAndRadius(
    //       Vector2(1, 1).toRect(),
    //       const Radius.circular(1),
    //     ),
    //     backBorderPaint1);
  }

  static final Paint backBackgroundPaint = Paint()
    ..color = const Color(0xff380c02);
  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final Paint backBorderPaint2 = Paint()
    ..color = const Color(0x5CEF971B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 35;
  static final RRect cardRRect = RRect.fromRectAndRadius(
    Vector2(130, 180).toRect(),
    const Radius.circular(10),
  );
  static final RRect backRRectInner = cardRRect.deflate(40);
  // static final Sprite flameSprite = klondikeSprite(1367, 6, 357, 501);

  void _renderBack(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBackgroundPaint);
    canvas.drawRRect(cardRRect, backBorderPaint1);
    canvas.drawRRect(backRRectInner, backBorderPaint2);
    // flameSprite.render(canvas, position: size / 2, anchor: Anchor.center);
  }

  void _renderBaseCard(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBorderPaint1);
  }

  static final Paint frontBackgroundPaint = Paint()
    ..color = const Color(0xff000000);

  static final Paint frontBackgroundPaintRed = Paint()
    ..color = const Color(0xffFF0000);
  static final Paint frontBackgroundPaintYellow = Paint()
    ..color = const Color(0xffFFFF00);
  static final Paint redBorderPaint = Paint()
    ..color = const Color(0xffece8a3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xff7ab2e8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final blueFilter = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0x880d8bff),
      BlendMode.srcATop,
    );
  // static final Sprite redJack = klondikeSprite(81, 565, 562, 488);
  // static final Sprite redQueen = klondikeSprite(717, 541, 486, 515);
  // static final Sprite redKing = klondikeSprite(1305, 532, 407, 549);
  // static final Sprite blackJack = klondikeSprite(81, 565, 562, 488)
  //   ..paint = blueFilter;
  // static final Sprite blackQueen = klondikeSprite(717, 541, 486, 515)
  //   ..paint = blueFilter;
  // static final Sprite blackKing = klondikeSprite(1305, 532, 407, 549)
  //   ..paint = blueFilter;

  void _renderFront(Canvas canvas) {
    Paint paint;
    if (!canSpawn) {
      paint = frontBackgroundPaint;
    } else if (_isDragging) {
      paint = frontBackgroundPaintYellow;
    } else {
      paint = frontBackgroundPaintRed;
    }
    canvas.drawRRect(cardRRect, paint);
    // canvas.drawRRect(
    //   cardRRect,
    //   suit.isRed ? redBorderPaint : blackBorderPaint,
    // );
/* 
    final rankSprite = suit.isBlack ? rank.blackSprite : rank.redSprite;
    final suitSprite = suit.sprite;
    _drawSprite(canvas, rankSprite, 0.1, 0.08);
    _drawSprite(canvas, suitSprite, 0.1, 0.18, scale: 0.5);
    _drawSprite(canvas, rankSprite, 0.1, 0.08, rotate: true);
    _drawSprite(canvas, suitSprite, 0.1, 0.18, scale: 0.5, rotate: true);
    switch (rank.value) {
      case 1:
        _drawSprite(canvas, suitSprite, 0.5, 0.5, scale: 2.5);
        break;
      case 2:
        _drawSprite(canvas, suitSprite, 0.5, 0.25);
        _drawSprite(canvas, suitSprite, 0.5, 0.25, rotate: true);
        break;
      case 3:
        _drawSprite(canvas, suitSprite, 0.5, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.5);
        _drawSprite(canvas, suitSprite, 0.5, 0.2, rotate: true);
        break;
      case 4:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
        break;
      case 5:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.5);
        break;
      case 6:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
        break;
      case 7:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.35);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        break;
      case 8:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.35);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.35, rotate: true);
        break;
      case 9:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.3);
        _drawSprite(canvas, suitSprite, 0.3, 0.4);
        _drawSprite(canvas, suitSprite, 0.7, 0.4);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.3, 0.4, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.4, rotate: true);
        break;
      case 10:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.3);
        _drawSprite(canvas, suitSprite, 0.3, 0.4);
        _drawSprite(canvas, suitSprite, 0.7, 0.4);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.3, rotate: true);
        _drawSprite(canvas, suitSprite, 0.3, 0.4, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.4, rotate: true);
        break;
      case 11:
        _drawSprite(canvas, suit.isRed ? redJack : blackJack, 0.5, 0.5);
        break;
      case 12:
        _drawSprite(canvas, suit.isRed ? redQueen : blackQueen, 0.5, 0.5);
        break;
      case 13:
        _drawSprite(canvas, suit.isRed ? redKing : blackKing, 0.5, 0.5);
        break;
    } */
  }

  void _drawSprite(
    Canvas canvas,
    Sprite sprite,
    double relativeX,
    double relativeY, {
    double scale = 1,
    bool rotate = false,
  }) {
    if (rotate) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(pi);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    sprite.render(
      canvas,
      position: Vector2(relativeX * size.x, relativeY * size.y),
      anchor: Anchor.center,
      size: sprite.srcSize.scaled(scale),
    );
    if (rotate) {
      canvas.restore();
    }
  }

  //#endregion

  //#region TheCard-Dragging

  // @override
  // void onTapCancel(TapCancelEvent event) {
  //   if (pile is StockPile) {
  //     _isDragging = false;
  //     handleTapUp();
  //   }
  // }

  @override
  void onTapDown(TapDownEvent event) {
    // TODO: implement onTapDown
    super.onTapDown(event);

    this.add(
      MoveEffect.by(Vector2(0, -10),
          EffectController(duration: 0.1, curve: Curves.easeInOut)
          //InfiniteEffectController(ZigzagEffectController(period: 0.2))
          // PerlinNoiseEffectController(duration: 0.2, frequency: 400),

          ),
    );
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // TODO: implement onTapCancel
    super.onTapCancel(event);
  }

  Ember tempEmber = Ember();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // if (pile is StockPile) {
    //   _isDragging = false;
    //   return;
    // }
    // Clone the position, else _whereCardStarted changes as the position does.
    _whereCardStarted = position.clone();

    if (!tempEmber.isLoaded) {
      tempEmber = Ember();
      parent!.add(tempEmber);
    } else {
      tempEmber.opacity = .3;
      tempEmber.anchor = Anchor.center;
      // tempEmber.priority = 100;
      tempEmber.shadow.radius = 0;
      tempEmber.shadow.growing = false;
      tempEmber.position =
          position + event.localPosition - Vector2(0, tempEmber.size.y / 2);
    }

    attachedCards.clear();
    if (pile?.canMoveCard(this, MoveMethod.drag) ?? false) {
      _isDragging = true;
      priority = 100;

      // if (pile is TableauPile) {
      //   final extraCards = (pile! as TableauPile).cardsOnTop(this);
      //   for (final card in extraCards) {
      //     card.priority = attachedCards.length + 101;
      //     attachedCards.add(card);
      //   }
      // }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) {
      return;
    }
    final delta = event.localDelta;
    position.add(delta);
    tempEmber.position.add(delta); // = event.localStartPosition;
    // attachedCards.forEach((card) => card.position.add(delta));
    final dropPiles = /* world */ parent!
        .componentsAtPoint(position + size / 2)
        .whereType<Pile>()
        .toList();
    if (dropPiles.isNotEmpty) {
      // print('pile!');
      canSpawn = false;
    } else {
      // print('nothing...');
      canSpawn = true;
    }

    final shadows = parent!
        .componentsAtPoint(/* position + size / 2 */ tempEmber.position)
        .whereType<TreeShadow>()
        .toList();
    for (final element in shadows) {
      if (inCircle(
        element.myParent!.position.x,
        element.myParent!.position.y,
        element.radius,
        tempEmber.position.x,
        tempEmber.position.y,
      )) {
        if (element != tempEmber.shadow) {
          tempEmber.opacity = 1;
        }
      } else {
        // print('not in circle: ${element}');
        tempEmber.opacity = .3;
      }
    }
  }

  bool inCircle(num cx, num cy, num r, num x, num y) {
    final squareDist = ((cx - x) * (cx - x)) + ((cy - y) * (cy - y));
    return squareDist <= (r * r);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging) {
      return;
    }
    _isDragging = false;

    // If short drag, return card to Pile and treat it as having been tapped.
    final shortDrag = (position - _whereCardStarted).length <
        100 / 5 /* KlondikeGame.dragTolerance */;
    if (false && attachedCards.isEmpty) {
      doMove(
        _whereCardStarted,
        onComplete: () {
          pile!.returnCard(this);
          // TheCard moves to its Foundation Pile next, if valid, or it stays put.
          handleTapUp();
        },
      );
      return;
    }

    // Find out what is under the center-point of this card when it is dropped.
    final dropPiles = parent!
        .componentsAtPoint(/* position + size / 2 */ tempEmber.position)
        .whereType<Pile>()
        .toList();
    if (dropPiles.isNotEmpty) {
      final dropPosition = (dropPiles.first as FoundationPile).position;
      doMove(
        dropPosition,
        onComplete: () {
          dropPiles.first.acquireCard(this);
        },
      );

      /*   if (dropPiles.first.canAcceptCard(this)) {
        // Found a Pile: move card(s) the rest of the way onto it.
        pile!.removeCard(this, MoveMethod.drag);
        if (dropPiles.first is TableauPile) {
          // Get TableauPile to handle positions, priorities and moves of cards.
          (dropPiles.first as TableauPile).dropCards(this, attachedCards);
          attachedCards.clear();
        } else {
          // Drop a single card onto a FoundationPile.
          final dropPosition = (dropPiles.first as FoundationPile).position;
          doMove(
            dropPosition,
            onComplete: () {
              dropPiles.first.acquireCard(this);
            },
          );
        }
        return;
      } */
      return;
    }
    final shadows = parent!
        .componentsAtPoint(/* position + size / 2 */ tempEmber.position)
        .whereType<TreeShadow>()
        .toList();
    for (final element in shadows) {
      if (inCircle(
        element.myParent!.position.x,
        element.myParent!.position.y,
        element.radius,
        tempEmber.position.x,
        tempEmber.position.y,
      )) {
        if (element != tempEmber.shadow) {
          final newEmber = Ember();
          newEmber.position = tempEmber.position;
          // tempEmber.shadow.growing = true;
          tempEmber.opacity = 1;
          parent!.add(newEmber);

          // tempEmber.shadow.radius = tempEmber.size.x;
        }
      } else {
        // print('not in circle: ${element}');
      }
    }

    // Invalid drop (middle of nowhere, invalid pile or invalid card for pile).
    /*  print('Spawn object at ${position}');
    final ember = Ember(position: position + size / 2, priority: 100);
    parent!.add(ember);
 */
    doMove(
      _whereCardStarted,
      onComplete: () {
        pile!.returnCard(this);
      },
    );
    /*  if (attachedCards.isNotEmpty) {
      attachedCards.forEach((card) {
        final offset = card.position - position;
        card.doMove(
          _whereCardStarted + offset,
          onComplete: () {
            pile!.returnCard(card);
          },
        );
      });
      attachedCards.clear();
    } */
  }

  //#endregion

  //#region Card-Tapping

  // Tap a face-up card to make it auto-move and go out (if acceptable), but
  // if it is face-down and on the Stock Pile, pass the event to that pile.

  @override
  void onTapUp(TapUpEvent event) {
    handleTapUp();
  }

  void handleTapUp() {
    // Can be called by onTapUp or after a very short (failed) drag-and-drop.
    // We need to be more user-friendly towards taps that include a short drag.
    if (pile?.canMoveCard(this, MoveMethod.tap) ?? false) {
      // final suitIndex = suit.value;
      // if (world.foundations[suitIndex].canAcceptCard(this)) {
      //   pile!.removeCard(this, MoveMethod.tap);
      //   doMove(
      //     world.foundations[suitIndex].position,
      //     onComplete: () {
      //       world.foundations[suitIndex].acquireCard(this);
      //     },
      //   );
      // }
    } /* else if (pile is StockPile) {
      world.stock.handleTapUp(this);
    } */
  }

  //#endRegion

  //#region Effects

  void doMove(
    Vector2 to, {
    double speed = 10.0,
    double start = 0.0,
    int startPriority = 100,
    Curve curve = Curves.easeOutQuad,
    VoidCallback? onComplete,
  }) {
    assert(speed > 0.0, 'Speed must be > 0 widths per second');
    final dt = (to - position).length / (speed * size.x);
    assert(dt > 0, 'Distance to move must be > 0');
    add(
      CardMoveEffect(
        to,
        EffectController(duration: dt, startDelay: start, curve: curve),
        transitPriority: startPriority,
        onComplete: () {
          onComplete?.call();
        },
      ),
    );
  }

  void doMoveAndFlip(
    Vector2 to, {
    double speed = 10.0,
    double start = 0.0,
    Curve curve = Curves.easeOutQuad,
    VoidCallback? whenDone,
  }) {
    assert(speed > 0.0, 'Speed must be > 0 widths per second');
    final dt = (to - position).length / (speed * size.x);
    assert(dt > 0, 'Distance to move must be > 0');
    priority = 100;
    add(
      MoveToEffect(
        to,
        EffectController(duration: dt, startDelay: start, curve: curve),
        onComplete: () {
          turnFaceUp(
            onComplete: whenDone,
          );
        },
      ),
    );
  }

  bool canSpawn = false;

  void turnFaceUp({
    double time = 0.3,
    double start = 0.0,
    VoidCallback? onComplete,
  }) {
    assert(!_isFaceUpView, 'Card must be face-down before turning face-up.');
    assert(time > 0.0, 'Time to turn card over must be > 0');
    assert(start >= 0.0, 'Start tim must be >= 0');
    _isAnimatedFlip = true;
    anchor = Anchor.topCenter;
    position += Vector2(width / 2, 0);
    priority = 100;
    add(
      ScaleEffect.to(
        Vector2(scale.x / 100, scale.y),
        EffectController(
          startDelay: start,
          curve: Curves.easeOutSine,
          duration: time / 2,
          onMax: () {
            _isFaceUpView = true;
          },
          reverseDuration: time / 2,
          onMin: () {
            _isAnimatedFlip = false;
            _faceUp = true;
            anchor = Anchor.topLeft;
            position -= Vector2(width / 2, 0);
          },
        ),
        onComplete: () {
          onComplete?.call();
        },
      ),
    );
  }

  //#endregion
}

class CardMoveEffect extends MoveToEffect {
  CardMoveEffect(
    super.destination,
    super.controller, {
    super.onComplete,
    this.transitPriority = 100,
  });

  final int transitPriority;

  @override
  void onStart() {
    super.onStart(); // Flame connects MoveToEffect to EffectController.
    parent?.priority = transitPriority;
  }
}
