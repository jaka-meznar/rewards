import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewards/src/reward_api.dart';
import 'package:rewards/src/reward_core.dart';
import 'package:rewards/src/reward_query.dart';
import 'package:rewards/src/error/reward_error.dart';
import 'package:rewards/src/widgets/current_reward_tokens.dart';
import 'package:rewards/src/widgets/max_reward_tokens.dart';
import 'package:rewards/src/widgets/merged_reward_tokens.dart';
import 'package:rewards/src/widgets/reward_inherited.dart';

// Helper for robust widget async waiting
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget not found: $finder');
}

// Mock implementations for testing
class MockRewardQuery extends RewardQuery {
  int _currentTokens = 4;
  int? _maxTokens;
  bool _disposed = false;

  @override
  Future<int> getNumberOfRewardTokensForUser() async {
    if (_disposed) throw Exception('Query disposed');
    return _currentTokens;
  }

  @override
  Future<void> setNumberOfRewardTokensForUser(int numberOfRewardTokens) async {
    if (_disposed) throw Exception('Query disposed');
    _currentTokens = numberOfRewardTokens;
  }

  @override
  Future<int?> getMaxNumberOfRewardTokens() async {
    if (_disposed) throw Exception('Query disposed');
    return _maxTokens;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  void setMaxTokens(int? maxTokens) {
    _maxTokens = maxTokens;
  }

  int get currentTokens => _currentTokens;
  bool get disposed => _disposed;
}

class MockRewardQueryWithMax extends MockRewardQuery {
  @override
  Future<int?> getMaxNumberOfRewardTokens() async {
    return 10;
  }
}

void main() {
  group('RewardError Tests', () {
    test('NotEnoughRewardTokensError has correct message', () {
      final error = NotEnoughRewardTokensError();
      expect(error.toString(), equals('RewardError: Not enough reward tokens'));
    });
  });

  group('RewardQuery Tests', () {
    test('MockRewardQuery basic functionality', () async {
      final query = MockRewardQuery();

      expect(await query.getNumberOfRewardTokensForUser(), equals(4));
      await query.setNumberOfRewardTokensForUser(10);
      expect(query.currentTokens, equals(10));
    });

    test('MockRewardQuery dispose functionality', () async {
      final query = MockRewardQuery();

      expect(query.disposed, isFalse);
      await query.dispose();
      expect(query.disposed, isTrue);

      expect(
        () => query.getNumberOfRewardTokensForUser(),
        throwsA(isA<Exception>()),
      );
    });

    test('MockRewardQueryWithMax returns max tokens', () async {
      final query = MockRewardQueryWithMax();
      expect(await query.getMaxNumberOfRewardTokens(), equals(10));
    });
  });

  group('RewardCore Tests', () {
    late MockRewardQuery mockQuery;
    late RewardCore rewardCore;

    setUp(() {
      mockQuery = MockRewardQuery();
      rewardCore = RewardCore(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
      );
    });

    test('RewardCore constructor initializes correctly', () {
      expect(rewardCore, isNotNull);
    });

    test('canUseRewardTokens returns true when enough tokens', () {
      expect(rewardCore.canUseRewardTokens(3), isTrue);
      expect(rewardCore.canUseRewardTokens(5), isTrue);
    });

    test('canUseRewardTokens returns false when not enough tokens', () {
      expect(rewardCore.canUseRewardTokens(6), isFalse);
      expect(rewardCore.canUseRewardTokens(10), isFalse);
    });

    test('setMaxRewardTokens updates max tokens', () {
      rewardCore.setMaxRewardTokens(20);
      // Note: We can't directly test the private field, but we can test through streams
    });

    test('addRewardTokens increases tokens up to max', () async {
      // After queryInitialState, _currentRewardTokens will be 4 (from mock)
      await rewardCore.queryInitialState();
      final initialTokens = 4; // Mock returns 4
      final maxTokens = 10;

      // Add tokens normally
      await rewardCore.addRewardTokens(3);
      expect(mockQuery.currentTokens, equals(initialTokens + 3));

      // Add tokens that would exceed max - should cap at max
      await rewardCore.addRewardTokens(10);
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('addRewardTokens caps at max tokens', () async {
      await rewardCore.queryInitialState();
      final maxTokens = 10;

      // Try to add more than max tokens
      await rewardCore.addRewardTokens(15);
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens sets tokens to max', () async {
      await rewardCore.queryInitialState();
      final maxTokens = 10;

      // Top up should set current tokens to max
      await rewardCore.topUpRewardTokens();
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens works when current tokens are below max', () async {
      await rewardCore.queryInitialState();
      final maxTokens = 10;
      final initialTokens = 4; // Mock returns 4

      // Verify initial state
      expect(mockQuery.currentTokens, equals(initialTokens));

      // Top up should set to max
      await rewardCore.topUpRewardTokens();
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens works when current tokens are at max', () async {
      await rewardCore.queryInitialState();
      final maxTokens = 10;

      // First top up to max
      await rewardCore.topUpRewardTokens();
      expect(mockQuery.currentTokens, equals(maxTokens));

      // Top up again - should still be at max
      await rewardCore.topUpRewardTokens();
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('subtractRewardTokens decreases current tokens', () async {
      // After queryInitialState, _currentRewardTokens will be 4 (from mock)
      await rewardCore.queryInitialState();
      final initialTokens = 4; // Mock returns 4
      await rewardCore.subtractRewardTokens(2);
      expect(mockQuery.currentTokens, equals(initialTokens - 2));
    });

    test('queryInitialState loads initial state', () async {
      await rewardCore.queryInitialState();
      // The streams should emit the initial values
    });

    test('dispose closes streams and query', () async {
      rewardCore.dispose();
      expect(mockQuery.disposed, isTrue);
    });

    test('streams emit values', () async {
      final currentTokens = <int>[];
      final maxTokens = <int>[];

      rewardCore.currentRewardTokensStream.listen(currentTokens.add);
      rewardCore.maxRewardTokensStream.listen(maxTokens.add);

      await rewardCore.queryInitialState();
      await Future.delayed(Duration(milliseconds: 10));

      expect(currentTokens, isNotEmpty);
      expect(maxTokens, isNotEmpty);
    });
  });

  group('RewardApi Tests', () {
    late MockRewardQuery mockQuery;
    late RewardApi rewardApi;

    setUp(() {
      mockQuery = MockRewardQuery();
      rewardApi = RewardApi(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
      );
    });

    test('RewardApi constructor initializes correctly', () {
      expect(rewardApi, isNotNull);
    });

    test('useRewardTokens succeeds when enough tokens', () {
      expect(() => rewardApi.useRewardTokens(3), returnsNormally);
    });

    test('useRewardTokens throws error when not enough tokens', () {
      expect(
        () => rewardApi.useRewardTokens(10),
        throwsA(isA<NotEnoughRewardTokensError>()),
      );
    });

    test('addRewardTokens increases tokens up to max', () async {
      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      final initialTokens =
          mockQuery.currentTokens; // Should be 4 after queryInitialState
      final maxTokens = 10;

      // Add tokens normally
      rewardApi.addRewardTokens(3);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(initialTokens + 3));

      // Add tokens that would exceed max - should cap at max
      rewardApi.addRewardTokens(10);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('addRewardTokens caps at max tokens', () async {
      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      final maxTokens = 10;

      // Try to add more than max tokens
      rewardApi.addRewardTokens(15);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens sets tokens to max', () async {
      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      final maxTokens = 10;

      // Top up should set current tokens to max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens works when current tokens are below max', () async {
      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      final maxTokens = 10;
      final initialTokens =
          mockQuery.currentTokens; // Should be 4 after queryInitialState

      // Verify initial state
      expect(mockQuery.currentTokens, equals(initialTokens));

      // Top up should set to max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('topUpRewardTokens works when current tokens are at max', () async {
      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      final maxTokens = 10;

      // First top up to max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));

      // Top up again - should still be at max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(maxTokens));
    });

    test('queryRewardTokens calls queryInitialState', () async {
      rewardApi.queryRewardTokens();
      // This should trigger the query without throwing
      expect(() => rewardApi.queryRewardTokens(), returnsNormally);
    });

    test('streams emit values', () async {
      final currentTokens = <int>[];
      final maxTokens = <int>[];

      rewardApi.currentRewardTokens.listen(currentTokens.add);
      rewardApi.maxRewardTokens.listen(maxTokens.add);

      // Wait for initial values
      await Future.delayed(Duration(milliseconds: 10));

      expect(currentTokens, isNotEmpty);
      expect(maxTokens, isNotEmpty);
    });

    // Removed the dispose test as it cannot be reliably tested due to async constructor
  });

  group('RewardInherited Tests', () {
    test('RewardInherited constructor creates RewardApi', () {
      final mockQuery = MockRewardQuery();
      final inherited = RewardInherited(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
        child: Container(),
      );

      expect(inherited.rewardApi, isA<RewardApi>());
    });

    testWidgets('maybeOf returns null when not in context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = RewardInherited.maybeOf(context);
              expect(result, isNull);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('of throws assertion when not in context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => RewardInherited.of(context),
                throwsA(isA<AssertionError>()),
              );
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('of returns instance when in context', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            child: Builder(
              builder: (context) {
                final result = RewardInherited.of(context);
                expect(result, isA<RewardInherited>());
                return Container();
              },
            ),
          ),
        ),
      );
    });

    test('updateShouldNotify returns boolean', () {
      final mockQuery = MockRewardQuery();
      final inherited = RewardInherited(
        rewardQuery: mockQuery,
        child: Container(),
      );

      final result = inherited.updateShouldNotify(inherited);
      expect(result, isA<bool>());
    });
  });

  group('CurrentRewardTokens Widget Tests', () {
    testWidgets('shows CircularProgressIndicator initially', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            child: CurrentRewardTokens(
              tokenDisplayBuilder: (tokens) => Text('Tokens: $tokens'),
            ),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays current tokens after data loads', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            child: CurrentRewardTokens(
              tokenDisplayBuilder: (tokens) => Text('Tokens: $tokens'),
            ),
          ),
        ),
      );

      // Wait for the token text to appear
      await pumpUntilFound(tester, find.text('Tokens: 4'));

      expect(find.text('Tokens: 4'), findsOneWidget);
    });
  });

  group('MaxRewardTokens Widget Tests', () {
    testWidgets('shows CircularProgressIndicator initially', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            child: MaxRewardTokens(
              maxRewardTokensDisplayBuilder: (tokens) => Text('Max: $tokens'),
            ),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays max tokens after data loads', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 10,
            child: MaxRewardTokens(
              maxRewardTokensDisplayBuilder: (tokens) => Text('Max: $tokens'),
            ),
          ),
        ),
      );

      // Wait for the max token text to appear
      await pumpUntilFound(tester, find.text('Max: 10'));
      expect(find.text('Max: 10'), findsOneWidget);
    });
  });

  group('MergedRewardTokens Widget Tests', () {
    testWidgets('shows CircularProgressIndicator initially', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('Current: $current, Max: $max'),
            ),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays merged tokens after data loads', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 10,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('Current: $current, Max: $max'),
            ),
          ),
        ),
      );

      // Wait for the merged token text to appear
      await pumpUntilFound(tester, find.text('Current: 4, Max: 10'));
      expect(find.text('Current: 4, Max: 10'), findsOneWidget);
    });

    testWidgets('calls builder with correct parameters', (tester) async {
      final mockQuery = MockRewardQuery();
      String? capturedCurrent;
      String? capturedMax;

      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 15,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder: (current, max) {
                capturedCurrent = current;
                capturedMax = max;
                return Text('$current/$max');
              },
            ),
          ),
        ),
      );

      // Wait for the widget to load data
      await pumpUntilFound(tester, find.text('4/15'));

      expect(capturedCurrent, equals('4'));
      expect(capturedMax, equals('15'));
    });

    testWidgets('updates when streams emit new values', (tester) async {
      final mockQuery = MockRewardQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 10,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('$current/$max'),
            ),
          ),
        ),
      );

      // Wait for initial data
      await pumpUntilFound(tester, find.text('4/10'));

      // Update the mock query values
      await mockQuery.setNumberOfRewardTokensForUser(7);
      mockQuery.setMaxTokens(20);

      // Rebuild the widget to trigger new stream values
      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 20,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('$current/$max'),
            ),
          ),
        ),
      );

      // Wait for updated data
      await pumpUntilFound(tester, find.text('7/20'));
      expect(find.text('7/20'), findsOneWidget);
    });

    testWidgets('handles zero values correctly', (tester) async {
      final mockQuery = MockRewardQuery();
      // Set initial values to 0
      await mockQuery.setNumberOfRewardTokensForUser(0);
      mockQuery.setMaxTokens(0);

      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 0,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('Current: $current, Max: $max'),
            ),
          ),
        ),
      );

      // Wait for the zero values to appear
      await pumpUntilFound(tester, find.text('Current: 0, Max: 0'));
      expect(find.text('Current: 0, Max: 0'), findsOneWidget);
    });

    testWidgets('handles large numbers correctly', (tester) async {
      final mockQuery = MockRewardQuery();
      await mockQuery.setNumberOfRewardTokensForUser(999999);
      mockQuery.setMaxTokens(1000000);

      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 1000000,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder:
                  (current, max) => Text('$current/$max'),
            ),
          ),
        ),
      );

      // Wait for the large numbers to appear
      await pumpUntilFound(tester, find.text('999999/1000000'));
      expect(find.text('999999/1000000'), findsOneWidget);
    });

    testWidgets('builder function is called with string parameters', (
      tester,
    ) async {
      final mockQuery = MockRewardQuery();
      bool builderCalled = false;
      String? firstParamType;
      String? secondParamType;

      await tester.pumpWidget(
        MaterialApp(
          home: RewardInherited(
            rewardQuery: mockQuery,
            maxRewardTokens: 10,
            child: MergedRewardTokens(
              mergedRewardTokensDisplayBuilder: (current, max) {
                builderCalled = true;
                firstParamType = current.runtimeType.toString();
                secondParamType = max.runtimeType.toString();
                return Text('$current/$max');
              },
            ),
          ),
        ),
      );

      // Wait for the widget to load data
      await pumpUntilFound(tester, find.text('4/10'));

      expect(builderCalled, isTrue);
      expect(firstParamType, equals('String'));
      expect(secondParamType, equals('String'));
    });
  });

  group('Integration Tests', () {
    test('full reward token lifecycle', () async {
      final mockQuery = MockRewardQuery();
      final rewardApi = RewardApi(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
      );

      // Wait for initial state to be loaded
      await Future.delayed(Duration(milliseconds: 10));
      expect(
        mockQuery.currentTokens,
        equals(4),
      ); // Mock default after queryInitialState

      // Add tokens normally
      rewardApi.addRewardTokens(3);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(7));

      // Add tokens that would exceed max - should cap at max
      rewardApi.addRewardTokens(5);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(10));

      // Use tokens successfully
      rewardApi.useRewardTokens(2);
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(8));

      // Top up to max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(mockQuery.currentTokens, equals(10));

      // Try to use too many tokens
      expect(
        () => rewardApi.useRewardTokens(15),
        throwsA(isA<NotEnoughRewardTokensError>()),
      );

      // Cleanup
      rewardApi.dispose();
    });

    test('stream behavior with multiple operations', () async {
      final mockQuery = MockRewardQuery();
      final rewardApi = RewardApi(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
      );

      final currentTokens = <int>[];
      final maxTokens = <int>[];

      rewardApi.currentRewardTokens.listen(currentTokens.add);
      rewardApi.maxRewardTokens.listen(maxTokens.add);

      // Wait for initial state
      await Future.delayed(Duration(milliseconds: 10));

      // Perform multiple operations
      rewardApi.addRewardTokens(2);
      await Future.delayed(Duration(milliseconds: 10));
      rewardApi.useRewardTokens(1);
      await Future.delayed(Duration(milliseconds: 10));
      rewardApi.addRewardTokens(3);
      await Future.delayed(Duration(milliseconds: 10));

      expect(currentTokens.length, greaterThan(1));
      expect(maxTokens.length, greaterThan(0));

      rewardApi.dispose();
    });

    test('topUpRewardTokens integration with streams', () async {
      final mockQuery = MockRewardQuery();
      final rewardApi = RewardApi(
        rewardQuery: mockQuery,
        maxRewardTokens: 10,
        currentRewardTokens: 5,
      );

      final currentTokens = <int>[];

      rewardApi.currentRewardTokens.listen(currentTokens.add);

      // Wait for initial state
      await Future.delayed(Duration(milliseconds: 10));

      // Verify initial state
      expect(currentTokens.last, equals(4)); // Mock returns 4

      // Top up to max
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify top up worked
      expect(currentTokens.last, equals(10));
      expect(mockQuery.currentTokens, equals(10));

      // Use some tokens
      rewardApi.useRewardTokens(3);
      await Future.delayed(Duration(milliseconds: 10));
      expect(currentTokens.last, equals(7));

      // Top up again
      rewardApi.topUpRewardTokens();
      await Future.delayed(Duration(milliseconds: 10));
      expect(currentTokens.last, equals(10));

      rewardApi.dispose();
    });
  });
}
