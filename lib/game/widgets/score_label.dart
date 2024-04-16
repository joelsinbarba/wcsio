import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_dash/game/bloc/game_bloc.dart';
import 'package:super_dash/gen/assets.gen.dart';
import 'package:super_dash/l10n/l10n.dart';

class ScoreLabel extends StatelessWidget {
  const ScoreLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final score = context.select(
      (GameBloc bloc) => bloc.state.score,
    );

    return SafeArea(
      child: IgnorePointer(
        child: Container(
          /*  decoration: BoxDecoration(
            color: const Color(0xE51B1B36).withOpacity(.6),
          ), */
          child: Positioned(
              // right: 20,
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
                l10n.gameScoreLabel(
                    score), // .select((ScoreBloc bloc) => bloc.score.toString()),
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
