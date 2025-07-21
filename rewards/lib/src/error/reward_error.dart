sealed class RewardError extends Error {
  final String message;

  RewardError(this.message);

  @override
  String toString() {
    return 'RewardError: $message';
  }
}

/// The error thrown when the user does not have enough reward tokens
class NotEnoughRewardTokensError extends RewardError {
  NotEnoughRewardTokensError() : super('Not enough reward tokens');
}
