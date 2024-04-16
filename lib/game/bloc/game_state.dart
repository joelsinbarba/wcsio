part of 'game_bloc.dart';

class GameState extends Equatable {
  const GameState({
    required this.score,
    required this.currentLevel,
    required this.currentSection,
    required this.movesLeft,
  });

  const GameState.initial()
      : score = 0,
        currentLevel = 1,
        currentSection = 0,
        movesLeft = 25;

  final int score;
  final int movesLeft;
  final int currentLevel;
  final int currentSection;

  GameState copyWith({
    int? score,
    int? currentLevel,
    int? currentSection,
    int? movesLeft,
  }) {
    return GameState(
      score: score ?? this.score,
      currentLevel: currentLevel ?? this.currentLevel,
      currentSection: currentSection ?? this.currentSection,
      movesLeft: movesLeft ?? this.movesLeft,
    );
  }

  @override
  List<Object?> get props => [score, currentLevel, currentSection];
}
