import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise_ai/features/calculator/domain/entities/affordability_result.dart';

void main() {
  group('AffordabilityResult.fromJson', () {
    test('parses minimal response without crashing', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'SAFE_TO_BUY',
        'reason': 'You can afford this.',
      });

      expect(result.verdict, 'SAFE_TO_BUY');
      expect(result.reason, 'You can afford this.');
      expect(result.goalImpacts, isEmpty);
      expect(result.scenarios, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.recommendations, isEmpty);
      expect(result.strengthEvidence, isEmpty);
      expect(result.confidence, 0);
      expect(result.recommendationStrength, RecommendationStrength.low);
    });

    test('parses all verdict types correctly', () {
      for (final v in ['SAFE_TO_BUY', 'WAIT_AND_SAVE', 'DONT_BUY']) {
        final result = AffordabilityResult.fromJson({'verdict': v, 'reason': ''});
        expect(result.verdict, v);
      }
    });

    test('parses recommendation strength', () {
      final high = AffordabilityResult.fromJson({
        'verdict': 'SAFE_TO_BUY',
        'reason': '',
        'recommendationStrength': 'HIGH',
      });
      expect(high.recommendationStrength, RecommendationStrength.high);

      final medium = AffordabilityResult.fromJson({
        'verdict': 'WAIT_AND_SAVE',
        'reason': '',
        'recommendationStrength': 'MEDIUM',
      });
      expect(medium.recommendationStrength, RecommendationStrength.medium);

      final low = AffordabilityResult.fromJson({
        'verdict': 'DONT_BUY',
        'reason': '',
        'recommendationStrength': 'LOW',
      });
      expect(low.recommendationStrength, RecommendationStrength.low);
    });

    test('parses numeric fields correctly', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'SAFE_TO_BUY',
        'reason': '',
        'monthlyEmi': 5000,
        'dtiRatio': 32.5,
        'remainingMonthlySurplus': 12000,
        'maxAffordablePrice': 500000,
        'confidence': 87,
      });

      expect(result.monthlyEmi, 5000.0);
      expect(result.dtiRatio, 32.5);
      expect(result.remainingMonthlySurplus, 12000.0);
      expect(result.maxAffordablePrice, 500000.0);
      expect(result.confidence, 87);
    });

    test('parses goal impacts from list response', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'WAIT_AND_SAVE',
        'reason': 'Emergency fund too low.',
        'goalImpacts': [
          {
            'goalName': 'Home',
            'goalType': 'home',
            'currentProgressPct': 45.0,
            'projectedProgressPct': 38.0,
            'monthsDelayed': 4,
            'statusChange': 'DELAYED',
          }
        ],
      });

      expect(result.goalImpacts, hasLength(1));
      final impact = result.goalImpacts.first;
      expect(impact.goalName, 'Home');
      expect(impact.goalType, 'home');
      expect(impact.currentProgressPct, 45.0);
      expect(impact.projectedProgressPct, 38.0);
      expect(impact.monthsDelayed, 4);
      expect(impact.statusChange, 'DELAYED');
    });

    test('parses scenario list with tradeoffs', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'SAFE_TO_BUY',
        'reason': '',
        'scenarios': [
          {
            'label': 'Cash Purchase',
            'verdict': 'SAFE_TO_BUY',
            'confidence': 90,
            'recommendationStrength': 'HIGH',
            'summary': 'Pay outright.',
            'isRecommended': true,
            'tradeoffs': [
              {'type': 'PRO', 'description': 'No interest cost'},
              {'type': 'CON', 'description': 'Depletes savings'},
            ],
          }
        ],
      });

      expect(result.scenarios, hasLength(1));
      final s = result.scenarios.first;
      expect(s.label, 'Cash Purchase');
      expect(s.isRecommended, true);
      expect(s.tradeoffs, hasLength(2));
      expect(s.tradeoffs.first.type, TradeoffType.pro);
      expect(s.tradeoffs.last.type, TradeoffType.con);
    });

    test('handles null optional fields gracefully', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'DONT_BUY',
        'reason': 'Cannot afford.',
        'monthlyEmi': null,
        'dtiRatio': null,
        'maxAffordablePrice': null,
      });

      expect(result.monthlyEmi, isNull);
      expect(result.dtiRatio, isNull);
      expect(result.maxAffordablePrice, isNull);
    });

    test('parses reasons, warnings, recommendations as string lists', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'WAIT_AND_SAVE',
        'reason': '',
        'reasons': ['Emergency fund below 6 months'],
        'warnings': ['DTI will exceed 40%'],
        'recommendations': ['Save ₹5,000/month for 3 months first'],
      });

      expect(result.reasons, ['Emergency fund below 6 months']);
      expect(result.warnings, ['DTI will exceed 40%']);
      expect(result.recommendations, ['Save ₹5,000/month for 3 months first']);
    });

    test('parses date as string format', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'WAIT_AND_SAVE',
        'reason': '',
        'expectedPurchaseDate': '2026-11-01',
      });

      expect(result.expectedPurchaseDate, DateTime(2026, 11, 1));
    });

    test('parses date as [year, month, day] array format', () {
      final result = AffordabilityResult.fromJson({
        'verdict': 'WAIT_AND_SAVE',
        'reason': '',
        'expectedPurchaseDate': [2026, 11, 1],
      });

      expect(result.expectedPurchaseDate, DateTime(2026, 11, 1));
    });
  });

  group('GoalImpact.fromJson', () {
    test('defaults missing optional fields', () {
      final impact = GoalImpact.fromJson({
        'goalName': 'Emergency Fund',
        'goalType': 'emergency_fund',
        'currentProgressPct': 50,
        'projectedProgressPct': 50,
      });

      expect(impact.monthsDelayed, 0);
      expect(impact.statusChange, 'UNAFFECTED');
      expect(impact.monthsToTargetNow, isNull);
      expect(impact.monthsToTargetAfter, isNull);
    });
  });

  group('RecommendationStrengthX.parse', () {
    test('is case-insensitive', () {
      expect(RecommendationStrengthX.parse('high'), RecommendationStrength.high);
      expect(RecommendationStrengthX.parse('HIGH'), RecommendationStrength.high);
      expect(RecommendationStrengthX.parse('Medium'), RecommendationStrength.medium);
      expect(RecommendationStrengthX.parse(null), RecommendationStrength.low);
      expect(RecommendationStrengthX.parse('unknown'), RecommendationStrength.low);
    });
  });
}
