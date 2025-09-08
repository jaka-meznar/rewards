import 'package:flutter/widgets.dart';
import '../reward_api.dart';
import '../reward_query.dart';

/// The inherited widget for the reward api. This is used to access the reward api from the widget tree.
class RewardInherited extends InheritedWidget {
  final RewardApi rewardApi;

  RewardInherited({
    super.key,
    required super.child,
    required RewardQuery rewardQuery,
    int maxRewardTokens = 0,
    int currentRewardTokens = 0,
    bool topUpRewardTokensFirstRun = false,
  }) : rewardApi = RewardApi(
         rewardQuery: rewardQuery,
         maxRewardTokens: maxRewardTokens,
         currentRewardTokens: currentRewardTokens,
       ) {
    if (topUpRewardTokensFirstRun) {
      rewardApi.topUpRewardTokensFirstRun();
    }
  }

  static RewardInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RewardInherited>();
  }

  static RewardInherited of(BuildContext context) {
    final RewardInherited? result = maybeOf(context);
    assert(result != null, 'No RewardInherited found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant RewardInherited oldWidget) {
    return oldWidget.rewardApi != rewardApi;
  }
}
