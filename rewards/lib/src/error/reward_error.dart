sealed class RewardError extends Error {
  final String message;

  RewardError(this.message);

  @override
  String toString() {
    return 'RewardError: $message';
  }
}

class NotEnoughRewardTokensError extends RewardError {
  NotEnoughRewardTokensError() : super('Not enough reward tokens');
}
