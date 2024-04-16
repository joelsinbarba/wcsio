import 'dart:ui';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';
import 'package:super_dash/constants/constants.dart';
import 'package:super_dash/gen/assets.gen.dart';
import 'package:super_dash/l10n/l10n.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  static PageRoute<void> route() {
    return HeroDialogRoute(
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: const ResultScreen(),
      ),
    );
  }

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late RiveAnimationController _controller;

  /// Is the animation currently playing?
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = OneShotAnimation(
      'star3',
      autoplay: false,
      onStop: () => setState(() => _isPlaying = false),
      onStart: () => setState(() => _isPlaying = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bodyStyle = AppTextStyles.bodyLarge;
    const highlightColor = Color(0xFF9CECCD);
    final linkStyle = AppTextStyles.bodyLarge.copyWith(
      color: highlightColor,
      decoration: TextDecoration.underline,
      decorationColor: highlightColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: 300,
          height: 300,
          child: Positioned.fill(
            child: Image.asset(
              'images/stars.png',
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
        Expanded(
          flex: 30,
          child: Container(
            height: 300,
            color: Colors.transparent,
            child: RiveAnimation.asset(
              'assets/rive/game_stars.riv',
              animations: const ['star3'],
              fit: BoxFit.contain,
              controllers: [_controller],
            ),
          ),
        ),
        Expanded(
          flex: 60, // Give middle section more weight for expansion
          child: Container(
            color: Colors.black.withOpacity(.2),
          ),
        ),
        Expanded(
          flex: 20,
          child: Container(
            color: Colors.blue,
          ),
        ),
        /* const SizedBox(height: 24),
        Assets.images.gameLogo.image(width: 230),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                l10n.aboutSuperDash,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(text: l10n.learn),
                    TextSpan(
                      text: l10n.howWeBuiltSuperDash,
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlString(Urls.howWeBuilt),
                    ),
                    TextSpan(
                      text: l10n.inFlutterAndGrabThe,
                    ),
                    TextSpan(
                      text: l10n.openSourceCode,
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlString(Urls.githubRepo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                child: Text('Continue'),
                style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    padding:
                        EdgeInsets.symmetric(vertical: 30, horizontal: 60)),
              )
            ],
          ),
        ),
        const SizedBox(height: 40), */
      ],
    );
  }
}
