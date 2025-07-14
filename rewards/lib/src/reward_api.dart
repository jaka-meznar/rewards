import 'error/reward_error.dart';
import 'reward_core.dart';
import 'reward_query.dart';

class RewardApi {
  final RewardCore _rewardCore;
  late Stream<int> currentRewardTokens;
  late Stream<int> maxRewardTokens;

  RewardApi({
    required RewardQuery rewardQuery,
    int maxRewardTokens = 0,
    int currentRewardTokens = 0,
  }) : _rewardCore = RewardCore(
         rewardQuery: rewardQuery,
         maxRewardTokens: maxRewardTokens,
         currentRewardTokens: currentRewardTokens,
       ) {
    //TODO: watch if distinct would fuckup the first value
    this.currentRewardTokens = _rewardCore.currentRewardTokensStream.distinct();
    this.maxRewardTokens = _rewardCore.maxRewardTokensStream.distinct();
    _rewardCore.queryInitialState();
  }

  void useRewardTokens(int amount) {
    if (_rewardCore.canUseRewardTokens(amount)) {
      _rewardCore.substractRewardTokens(amount);
    } else {
      throw NotEnoughRewardTokensError();
    }
  }

  void addRewardTokens(int amount) {
    _rewardCore.addRewardTokens(amount);
  }

  void queryRewardTokens() {
    _rewardCore.queryInitialState();
  }

  void dispose() {
    _rewardCore.dispose();
  }
}
