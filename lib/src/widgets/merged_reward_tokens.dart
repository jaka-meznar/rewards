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
      stream: _combineLatest(
        RewardInherited.of(context).rewardApi.currentRewardTokens,
        RewardInherited.of(context).rewardApi.maxRewardTokens,
      ),
      // stream: StreamZip([
      //   RewardInherited.of(context).rewardApi.currentRewardTokens,
      //   RewardInherited.of(context).rewardApi.maxRewardTokens,
      // ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return mergedRewardTokensDisplayBuilder(
            '${snapshot.data![0]}', // current tokens
            '${snapshot.data![1]}', // max tokens
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          //if the stream is waiting, but no data, we need to resend the values
          RewardInherited.of(context).rewardApi.resendValuesOnStreams();
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Stream<List<int>> _combineLatest(Stream<int> stream1, Stream<int> stream2) {
    return StreamGroup.merge([stream1, stream2]).asyncMap((_) async {
      // Get the latest values from both streams
      final currentTokens = await stream1.last;
      final maxTokens = await stream2.last;
      return [currentTokens, maxTokens];
    }).asBroadcastStream();
  }
}
