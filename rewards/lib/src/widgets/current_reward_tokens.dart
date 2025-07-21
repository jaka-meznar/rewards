import 'package:flutter/material.dart';

import 'reward_inherited.dart';

class CurrentRewardTokens extends StatelessWidget {
  const CurrentRewardTokens({super.key, required this.tokenDisplayBuilder});

  /// A builder function that provides the current reward tokens as a string.
  /// Example:
  /// ```dart
  /// CurrentRewardTokens(
  /// tokenDisplayBuilder: (numberOfRewardTokens) => Text(
  /// '$numberOfRewardTokens',
  /// style: ...
  /// ...
  /// ```
  final Widget Function(String numberOfRewardTokens) tokenDisplayBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: RewardInherited.of(context).rewardApi.currentRewardTokens,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return tokenDisplayBuilder('${snapshot.data}');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          //if the stream is waiting, but no data, we need to resend the values
          //RewardInherited.of(context).rewardApi.resendValuesOnStreams();
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
