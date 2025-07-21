import 'error/reward_error.dart';
import 'reward_core.dart';
import 'reward_query.dart';

final class RewardApi {
  ///the reward core instance is created here
  final RewardCore _rewardCore;

  ///the stream for updating the UI with the current reward tokens
  //late Stream<int> currentRewardTokens;

  ///the stream for updating the UI with the max reward tokens
  //late Stream<int> maxRewardTokens;

  Stream<int> get currentRewardTokens => _rewardCore.currentRewardTokensStream;
  Stream<int> get maxRewardTokens => _rewardCore.maxRewardTokensStream;

  ///if data for maxRewardTokens and currentRewardTokens cannot be queried (ie. first open), the constructor values are used
  RewardApi({
    required RewardQuery rewardQuery,
    int maxRewardTokens = 0,
    int currentRewardTokens = 0,
  }) : _rewardCore = RewardCore(
         rewardQuery: rewardQuery,
         maxRewardTokens: maxRewardTokens,
         currentRewardTokens: currentRewardTokens,
       ) {
    // this.currentRewardTokens = _rewardCore.currentRewardTokensStream;
    // this.maxRewardTokens = _rewardCore.maxRewardTokensStream;
    // Query the initial state asynchronously
    _rewardCore.queryInitialState();
  }

  ///subtracts the given amount from the current reward tokens
  void useRewardTokens(int amount) {
    if (_rewardCore.canUseRewardTokens(amount)) {
      _rewardCore.subtractRewardTokens(amount);
    } else {
      throw NotEnoughRewardTokensError();
    }
  }

  ///adds the given amount to the current reward tokens. If the amount + current is greater than the max, the max is used.
  void addRewardTokens(int amount) {
    _rewardCore.addRewardTokens(amount);
  }

  ///queries the initial state of the reward tokens
  void queryRewardTokens() {
    _rewardCore.queryInitialState();
  }

  ///disposes the reward core
  void dispose() {
    _rewardCore.dispose();
  }

  ///resends the values on the streams (ie. if the streams are setup before the widget completes)
  void resendValuesOnStreams() {
    _rewardCore.resendValuesOnStreams();
  }

  void topUpRewardTokens() {
    _rewardCore.topUpRewardTokens();
  }
}
