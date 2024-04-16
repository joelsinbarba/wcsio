import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gaimon/gaimon.dart';
import 'package:super_dash/audio/audio.dart';
import 'package:super_dash/game/components/ember.dart';
import 'package:super_dash/game/components/item_effect.dart';
import 'package:super_dash/game/components/requester_sprite.dart';
import 'package:super_dash/game/entities/item.dart';
import 'package:flame/rendering.dart';

class RequesterSlot {
  Vector2? position;
  Request? requesterSprite;
}

class Requester<T extends FlameGame> extends Component
    with HasGameReference<T> {
  Requester(this.requests, this.requesterSlots, this.audioController) {
    //_activeRequests = requests.toList();
  }
  final List<Request> requests;
  final List<RequesterSlot> requesterSlots;
  final AudioController audioController;
  //late List<Request> _activeRequests;

  @override
  FutureOr<void> onLoad() {
    // TODO: implement onLoad
    print('requests ${requests}');

    for (var i = 0; i < 5; i++) {
      RequesterSprite rq =
          RequesterSprite('✅', position: requesterSlots[i].position)
            ..priority = 10
            ..itemType = requests[i].typeRequested;
      requests[i].requesterSprite = rq;
      rq.text = requests[i].amountRequested.toString();
      game.world.add(rq);
      // rq.position.x += rq.size.x * 1.2 /*  / 2 */;
    }
    return super.onLoad();
  }

  int processDeliveredItem(Ember deliveredItem) {
    var activeRequests =
        requests.where((x) => x.amountDelivered < x.amountRequested);

    // print('Active requests are: ${activeRequests}');
    bool requestHandled = false;

    for (final request in activeRequests) {
      if (request.typeRequested == deliveredItem.itemType &&
          request.amountDelivered < request.amountRequested &&
          (request.amountRequested - request.amountDelivered > 0)) {
        // print('Should process this now ${deliveredItem.itemType}');

        Request correspondingRequest = requests.firstWhere(
          (x) =>
              x.requesterSprite!.itemType == deliveredItem.itemType &&
              x.amountDelivered != x.amountRequested,
        );

        game.world.add(
          ItemEffect(
            type: ItemType.egg,
            position: deliveredItem.position.clone(),
          )..priority = 100 /* ..size = Vector2.all(tileSize * 5) */,
        );

        request.amountDelivered++;
        int numberToUpdate = request.amountRequested - request.amountDelivered;

        final effect = MoveToEffect(
          correspondingRequest.requesterSprite!.position,
          DelayedEffectController(
            CurvedEffectController(.6, Curves.easeIn),
            delay: .1 /* * (i + 1) */,
          ),
          onComplete: () => {
            deliveredItem.removeFromParent(),
            request.requesterSprite!.updateText(
              numberToUpdate.toString(),
            ),
            removeRequests(),
          },
        );

        deliveredItem.add(effect);

        requestHandled = true;

        return 0;
      }
    }

    if (!requestHandled) {
      // No matching request found, print "Add 100 points"
      print('Add 100 points, because no one wants ${deliveredItem.itemType}');
      deliveredItem.scale = Vector2.all(.2);
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) Gaimon.heavy();
      final seffect = ScaleEffect.to(
        Vector2.all(.6),
        EffectController(duration: 0.2, curve: Curves.easeInOut),
        onComplete: () => {
          deliveredItem.scale = Vector2.all(.6),
          deliveredItem.removeFromParent()
        },
      );
      game.world.add(
        ItemEffect(
          type: ItemType.egg,
          position: deliveredItem.position.clone(),
        )..priority = 100 /* ..size = Vector2.all(tileSize * 5) */,
      );

      deliveredItem.add(seffect);
      if (checkWin()) return 2;
      return 1;
    }

    return 0;
  }

  void removeRequests() {
    for (final request in requests) {
      if (request.isDone) continue;
      if ((request.amountRequested - request.amountDelivered) == 0) {
        request.requesterSprite!.decorator
            .addLast(PaintDecorator.grayscale(opacity: 1));

        audioController.playSfx(Sfx.acornPickup);
        request.isDone = true;
      }
    }

    for (var i = 0; i < requesterSlots.length; i++) {
      if (!requesterSlots[i].requesterSprite /* !.isDone */ != null) continue;
      // This one's emtpy, so find first incomplete request
      for (var j = i + 1; j < requesterSlots.length; j++) {
        if (!requesterSlots[i].requesterSprite!.isDone) {
          print(
              'moving element at ${j} to ${i}, should be ${requesterSlots[i]}');

          /* final fxx = MoveToEffect(
            requesterSlots[i].position!,
            EffectController(duration: 1, startDelay: .5, curve: Curves.linear),
          ); */
          //requests[j].requesterSprite!.add(fxx);
          // requests[j].requesterSprite!.position = requesterSlots[i].position!;
          break;
        }
      }
    }

    String srow = "";

    for (var i = 0; i < requesterSlots.length; i++) {
      srow += (requesterSlots[i].requesterSprite != null) ? 'X' : 'O';
    }
    print('${srow}\n');
/*     for (var i = 0; i < requests.length; i++) {
      if (requests[i].isDone) {
        print('ignoring ${i}');
        continue;
      }
      if (i < 0 && !requests[i - 1].isDone) {
        continue;
      }
      // requests[i].requesterSprite!.position = requesterPositions[i];
      final effect = MoveToEffect(
        /*  requesterPositions[iteratePos] */ requests[i]
                .requesterSprite!
                .position -
            Vector2(200, 0),
        EffectController(duration: 1, startDelay: .5, curve: Curves.linear),
      );
      requests[i].requesterSprite!.add(effect);
      iteratePos++;
    } */
  }

  bool checkWin() {
    for (final request in requests) {
      if (request.amountDelivered != request.amountRequested) {
        // print('not yet');
        return false;
      }
    }
    return true;
  }
}

class Request {
  final GItemType typeRequested;
  final int amountRequested;
  int amountDelivered;
  RequesterSprite? requesterSprite;
  bool isDone = false;

  Request(this.typeRequested, this.amountRequested,
      {this.amountDelivered = 0, this.requesterSprite});

  @override
  String toString() =>
      "\n${typeRequested.name} delivered: $amountDelivered/$amountRequested \n";
}
