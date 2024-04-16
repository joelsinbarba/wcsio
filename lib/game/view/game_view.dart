import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_dash/audio/audio.dart';
import 'package:super_dash/game/game.dart';
import 'package:super_dash/game_intro/game_intro.dart';
import 'package:super_dash/l10n/l10n.dart';
import 'package:super_dash/score/bloc/score_bloc.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  static PageRoute<void> route() {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => const Game(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(),
      child: const GameView(),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          GameWidget.controlled(
            loadingBuilder: (context) => const GameBackground(),
            backgroundBuilder: (context) => const GameBackground(),
            gameFactory: () => SuperDashGame(
              gameBloc: context.read<GameBloc>(),
              audioController: context.read<AudioController>(),
            ),
            overlayBuilderMap: {
              'tapToJump': (context, game) => const TapToJumpOverlay(),
              'moves': (context, game) => const MovesOverlay(),
            },
            initialActiveOverlays: const [],
          ),
        ],
      ),
    );
  }
}

class MovesOverlay extends StatefulWidget {
  const MovesOverlay({super.key});

  @override
  State<MovesOverlay> createState() => _MovesOverlayState();
}

class _MovesOverlayState extends State<MovesOverlay> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: IgnorePointer(
        child: Container(
          /*  decoration: BoxDecoration(
            color: const Color(0xE51B1B36).withOpacity(.6),
          ), */
          child: Positioned(
              left: 580,
              right: 0,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.6),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  // Adjust background color as needed
                  child: Text(
                    context
                        .read<GameBloc>()
                        .state
                        .score
                        .toString(), // .select((ScoreBloc bloc) => bloc.score.toString()),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
          /* child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color.fromARGB(81, 177, 177, 177),
              ),
              color: const Color(0xE51B1B36),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.tapToStart,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ), */
        ),
      ),
    );
  }
}
