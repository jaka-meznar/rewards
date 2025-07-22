import 'package:async/async.dart';
import 'package:flutter/material.dart';

import 'reward_inherited.dart';

class MergedRewardTokens extends StatefulWidget {
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
  State<MergedRewardTokens> createState() => _MergedRewardTokensState();
}

class _MergedRewardTokensState extends State<MergedRewardTokens> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: StreamZip([
        RewardInherited.of(context).rewardApi.currentRewardTokens,
        RewardInherited.of(context).rewardApi.maxRewardTokens,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return widget.mergedRewardTokensDisplayBuilder(
            '${snapshot.data![0]}', // current tokens
            '${snapshot.data![1]}', // max tokens
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
