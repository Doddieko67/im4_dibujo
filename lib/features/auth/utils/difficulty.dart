enum OrigamiDifficulty { easy, medium, hard }

int getPointsForDifficulty(OrigamiDifficulty difficulty) {
  switch (difficulty) {
    case OrigamiDifficulty.easy:
      return 10;
    case OrigamiDifficulty.medium:
      return 25;
    case OrigamiDifficulty.hard:
      return 50;
  }
}
