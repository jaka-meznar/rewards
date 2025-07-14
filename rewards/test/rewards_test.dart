import 'package:flutter_test/flutter_test.dart';
import 'package:rewards/src/reward_api.dart';
import 'package:rewards/src/reward_query.dart';

class MockRewardQuery extends RewardQuery {
  @override
  Future<int> getNumberOfRewardTokensForUser() {
    return Future.value(4);
  }

  @override
  Future<void> setNumberOfRewardTokensForUser(int numberOfRewardTokens) {
    return Future.value();
  }
}

void main() {
  test('Creation of RewardApi', () {
    final rewardApi = RewardApi(
      rewardQuery: MockRewardQuery(),
      maxRewardTokens: 10,
    );
    expect(rewardApi, isNotNull);
    expect(rewardApi.maxRewardTokens, emits(10));
    expect(rewardApi.currentRewardTokens, emits(4));
  });
}
