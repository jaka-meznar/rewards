///At least number of reward tokens for a user and set the reward tokens for a user needs to be implemented
abstract class RewardQuery {
  /// Get the currentnumber of reward tokens for a user
  Future<int?> getNumberOfRewardTokensForUser();

  /// Set the number of reward tokens for a user
  Future<void> setNumberOfRewardTokensForUser(int numberOfRewardTokens);

  /// Optional. Can be set when creating the reward core. Gets the max number of reward tokens if needed from a query.
  Future<int?> getMaxNumberOfRewardTokens() async {
    return null;
  }

  Future<void> dispose() async {}
}
