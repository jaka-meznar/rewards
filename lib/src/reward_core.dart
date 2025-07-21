import 'dart:async';

import 'package:rewards/src/reward_query.dart';

//TODO: there can be a state stream, which indicates that the reward tokens are being updated, and the stream can be used to show a loading indicator

/// This is where the internal status resides
final class RewardCore {
  /// The max number of reward tokens
  late int _maxRewardTokens;

  /// The current number of reward tokens
  late int _currentRewardTokens;

  /// The implemented query class for the reward tokens
  final RewardQuery _rewardQuery;

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

  /// The constructor for the reward core. The max and current reward tokens values can be set here if they cannot be queried from the query class.
  RewardCore({
    required RewardQuery rewardQuery,
    required int maxRewardTokens,
    required int currentRewardTokens,
  }) : _maxRewardTokens = maxRewardTokens,
       _currentRewardTokens = currentRewardTokens,
       _rewardQuery = rewardQuery {
    //adds the current values to the streams immediately
    _currentRewardTokensController.onListen = () {
      print("listening for current reward tokens");
      _currentRewardTokensController.add(_currentRewardTokens);
    };
    _maxRewardTokensController.onListen = () {
      print("listening for max reward tokens");
      _maxRewardTokensController.add(_maxRewardTokens);
    };
  }

  /// Checks if the current reward tokens are enough to use the given amount
  bool canUseRewardTokens(int amount) {
    return _currentRewardTokens >= amount;
  }

  /// Sets the max number of reward tokens
  void setMaxRewardTokens(int maxRewardTokens) {
    _maxRewardTokens = maxRewardTokens;
  }

  /// Adds the given amount to the current reward tokens
  Future<void> topUpRewardTokens() async {
    await _rewardQuery
        .setNumberOfRewardTokensForUser(_maxRewardTokens)
        .then(
          (_) {
            _currentRewardTokens = _maxRewardTokens;
            _currentRewardTokensController.add(_currentRewardTokens);
          },
          onError: (error, stackTrace) {
            _currentRewardTokensController.addError(error);
          },
        );
  }

  /// Adds the given amount to the current reward tokens
  Future<void> addRewardTokens(int amount) async {
    //fixes to the max amount
    var calculatedAmount = amount + _currentRewardTokens;
    if (calculatedAmount > _maxRewardTokens) {
      calculatedAmount = _maxRewardTokens;
    }
    await _rewardQuery
        .setNumberOfRewardTokensForUser(calculatedAmount)
        .then(
          (_) {
            _currentRewardTokens = calculatedAmount;
            _currentRewardTokensController.add(_currentRewardTokens);
          },
          onError: (error, stackTrace) {
            _currentRewardTokensController.addError(error);
          },
        );
  }

  /// Subtracts the given amount from the current reward tokens
  Future<void> subtractRewardTokens(int amount) async {
    await _rewardQuery
        .setNumberOfRewardTokensForUser(_currentRewardTokens - amount)
        .then(
          (_) {
            _currentRewardTokens -= amount;
            _currentRewardTokensController.add(_currentRewardTokens);
          },
          onError: (error, stackTrace) {
            _currentRewardTokensController.addError(error);
          },
        );
  }

  /// Queries the initial state of the reward tokens
  Future<void> queryInitialState() async {
    try {
      final value = await _rewardQuery.getNumberOfRewardTokensForUser();
      if (value != null) {
        _currentRewardTokens = value;
      }
      //else, reward tokens could not be queried, so we leave them as they were set in the constructor
    } catch (error) {
      _currentRewardTokensController.addError(error);
    }

    try {
      final maxTokens = await _rewardQuery.getMaxNumberOfRewardTokens();
      if (maxTokens != null) {
        _maxRewardTokens = maxTokens;
      }
      //else, max number of reward tokens could not be queried, so we leave them as they were set in the constructor
    } catch (error) {
      _maxRewardTokensController.addError(error);
    }

    // Add the initial values to the streams
    resendValuesOnStreams();
  }

  /// Resends the values on the streams (ie. if the streams are setup before the widget completes)
  void resendValuesOnStreams() {
    _currentRewardTokensController.add(_currentRewardTokens);
    _maxRewardTokensController.add(_maxRewardTokens);
  }

  /// Disposes the reward core and query
  void dispose() {
    _currentRewardTokensController.close();
    _maxRewardTokensController.close();
    _rewardQuery.dispose();
  }
}
