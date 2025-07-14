import 'package:flutter/material.dart';

import 'reward_inherited.dart';

class MaxRewardTokens extends StatelessWidget {
  const MaxRewardTokens({
    super.key,
    required this.maxRewardTokensDisplayBuilder,
  });

  /// A builder function that provides the max reward tokens as a string.
  /// Example:
  /// ```dart
  /// MaxRewardTokens(
  /// tokenDisplayBuilder: (numberOfMaxRewardTokens) => Text(
  /// '$numberOfMaxRewardTokens',
  /// style: ...
  /// ...
  /// ```
  final Widget Function(String numberOfMaxRewardTokens)
  maxRewardTokensDisplayBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: RewardInherited.of(context).rewardApi.maxRewardTokens,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return maxRewardTokensDisplayBuilder('${snapshot.data}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
