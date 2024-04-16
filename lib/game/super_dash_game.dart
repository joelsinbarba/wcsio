import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flame/cache.dart';
import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame/src/camera/viewport.dart';
import 'package:flame/text.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:leap/leap.dart';
import 'package:super_dash/audio/audio.dart';
import 'package:super_dash/game/BtnComponent.dart';
import 'package:super_dash/game/MovesComponent.dart';
import 'package:super_dash/game/components/ember.dart';
import 'package:super_dash/game/components/foundation_pile.dart';
import 'package:super_dash/game/components/the_card.dart';
import 'package:super_dash/game/entities/requester.dart';
import 'package:super_dash/game/game.dart';
import 'package:super_dash/game_intro/view/game_info_dialog.dart';
import 'package:super_dash/game_intro/view/result_screen.dart';
import 'package:super_dash/score/score.dart';
import 'package:flame/palette.dart';
import 'package:gaimon/gaimon.dart';

bool _tsxPackingFilter(Tileset tileset) {
  return !(tileset.source ?? '').startsWith('anim');
}

Paint _layerPaintFactory(double opacity) {
  return Paint()
    ..color = Color.fromRGBO(255, 255, 255, opacity)
    ..isAntiAlias = false;
}

class SuperDashGame extends LeapGame
    with
        TapDetector,
        HasKeyboardHandlerComponents,
        // MouseMovementDetector,
        HasCollisionDetection,
        // PanDetector,
        ScrollDetector,
        ScaleDetector,
        DoubleTapCallbacks {
  SuperDashGame({
    required this.gameBloc,
    required this.audioController,
    this.customBundle,
    this.inMapTester = true,
  }) : super(
          tileSize: 64,
          configuration: const LeapConfiguration(
            tiled: TiledOptions(
              atlasMaxX: 4048,
              atlasMaxY: 4048,
              tsxPackingFilter: _tsxPackingFilter,
              layerPaintFactory: _layerPaintFactory,
              atlasPackingSpacingX: 4,
              atlasPackingSpacingY: 4,
            ),
          ),
        );

  final _cameraViewport = Vector2(1024, 1024);
  static const prefix = 'assets/map/';
  static const _sections = [
    'flutter_runnergame_map_A.tmx',
    'flutter_runnergame_map_B.tmx',
    'flutter_runnergame_map_C.tmx',
  ];
  static const _sectionsBackgroundColor = [
    (Color(0xFFDADEF6), Color(0xFFEAF0E3)),
    (Color(0xFFEBD6E1), Color(0xFFC9C8E9)),
    (Color(0xFF002052), Color(0xFF0055B4)),
  ];
  final CircleComponent _targetComponent = CircleComponent(
    radius: 200,
    position: Vector2(80, 60),
    anchor: Anchor.center,
    paint: BasicPalette.green.paint(),
    priority: 1000,
  );

  final GameBloc gameBloc;
  final AssetBundle? customBundle;
  final AudioController audioController;
  final List<VoidCallback> _inputListener = [];

  late final SpriteSheet itemsSpritesheet;
  final bool inMapTester;

  GameState get state => gameBloc.state;

  Player? get player => world.firstChild<Player>();

  List<Tileset> get tilesets => leapMap.tiledMap.tileMap.map.tilesets;
  final defaultPaint = Paint()
    ..color = Colors.cyan
    ..style = PaintingStyle.fill;

  final List<TheCard> cards = [];
  static const double cardGap = 175.0;
  static const double topGap = 500.0;
  static const double cardWidth = 1000.0;
  static const double cardHeight = 1400.0;
  static const double cardRadius = 100.0;
  static const double cardSpaceWidth = cardWidth + cardGap;
  static const double cardSpaceHeight = cardHeight + cardGap;
  final List<Ember> embers = [];
  final List<List<Ember?>> gridOfEmbers = [[], [], [], []];

  void checkWin() {}
  Tileset get itemsTileset {
    return tilesets.firstWhere(
      (tileset) => tileset.name == 'tile_items_v2',
    );
  }

  Tileset get enemiesTileset {
    return tilesets.firstWhere(
      (tileset) => tileset.name == 'tile_enemies_v2',
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // resized();
    // setCameraBounds(size);
  }
/* 
  void setCameraBounds(Vector2 gameSize) {
    _cameraViewport = Vector2(gameSize.x, gameSize.y);
    // camera.setBounds(
    //   Rectangle.fromLTRB(
    //     gameSize.x / 2,
    //     gameSize.y / 2,
    //     size.x - gameSize.x / 2,
    //     size.y - gameSize.y / 2,
    //   ),
    // );
  } */

  void addInputListener(VoidCallback listener) {
    _inputListener.add(listener);
  }

  double distance(Vector2 from, Vector2 to) {
    var a = from.x - to.x;
    var b = from.y - to.y;

    return sqrt(a * a + b * b);
  }

  late FoundationPile fp;

  Vector2 lastEmberPos = Vector2.zero();

  void clampZoom() {
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(0.35, 5);
  }

  static const zoomPerScrollUnit = 0.02;

  @override
  void onScroll(PointerScrollInfo info) {
    camera.viewfinder.zoom +=
        info.scrollDelta.global.y.sign * zoomPerScrollUnit;
    clampZoom();
  }

  late double startZoom;

  @override
  void onScaleStart(_) {
    startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    // TODO: implement onScaleEnd
    super.onScaleEnd(info);
    onStopFinger();
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      /* camera.viewfinder.zoom = startZoom * currentScale.y;
      clampZoom(); */
    } else {
      // Move camera
/*       final dropPiles = world
          .componentsAtPoint(camera.globalToLocal(info.eventPosition.global))
          .whereType<Ember>()
          .toList();

      if (dropPiles.isEmpty && connected.isEmpty) {
        camera.moveBy(
          info.delta.global * -2,
        );
        return;
      }
 */
      fingerDown(info.eventPosition.global);
    }
  }

  fingerDown(Vector2 fingerPosition) async {
    // print('Pos ${fingerPosition}  ${camera.globalToLocal(fingerPosition)}');
    final dropPiles = world /* camera.viewport */
        .componentsAtPoint(camera.globalToLocal(fingerPosition))
        .whereType<Ember>()
        .toList();
    Vector2 thisEmbersPos = Vector2.zero();

    for (final element in dropPiles) {
      if (distance(element.position, camera.globalToLocal(fingerPosition)) >=
          element.size.x / 2) {
        /*  print(
            'out of radius ${element.position} ${camera.globalToLocal(fingerPosition)}'); */
        return;
      }
      if (connected.contains(element) &&
          connected.length > 2 &&
          connected.first == element) {
        print("special!");
        return;
      }
      if (!connected.contains(element)) {
        if (element.itemType != selectedType && connected.isNotEmpty) {
          // print('Are we getting here?');
          return;
        }
        //check if element is adjacent to last
        for (var col = 0; col < colsSize; col++) {
          // print('here is ${i} ${grid[i].indexOf(element)}');
          if (grid[col].indexOf(element) != -1) {
            thisEmbersPos =
                Vector2(col.toDouble(), grid[col].indexOf(element).toDouble());
            //grid[col][grid[col].indexOf(element)] = null;
          }
        }
        for (var col = 0; col < colsSize; col++) {
          // print('here is ${i} ${grid[i].indexOf(element)}');
          if (connected.length > 0) {
            if (grid[col].indexOf(connected.last) != -1) {
              lastEmberPos = Vector2(
                  col.toDouble(), grid[col].indexOf(connected.last).toDouble());
            }
          }
        }

        /*  print(
            'Distance is ${c}, connected is ${connected.length} and lep ${lastEmberPos}'); */
        if (distance(thisEmbersPos, lastEmberPos) >= 2.0 &&
            lastEmberPos != Vector2.zero() &&
            connected.length > 0) {
          // print("Item too far, can't connect");
          return;
        }

        // if (distance(thisEmbersPos, camera.globalToLocal(fingerPosition)) >=
        //     element.size.x / 2) {
        //   print("not yet..");
        //   return;
        // }

        // print("Item too far, can't connect");
        connected.add(element);
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) Gaimon.rigid();
        //element.add(element.glowSprite!);
        element.glowSprite!.opacity = 1;
        element.moveEffect!.resume();
        // element.glowSprite = SpriteComponent(
        //   anchor: Anchor.center,
        //   position: Vector2.all(tileSize),
        //   sprite: await loadSprite('animations/shine.png'),
        //   size: Vector2.all(tileSize * 3),
        // )..priority = -1;
        // element.add(element.glowSprite as Component);

        /* element.add(
          MoveEffect.by(
              Vector2(tileSize, tileSize),
              InfiniteEffectController(
                NoiseEffectController(
                  duration: 2,
                  noise: PerlinNoise(frequency: 1),
                ),
              )),
        ); */

        selectedType = element.itemType;
        if (connected.length == 1) {
          darkenNonMatching();
        }
        audioController.playSfx(Sfx.select);
        element.scale = Vector2.all(.1);
        final effect = ScaleEffect.to(Vector2.all(.8),
            EffectController(duration: 0.2, curve: Curves.easeInOut),
            onComplete: () => element.scale = Vector2.all(.8));
        element.add(effect);
        if (connected.length > 1) {
          lines.add(Line()
            ..startPosition = Offset(connected[connected.length - 2].position.x,
                connected[connected.length - 2].position.y)
            ..endPosition =
                Offset(connected.last.position.x, connected.last.position.y)
            ..priority = 0);
        }

        world.addAll(lines);
        // element.opacity = 1;
        /*   Line line = Line()
          ..startPosition =
              Offset(connected.last.position.x, connected.last.position.y)
          ..endPosition = Offset(element.position.x, element.position.y);
        // lines.add(line);
        // world.addAll(lines);
        print(
            'Line is at ${line.startPosition},${line.endPosition} \n other is at ${connected[0].position} ');
        line.priority = 100;
        world.add(line); */
      } else if (connected.length > 1) {
        if (connected[connected.length - 2] == element) {
          if (distance(element.position, camera.globalToLocal(fingerPosition)) >
              element.size.x / 3) {
            return;
          }
          // connected.last.opacity = .5;
          connected.last.scale = Vector2.all(1);
          // final effect = ScaleEffect.to(
          //   Vector2.all(1),
          //   EffectController(duration: 0.1, curve: Curves.easeInOut),
          // );
          //connected.last.add(effect);
          connected.last.glowSprite!.opacity = 0;
          connected.last.moveEffect!.resume();
          connected.last.moveEffect!.pause();
          connected.removeLast();
          lines.last.removeFromParent();
          lines.removeLast();
          audioController.playSfx(Sfx.deselect);
        }
      }
    }
  }

  int movesLeft = 10;
  List<Ember> nonMatching = [];
  GItemType? selectedType;

  void resetColors() {
    for (final col in grid) {
      for (final row in col) {
        /*  if (rnd.nextDouble() <= 0.7 && row != null) {
          nonMatching.add(row);
        } */
        if (row!.myColorEffect != null && row!.moveEffect != null) {
          row.myColorEffect!.reset();
          row.myColorEffect!.pause();

          //row.myColorEffect!.removeFromParent();
          row.glowSprite!.opacity = 0;
          row.moveEffect!.resume();
          row.moveEffect!.pause();
        }
      }
    }
  }

  void darkenNonMatching() {
    for (final col in grid) {
      for (final row in col) {
        /*  if (rnd.nextDouble() <= 0.7 && row != null) {
          nonMatching.add(row);
        } */
        if (row!.itemType != selectedType) {
          nonMatching.add(row);
        }
      }
    }
    for (final element in nonMatching) {
      element.myColorEffect!.reset();
      element.myColorEffect!.resume();
      /* final effect = ColorEffect(
        Colors.black,
        EffectController(duration: .1),
        opacityFrom: 0,
        opacityTo: 0.5,
      );
      element.myColorEffect = effect;
      element.add(effect); */
    }
  }

  void printGridAsMatrix() {
    for (int row = 0; row < rowsSize; row++) {
      String srow = "";
      for (int col = 0; col < colsSize; col++) {
        srow += grid[col][row] != null ? 'O' : '#';
      }
      print(srow);
    }
    print('\n');
  }

  bool hasWon = false;
  /*  @override
  void onPanEnd(DragEndInfo info) {
    onStopFinger();
    super.onPanEnd(info);
  } */

  /*  @override
  void onMouseMove(PointerHoverInfo info) {
    // if (leapMap.tiledMap.isLoaded) return;
    // print(info.eventPosition.widget);'
    // final Enemy enemy = leapMap.children.whereType<Enemy>().first;
    //if (!isMoving) return;
    //myComponent.position = camera.globalToLocal(info.eventPosition.widget);

    //  spawnie.position = camera.globalToLocal(info.eventPosition.global);
//    print('Map tile is: ${camera.globalToLocal(info.eventPosition.widget)}');
    //print('Map tile is: ${leapMap.componentsAtPoint(camera.globalToLocal(info.eventPosition.widget)).toString()}');
    for (final element in leapMap
        .componentsAtPoint(camera.globalToLocal(info.eventPosition.widget))) {
      if (element is LeapMapGroundTile) {
        /* print(
            '${element.gridX}:${element.gridY} ... ${element.centerX}:${element.centerY} '); */
        // final effect = OpacityEffect.by(
        //   0.9,
        //   EffectController(duration: 5),
        // );
        /*  final effectm = RotateEffect.by(
          1,
          EffectController(duration: 2),
        );
        element.add(effectm);
        //tree.add(effectm);
        tree.size = tree.size * 20; */
      }
    }
  } */

  void removeInputListener(VoidCallback listener) {
    _inputListener.remove(listener);
  }

  void _triggerInputListeners() {
    for (final listener in _inputListener) {
      listener();
    }
  }

  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    /// Do something
    if (gridUi == null) return;
    /*  final effect = MoveToEffect(
      gridUi!.center,
      EffectController(duration: .2, startDelay: 0),
    );
    camera.viewfinder.add(effect);
    camera.viewfinder.position = gridUi!.center + Vector2(0, -300);
    camera.viewfinder.visibleGameSize =
        Vector2(gridUi!.size.x + tileSize, 2024 + tileSize); */
  }

  @override
  void onTapUp(TapUpInfo info) {
    // TODO: implement onTapUp
    super.onTapUp(info);
    onStopFinger();
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);

    //_triggerInputListeners();
    overlays.remove('tapToJump');

    fingerDown(info.eventPosition.global);
    /*  if (!fp.isLoaded)  */

    // isMoving = !isMoving;
    // spawnie.position = camera.globalToLocal(info.eventPosition.global);

    /*   if (spawnie.utilityHitbox.isColliding) {
      print('Got youuuu');
      return;
      // utilityHitbox.activeCollisions.forEach((element) {
      //   if (element is Ember) return;
      // });
      // do some specific things if hitbox is colliding
    } */

    //final gp = leapMap.tiledMap.tileMap.getLayer<ObjectGroup>('Ground');
    // TiledObject enemy = gp!.objects.first; // TiledObject(id: 9999);

    // newEnemy.position = tree.position;
  }

  List<Ember> connected = [];
  List<Line> lines = [];
  static const colsSize = 8;
  static const rowsSize = 8;
  final grid = List<List<Ember?>>.generate(
    rowsSize,
    (_) => List<Ember?>.filled(colsSize, null),
  );
  final positionsGrid = List<List<GridPosition?>>.generate(
    rowsSize,
    (_) => List<GridPosition?>.filled(colsSize, null),
  );

  late Requester requester;

  int getRandomNumberBetween(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  final requesterPositions = <RequesterSlot>[];

  Future<void> createGrid() async {
    await _setSectionBackground();

    const totalElementsSize = /* elementWidth */ 120 * 3;

    // Apply the formula to find the spacing
    var margin = (gridUi!.size.x - totalElementsSize) / (3);

    for (var i = 0; i < 5; i++) {
      requesterPositions.add(RequesterSlot()
        ..position = Vector2(
          gridUi!.topLeftPosition.x + margin + ((120 + margin) * i),
          gridUi!.topLeftPosition.y - 320,
        )
        ..occupied = false);
      /*  RequesterSprite rq = RequesterSprite('✅', position: requesterPositions[i])
        ..priority = 10
        ..itemType = requester.requests[i].typeRequested;
      requests[i].requesterSprite = rq;
      world.add(rq); */
      // rq.position.x += rq.size.x * 1.2 /*  / 2 */;
    }
    List<Request> x = [];
    for (var i = 0; i < 5; i++) {
      x.add(
        Request(
          GItemType.values[getRandomNumberBetween(0, 2)],
          getRandomNumberBetween(1, 5),
        ),
      );
    }

    requester = Requester(x, requesterPositions, audioController);
    world.add(requester);

    for (int i = 0; i < rowsSize; i++) {
      for (int j = 0; j < colsSize; j++) {
        positionsGrid[i][
                j] = /* GridPosition(
          (22 + gridUi!.topLeftPosition.x + 54 * (i)),
          (22 + gridUi!.topLeftPosition.y + 54 * (j)),
        ); */
            // do not delete next line, it's for the world
            GridPosition(360 + (tileSize * 2) * (i + 1),
                1624 + (tileSize * 2) * (j + 1));
        grid[i][j] = /* SpriteComponent(
          sprite: Sprite(image: https://stock.adobe.com/search/images?k=sprite),
          position: Vector2(j * 50, i * 50), // Adjust spacing as needed
        )..add(GridPosition(i, j));
      } */
            Ember(
          size: Vector2(/* gridUi!.size.x / colsSize */ tileSize * 2,
              tileSize * 2 /* gridUi!.size.y / rowsSize */),
          position: /* Vector2(
            (22 + gridUi!.topLeftPosition.x + 54 * i),
            (22 + gridUi!.topLeftPosition.y + 54 * j),
          ), */
              Vector2(360 + (tileSize * 2) * (i + 1),
                  1624 + (tileSize * 2) * (j + 1)),
        )..priority = 100;
        // ..opacity = .5;
        //camera.viewport.add(grid[i][j]!);
        world.add(grid[i][j]!);
        // gridOfEmbers[i].add(e);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    /*  if (inMapTester) {
      _addMapTesterFeatures();
    } */

    audioController.playSfx(Sfx.lchza);

    if (kIsWeb && audioController.isMusicEnabled) {
      // audioController.startMusic();
    }

    images = Images(
      prefix: prefix,
      bundle: customBundle,
    );

    itemsSpritesheet = SpriteSheet(
      image: await images.load('objects/tile_items_v2.png'),
      srcSize: Vector2.all(tileSize),
    );

    // await loadWorldAndMap(
    //   images: images,
    //   prefix: prefix,
    //   bundle: customBundle,
    //   tiledMapPath: _sections.first,
    // );
    // _setSectionBackground();

    // final player = Player(
    //   levelSize: leapMap.tiledMap.size.clone(),
    //   cameraViewport: _cameraViewport,
    // );

    // unawaited(
    //   world.addAll([player]),
    // );
    await createGrid();
    // await _addSpawners();
    // _addTreeHouseFrontLayer();
    //_addTreeHouseSign();

    add(
      KeyboardListenerComponent(
        keyDown: {
          LogicalKeyboardKey.space: (_) {
            // _triggerInputListeners();
            overlays.remove('tapToJump');
            return false;
          },
        },
        keyUp: {
          LogicalKeyboardKey.space: (_) {
            return false;
          },
        },
      ),
    );
    _targetComponent.position = Vector2(8, 29);
    /* movesText = TextComponent(
      text: movesLeft.toString(),
      textRenderer: regular,
      anchor: Anchor.topLeft,
      position: Vector2(
          /* MediaQueryData.fromView(ui.PlatformDispatcher.instance.implicitView!)
                  .padding
                  .left +
              20, */
          camera.viewport.size.x / 2,
          MediaQueryData.fromView(ui.PlatformDispatcher.instance.implicitView!)
                  .padding
                  .top +
              20),
    ); */
    moves = Moves(movesLeft.toString())..anchor = Anchor.center;
    camera.viewport.add(moves);
    camera.viewport.add(BtnComponent(''));
    resized();

    //or
    // movesText.position.x -= movesText.size.x / 2;
  }

  void resized() {
    moves.anchor = Anchor.topCenter;
    moves.position.x =
        (camera.viewport.size.x / 2) /*  - (movesText.size.x / 2) */;
    moves.position.y =
        MediaQueryData.fromView(ui.PlatformDispatcher.instance.implicitView!)
                .padding
                .top +
            40 /*  - (movesText.size.x / 2) */;
  }

  late Moves moves;
  // late TextComponent movesText;

  void spawnNewItems() {
    /*  AlteredCandyInfo newCandyInfo = new AlteredCandyInfo();

        //find how many null values the column has
        foreach (int column in columnsWithMissingCandy)
        {
            var emptyItems = shapes.GetEmptyItemsOnColumn(column);
            foreach (var item in emptyItems)
            {
                var go = GetRandomCandy();
                GameObject newCandy = Instantiate(go, SpawnPositions[column], Quaternion.identity)
                    as GameObject;

                newCandy.GetComponent<Shape>().Assign(go.GetComponent<Shape>().Type, item.Row, item.Column);

                if (Constants.Rows - item.Row > newCandyInfo.MaxDistance)
                    newCandyInfo.MaxDistance = Constants.Rows - item.Row;

                shapes[item.Row, item.Column] = newCandy;
                newCandyInfo.AddCandy(newCandy);
            }
        }
        return newCandyInfo; */
    for (var column = 0; column < colsSize; column++) {
      for (int row = rowsSize - 1; row >= 0; row--) {
        //print('${row} and ${column}');
        //if you find a null item
        if (grid[column][row] == null) {
          // print('null is ${row} and ${column}');
          grid[column][
                  row] = /* SpriteComponent(
          sprite: Sprite(image: https://stock.adobe.com/search/images?k=sprite),
          position: Vector2(j * 50, i * 50), // Adjust spacing as needed
        )..add(GridPosition(i, j));
      } */
              Ember(
                  position:
                      Vector2(((360 + (tileSize * 2) * (column + 1))), (1624)))
                ..size = Vector2(tileSize * 2, tileSize * 2)
                ..priority = 10
                ..scale = Vector2.zero();
          // ..opacity = .5;

          final scaleFx = ScaleEffect.to(
            Vector2.all(1),
            EffectController(duration: 0.5, curve: Curves.easeInOut),
          );

          final effect = MoveToEffect(
            Vector2(
              positionsGrid[column][row]!.i,
              positionsGrid[column][row]!.j,
            ),
            EffectController(duration: .2, startDelay: .6),
          );

          grid[column][row]?.add(scaleFx);
          grid[column][row]?.add(effect);
          world.add(grid[column][row]!);
        }
      }
    }
  }

  void bringThemDown() {
    for (var column = 0; column < colsSize; column++) {
      for (int row = rowsSize - 1; row >= 0; row--) {
        //print('${row} and ${column}');
        //if you find a null item
        if (grid[column][row] == null) {
          // print('null is ${row} and ${column}');
          //start searching for the first non-null
          for (int row2 = row - 1; row2 >= 0; row2--) {
            //if you find one, bring it down (i.e. replace it with the null you found)
            if (grid[column][row2] != null) {
              grid[column][row] = grid[column][row2];
              grid[column][row2] = null;

              //calculate the biggest distance
              // if (row2 - row > collapseInfo.MaxDistance)
              //     collapseInfo.MaxDistance = row2 - row;

              // //assign new row and column (name does not change)
              // shapes[row][column].GetComponent<Shape>().Row = row;
              // shapes[row][column].GetComponent<Shape>().Column = column;

              // collapseInfo.AddCandy(shapes[row][column]);

              // final pos = grid[column][row]?.position;
              /* grid[column][row]?.position = Vector2(
                  positionsGrid[column][row]!.i, positionsGrid[column][row]!.j); */

              // grid[column][row]?.opacity = 1;
              final effect = MoveToEffect(
                Vector2(
                  positionsGrid[column][row]!.i,
                  positionsGrid[column][row]!.j,
                ),
                EffectController(duration: .2, startDelay: .3),
              );

              grid[column][row]?.add(effect);
              /* grid[column][row]?.position = Vector2(
                positionsGrid[column][row]!.i,
                positionsGrid[column][row]!.j,
              );
 */
              break;
            }
          }
        }
      }
    }

    // printGridAsMatrix();
    // Shake effect
    if (connected.length >= 4) {
      camera.viewfinder.add(
        MoveEffect.by(
          Vector2.all(40),
          NoiseEffectController(
            duration: 0.5,
            noise: PerlinNoise(frequency: 400),
          ),
        ),
      );
    }

    connected.clear();
  }

  final Random rnd = Random();
  bool _addTheCards() {
    //final layer = leapMap.tiledMap.tileMap.renderableLayers.last;

    // world.add(TreeHouseFront(renderFront: layer.render));

    /*  int zombiesToAdd = 20;
    int counter = 0;
    while (counter < zombiesToAdd) {
      final x = rnd.nextInt(8) + 1;
      final y = rnd.nextInt(8) + 1;
      fp = FoundationPile(0, checkWin, position: Vector2(x * 100, y * 100));
      camera.viewport.add(fp);
      // add(Zombie(
      //   position: Vector2(worldTileSize * x, worldTileSize * y),
      // ));
      counter++;
    } */
    for (var i = 0; i < 4; i++) {
      final x = _cameraViewport.x - (140 * (i + 1));
      final y = _cameraViewport.y;
      fp = FoundationPile(0, checkWin, position: Vector2(x.toDouble(), y));
      camera.viewport.add(fp);
      final card = TheCard(camera);
      card.flip();
      cards.add(card);
      fp.acquireCard(card);
    }
/*     fp = FoundationPile(
      0,
      checkWin,
      position: Vector2(_cameraViewport.x - 120, 0), //Vector2(10, 0),
    );
    camera.viewport.add(fp); */

    camera.viewport.addAll(cards);

    final e = Ember(position: Vector2(400, 400));
    camera.viewport.add(e);
    //print('Cards added! ${camera.viewport.size}');
    //print(world.children);
    return true;
  }

  //  late MyComponent spawnie;
  late Enemy tree;

  void _addTreeHouseSign() {
    final gp = leapMap.tiledMap.tileMap.getLayer<ObjectGroup>('enemies');
    TiledObject enemy = gp!.objects.first; // TiledObject(id: 9999);
    tree = Enemy(
      tiledObject: enemy,
    );
    world.add(tree);
  }

  SpriteComponent? gridUi;

  void _addTreeHouseFrontLayer() {
    final layer = leapMap.tiledMap.tileMap.renderableLayers.last;
    world.add(TreeHouseFront(renderFront: layer.render));
  }

  Future<void> _setSectionBackground() async {
    // final colors = _sectionsBackgroundColor[state.currentSection];
    SpriteComponent bgSprite = SpriteComponent(
        size: Vector2(size.y, 1600), sprite: await loadSprite('bgTest.png'));
    bgSprite.size = Vector2(1024, 1024);
    camera.backdrop = bgSprite;

    gridUi = SpriteComponent(
      // size: Vector2(size.y, 1600),
      anchor: Anchor.topLeft,
      size: Vector2.all((tileSize * 2) * colsSize),
      position: /* Vector2(camera.viewport.virtualSize.x / 2,
          (camera.viewport.virtualSize.y / 2) + 100), */
          Vector2(360 + (tileSize), 1624 + (tileSize)),
      sprite: await loadSprite('grid88.png'),
    )..opacity = 1;
    /* camera.viewport */ world.add(gridUi!);

    // camera.anchor = PlayerCameraAnchor(levelSize: gridUi.size, cameraViewport: cameraViewport);

    camera =
        CameraComponent() /* .withFixedResolution(
      width: gridUi!.size.x + (tileSize * 2),
      height: gridUi!.size.y + (tileSize * 2),
    ) */
          ..world = world;
    // ..viewport = FixedAspectRatioViewport(aspectRatio: 16 / 9);
    final scaleX = camera.viewport.size.x / (gridUi!.size.x + (tileSize * 2));
    final scaleY = camera.viewport.size.y / (gridUi!.size.y + (tileSize * 2));
    //_scaleVector.setAll(min(scaleX, scaleY));
    camera.viewfinder.position = gridUi!.center + Vector2(0, -200);
    camera.viewfinder.visibleGameSize =
        Vector2(1024 + tileSize, 2024 + tileSize);
    /* camera.viewfinder.scale = Vector2(
        gridUi!.size.x + (tileSize * 2), gridUi!.size.y + (tileSize * 2)); */
    camera.setBounds(
      Rectangle.fromLTRB(
        gridUi!.topLeftPosition.x,
        gridUi!.topLeftPosition.y,
        gridUi!.topLeftPosition.x + gridUi!.size.x,
        gridUi!.topLeftPosition.y + gridUi!.size.y,
      ),
    );

    /* RectangleComponent(
      size: size.clone(),
      paint: Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.x, size.y),
          [
            Colors.red,
            colors.$2,
          ],
        ),
    ); */
  }

  void gameOver() {
    gameBloc.add(const GameOver());
    // Removed since the result didn't ended up good.
    // Leaving in comment if we decide to bring it back.
    // audioController.stopBackgroundSfx();

    world.firstChild<Player>()?.removeFromParent();

    _resetEntities();

    Future<void>.delayed(
      const Duration(seconds: 1),
      () async {
        await loadWorldAndMap(
          images: images,
          prefix: prefix,
          bundle: customBundle,
          tiledMapPath: _sections.first,
        );
        if (isLastSection || isFirstSection) {
          // _addTreeHouseFrontLayer();
        }

        if (isFirstSection) {
          _addTreeHouseSign();
        }
        final newPlayer = Player(
          levelSize: leapMap.tiledMap.size.clone(),
          cameraViewport: _cameraViewport,
        );
        await world.add(newPlayer);

        await newPlayer.mounted;
        await _addSpawners();
        overlays.add('tapToJump');
      },
    );

    if (buildContext != null) {
      final score = gameBloc.state.score;
      Navigator.of(buildContext!).push(Game.route());
    }
  }

  void _resetEntities() {
    children.whereType<ObjectGroupProximityBuilder<Player>>().forEach(
          (spawner) => spawner.removeFromParent(),
        );
    world.firstChild<TreeHouseFront>()?.removeFromParent();
    world.firstChild<TreeSign>()?.removeFromParent();

    leapMap.children
        .whereType<Enemy>()
        .forEach((enemy) => enemy.removeFromParent());
    leapMap.children
        .whereType<Item>()
        .forEach((enemy) => enemy.removeFromParent());
  }

  Future<void> _addSpawners() async {
    await addAll([
      ObjectGroupProximityBuilder<Player>(
        proximity: _cameraViewport.x * 1.5,
        tileLayerName: 'items',
        tileset: itemsTileset,
        componentBuilder: Item.new,
      ),
      ObjectGroupProximityBuilder<Player>(
        proximity: _cameraViewport.x * 1.5,
        tileLayerName: 'enemies',
        tileset: enemiesTileset,
        componentBuilder: Enemy.new,
      ),
    ]);
  }

  Future<void> _loadNewSection() async {
    final nextSectionIndex = state.currentSection + 1 < _sections.length
        ? state.currentSection + 1
        : 0;

    final nextSection = _sections[nextSectionIndex];

    _resetEntities();

    await loadWorldAndMap(
      images: images,
      prefix: prefix,
      bundle: customBundle,
      tiledMapPath: nextSection,
    );

    if (isFirstSection) {
      _addTreeHouseSign();
    }

    if (isLastSection || isFirstSection) {
      // _addTreeHouseFrontLayer();
    }

    await _addSpawners();
  }

  @override
  void onMapUnload(LeapMap map) {
    player?.velocity.setZero();
  }

  @override
  void onMapLoaded(LeapMap map) {
    player?.loadSpawnPoint();
    player?.loadRespawnPoints();
    player?.walking = true;
    player?.spritePaintColor(Colors.white);
    player?.isPlayerTeleporting = false;

    // _setSectionBackground();
  }

  void sectionCleared() {
    if (isLastSection) {
      player?.spritePaintColor(Colors.transparent);
      player?.walking = false;
    }

    _loadNewSection();

    gameBloc
      ..add(GameScoreIncreased(by: 1000 * state.currentLevel))
      ..add(GameSectionCompleted(sectionCount: _sections.length));
  }

  bool get isLastSection => state.currentSection == _sections.length - 1;
  bool get isFirstSection => state.currentSection == 0;

  void addCameraDebugger() {
    if (descendants().whereType<CameraDebugger>().isEmpty) {
      final player = world.firstChild<Player>()!;

      final cameraDebugger = CameraDebugger(
        position: player.position.clone(),
      );
      world.add(cameraDebugger);

      final anchor = PlayerCameraAnchor(
        levelSize: leapMap.tiledMap.size.clone(),
        cameraViewport: _cameraViewport,
      );
      cameraDebugger.add(anchor);
      camera.follow(anchor);

      final proximityBuilders =
          descendants().whereType<ObjectGroupProximityBuilder<Player>>();
      for (final proximityBuilder in proximityBuilders) {
        proximityBuilder.currentReference = cameraDebugger;
      }

      player.removeFromParent();
    }
  }

  void toggleInvincibility() {
    player?.isPlayerInvincible = !(player?.isPlayerInvincible ?? false);
  }

  void teleportPlayerToEnd() {
    player?.x = leapMap.tiledMap.size.x - (player?.size.x ?? 0) * 10 * 4;
    if (state.currentSection == 2) {
      player?.y = (player?.y ?? 0) - (tileSize * 4);
    }
  }

  void showHitBoxes() {
    void show() {
      descendants()
          .whereType<PhysicalEntity>()
          .where(
            (element) =>
                element is Player || element is Item || element is Enemy,
          )
          .forEach((entity) => entity.debugMode = true);
    }

    show();
    add(
      TimerComponent(
        period: 1,
        repeat: true,
        onTick: show,
      ),
    );
  }

  void _addMapTesterFeatures() {
    add(FpsComponent());
    add(
      FpsTextComponent(
        position: Vector2(100, 100),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void applyIfWon() {
    if (!hasWon) return;
    print('YOU WON!');
    // audioController.playSfx(Sfx.jump);

    final scaleFx = ScaleEffect.to(
        Vector2.all(1), EffectController(duration: 2, curve: Curves.easeInOut),
        onComplete: () => {gameOver()});
    player!.add(scaleFx);
    //gameOver();
  }

  Future<void> onStopFinger() async {
    for (final line in lines) {
      line.removeFromParent();
    }
    lines.clear();
    nonMatching.clear();
    selectedType = null;
    resetColors();
    if (connected.length < 3) {
      for (final element in connected) {
        final effect = ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.01, curve: Curves.linear),
        );
        element.add(effect);
      }
      connected.clear();
      return;
    }
    for (Ember element in connected) {
      //world.remove(element);
      // print('${element.parent} is the parent');
      for (var i = 0; i < rowsSize; i++) {
        // print('here is ${i} ${grid[i].indexOf(element)}');
        if (grid[i].indexOf(element) != -1) {
          await Future.delayed(Duration(milliseconds: 60));
          int results = requester.processDeliveredItem(element);
          if (results == 2) {
            hasWon = true;
          }

          grid[i][grid[i].indexOf(element)] = null;
          /* gameRef. */ audioController.playSfx(Sfx.bubble);
          element.scale = Vector2.all(.2);
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS) Gaimon.heavy();
          final seffect = ScaleEffect.to(Vector2.all(1),
              EffectController(duration: 0.2, curve: Curves.easeInOut),
              onComplete: () => element.scale = Vector2.all(1));
          element.add(seffect);

          // element.scale = Vector2.all(1);

          gameBloc..add(GameScoreIncreased(by: 100 * state.currentLevel));

          // element.removeFromParent();
        }
      }
      // gridOfEmbers[2][3] = null;
      // gridOfEmbers[2][2] = null;
      // gridOfEmbers[2][1] = null;
    }
    //  requester.removeRequests();

    // printGridAsMatrix();
    // lines.clear();
    connected.clear();

    movesLeft--;
    moves.updateText(movesLeft.toString());
    /*  movesText.text = movesLeft.toString();
    // reset to center
    movesText.position.x =
        (camera.viewport.size.x / 2) - (movesText.size.x / 2); */

    if (movesLeft == 0) {
      if (buildContext != null) {
        audioController.playSfx(Sfx.lchza);
        audioController.dispose();
        final score = gameBloc.state.score;
        Navigator.of(buildContext!).push(ResultScreen.route());
      }
    }

    bringThemDown();
    spawnNewItems();
    applyIfWon();
  }
}

class MySpecialHitbox extends CircleHitbox {
  MySpecialHitbox() {
    triggersParentCollision = false;
  }

// hitbox specific onCollision* functions
}

class GridElement extends Component {
  final int i;
  final int j;

  GridElement(this.i, this.j);

  @override
  bool get debugMode => false; // Avoid unnecessary widget rebuilds
}

class GridPosition extends Component {
  final double i;
  final double j;

  GridPosition(this.i, this.j);
}
