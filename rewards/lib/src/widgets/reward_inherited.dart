import 'package:flutter/widgets.dart';
import '../reward_api.dart';
import '../reward_query.dart';

class RewardInherited extends InheritedWidget {
  final RewardApi rewardApi;

  RewardInherited({
    super.key,
    required super.child,
    required RewardQuery rewardQuery,
    int maxRewardTokens = 0,
    int currentRewardTokens = 0,
  }) : rewardApi = RewardApi(
         rewardQuery: rewardQuery,
         maxRewardTokens: maxRewardTokens,
         currentRewardTokens: currentRewardTokens,
       );

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
    // TODO: implement updateShouldNotify
    throw UnimplementedError();
  }
}
