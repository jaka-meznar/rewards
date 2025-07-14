import 'dart:async';

import 'package:rewards/src/reward_query.dart';

/// This is where the internal status resides
final class RewardCore {
  /// The max number of reward tokens
  late int _maxRewardTokens;

  /// The current number of reward tokens
  late int _currentRewardTokens;

  /// The implemented query class for the reward tokens
  RewardQuery _rewardQuery;

  /// The controller for the current reward tokens
  final StreamController<int> _currentRewardTokensController =
      StreamController<int>.broadcast();

  /// The controller for the max reward tokens
  final StreamController<int> _maxRewardTokensController =
      StreamController<int>.broadcast();

  /// The exposed stream for the current reward tokens
  Stream<int> get currentRewardTokensStream =>
      _currentRewardTokensController.stream;

  /// The exposed stream for the max reward tokens
  Stream<int> get maxRewardTokensStream => _maxRewardTokensController.stream;

  RewardCore({
    required RewardQuery rewardQuery,
    required int maxRewardTokens,
    required int currentRewardTokens,
  }) : _maxRewardTokens = maxRewardTokens,
       _currentRewardTokens = currentRewardTokens,
       _rewardQuery = rewardQuery;

  /// Checks if the current reward tokens are enough to use the given amount
  bool canUseRewardTokens(int amount) {
    return _currentRewardTokens >= amount;
  }

  /// Sets the max number of reward tokens
  void setMaxRewardTokens(int maxRewardTokens) {
    _maxRewardTokens = maxRewardTokens;
  }

  /// Adds the given amount to the current reward tokens
  Future<void> addRewardTokens(int amount) async {
    await _rewardQuery
        .setNumberOfRewardTokensForUser(_currentRewardTokens + amount)
        .then((_) {
          _currentRewardTokens += amount;
          _currentRewardTokensController.add(_currentRewardTokens);
        });
  }

  /// Substracts the given amount from the current reward tokens
  Future<void> substractRewardTokens(int amount) async {
    await _rewardQuery
        .setNumberOfRewardTokensForUser(_currentRewardTokens - amount)
        .then((_) {
          _currentRewardTokens -= amount;
          _currentRewardTokensController.add(_currentRewardTokens);
        });
  }

  /// Queries the initial state of the reward tokens
  Future<void> queryInitialState() async {
    _currentRewardTokens = await _rewardQuery.getNumberOfRewardTokensForUser();
    final maxTokens = await _rewardQuery.getMaxNumberOfRewardTokens();
    if (maxTokens != null) {
      _maxRewardTokens = maxTokens;
    } else {
      assert(
        _maxRewardTokens != null,
        'Max number of reward tokens is not set',
      );
    }
    // Add the initial values to the streams
    resendValuesOnStreams();
  }

  void resendValuesOnStreams() {
    _currentRewardTokensController.add(_currentRewardTokens);
    _maxRewardTokensController.add(_maxRewardTokens);
  }

  void dispose() {
    _currentRewardTokensController.close();
    _maxRewardTokensController.close();
    _rewardQuery.dispose();
  }
}
