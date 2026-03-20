enum TimerStatus { stopped, running, paused }

class TournamentState {
  final int currentLevelIndex;
  final int remainingSeconds;
  final TimerStatus status;

  const TournamentState({
    this.currentLevelIndex = 0,
    this.remainingSeconds = 0,
    this.status = TimerStatus.stopped,
  });

  TournamentState copyWith({
    int? currentLevelIndex,
    int? remainingSeconds,
    TimerStatus? status,
  }) {
    return TournamentState(
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
    );
  }
}
