import 'package:async/async.dart';
import 'package:flutter/material.dart';

import 'reward_inherited.dart';

class MergedRewardTokens extends StatelessWidget {
  const MergedRewardTokens({
    super.key,
    required this.mergedRewardTokensDisplayBuilder,
  });

  final Widget Function(
    String numberOfRewardTokens,
    String numberOfMaxRewardTokens,
  )
  mergedRewardTokensDisplayBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: StreamZip([
        RewardInherited.of(context).rewardApi.currentRewardTokens,
        RewardInherited.of(context).rewardApi.maxRewardTokens,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData || snapshot.requireData.isNotEmpty) {
          return mergedRewardTokensDisplayBuilder(
            '${snapshot.data?[0] ?? snapshot.requireData[0]}', // current tokens
            '${snapshot.data?[1] ?? snapshot.requireData[1]}', // max tokens
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
