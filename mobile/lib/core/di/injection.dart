import 'package:get_it/get_it.dart';

import '../../application/decision/get_dashboard_feed_use_case.dart';
import '../../application/decision/get_today_decision_use_case.dart';
import '../../application/decision/record_decision_lifecycle_use_case.dart';
import '../../application/finance/get_financial_age_use_case.dart';
import '../../application/finance/get_health_score_use_case.dart';
import '../../application/finance/get_momentum_use_case.dart';
import '../../application/finance/get_resilience_index_use_case.dart';
import '../../application/ingestion/ingest_transactions_use_case.dart';
import '../../application/learning/evaluate_outcome_use_case.dart';
import '../../application/learning/get_learning_insights_use_case.dart';
import '../../application/learning/record_execution_use_case.dart';
import '../../application/partner/get_partner_programs_use_case.dart';
import '../../domain/engines/decision_learning_engine.dart';
import '../../domain/engines/duplicate_detector.dart';
import '../../domain/engines/evidence_builder.dart';
import '../../domain/engines/financial_age_engine.dart';
import '../../domain/engines/health_score_engine.dart';
import '../../domain/engines/merchant_resolver.dart';
import '../../domain/engines/momentum_engine.dart';
import '../../domain/engines/partner_matching_engine.dart';
import '../../domain/engines/product_knowledge_graph.dart';
import '../../domain/engines/resilience_engine.dart';
import '../../domain/engines/event_replay_engine.dart';
import '../../domain/engines/sms_parser_registry.dart';
import '../../domain/engines/sms_validation_engine.dart';
import '../../domain/engines/transaction_normalizer.dart';
import '../../domain/ingestion/merchant_learning_entry.dart';
import '../../domain/partner/product_catalog.dart';
import '../../infrastructure/engines/hardcoded_merchant_resolver.dart';
import '../../infrastructure/engines/hardcoded_product_knowledge_graph.dart';
import '../../infrastructure/engines/rule_based_decision_learning_engine.dart';
import '../../infrastructure/engines/rule_based_duplicate_detector.dart';
import '../../infrastructure/engines/rule_based_financial_age_engine.dart';
import '../../infrastructure/engines/rule_based_health_score_engine.dart';
import '../../infrastructure/engines/rule_based_momentum_engine.dart';
import '../../infrastructure/engines/rule_based_partner_matching_engine.dart';
import '../../infrastructure/engines/rule_based_resilience_engine.dart';
import '../../infrastructure/engines/rule_based_transaction_normalizer.dart';
import '../../infrastructure/engines/stub_event_replay_engine.dart';
import '../../infrastructure/engines/stub_evidence_builder.dart';
import '../../infrastructure/ingestion/sms/registry/sms_parser_registry_impl.dart';
import '../../infrastructure/ingestion/sms/validators/sms_validation_engine_impl.dart';
import '../../infrastructure/mappers/decision_mapper.dart';
import '../../infrastructure/mappers/partner_mapper.dart';
import '../../infrastructure/repositories/hardcoded_partner_repository.dart';
import '../../infrastructure/repositories/hardcoded_product_catalog.dart';
import '../../infrastructure/repositories/rest_decision_repository.dart';
import '../../infrastructure/services/partner_asset_service.dart';
import '../../domain/partner/policies/emergency_fund_policy.dart';
import '../../domain/partner/policies/wealth_creation_policy.dart';
import '../../domain/partner/policies/tax_saving_policy.dart';
import '../../domain/partner/policies/retirement_policy.dart';
import '../../domain/partner/policies/insurance_policy.dart';
import '../../domain/partner/policies/debt_reduction_policy.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Services — initialized eagerly so manifest is ready before first render
  await PartnerAssetService.instance.initialize();

  // Mappers
  sl.registerLazySingleton<PartnerMapper>(() => const PartnerMapper());
  sl.registerLazySingleton<DecisionMapper>(
    () => DecisionMapper(sl<PartnerMapper>()),
  );

  // Financial Identity Resolution — merchant alias → canonical profile
  sl.registerLazySingleton<MerchantResolver>(
    () => const HardcodedMerchantResolver(),
  );

  // Transaction Normalizer — raw event → TransactionCandidate
  sl.registerLazySingleton<TransactionNormalizer>(
    () => RuleBasedTransactionNormalizer(sl<MerchantResolver>()),
  );

  // Duplicate Detector — dedup and reconcile across sources
  sl.registerLazySingleton<DuplicateDetector>(
    () => const RuleBasedDuplicateDetector(),
  );

  // Knowledge Graph — instrument domain knowledge (hardcoded today, DB-backed in Phase 6)
  sl.registerLazySingleton<ProductKnowledgeGraph>(
    () => const HardcodedProductKnowledgeGraph(),
  );

  // Evidence Builder — assembles EvidenceItems from all data sources
  sl.registerLazySingleton<EvidenceBuilder>(
    () => const StubEvidenceBuilder(),
  );

  // Health Score Engine — 10-dimension financial health computation
  sl.registerLazySingleton<HealthScoreEngine>(
    () => const RuleBasedHealthScoreEngine(),
  );

  // Decision Learning Engine — closes the 8-step Decision Learning Loop
  sl.registerLazySingleton<DecisionLearningEngine>(
    () => const RuleBasedDecisionLearningEngine(),
  );

  // Financial Age Engine — chronological vs behavioral financial age
  sl.registerLazySingleton<FinancialAgeEngine>(
    () => const RuleBasedFinancialAgeEngine(),
  );

  // Resilience Engine — shock absorption capacity (distinct from health score)
  sl.registerLazySingleton<ResilienceEngine>(
    () => const RuleBasedResilienceEngine(),
  );

  // Momentum Engine — health score trajectory from snapshots
  sl.registerLazySingleton<MomentumEngine>(
    () => const RuleBasedMomentumEngine(),
  );

  // Product catalog — pure data, no user context
  sl.registerLazySingleton<ProductCatalog>(
    () => const HardcodedProductCatalog(),
  );

  // Partner Matching Engine — policy-based, reasoning-first
  sl.registerLazySingleton<PartnerMatchingEngine>(
    () => RuleBasedPartnerMatchingEngine(const [
      EmergencyFundPolicy(),
      WealthCreationPolicy(),
      TaxSavingPolicy(),
      RetirementPolicy(),
      InsurancePolicy(),
      DebtReductionPolicy(),
    ]),
  );

  // Repositories (concrete implementations behind domain interfaces)
  sl.registerLazySingleton<HardcodedPartnerRepository>(
    () => HardcodedPartnerRepository(
      catalog: sl<ProductCatalog>(),
      engine: sl<PartnerMatchingEngine>(),
    ),
  );
  sl.registerLazySingleton<RestDecisionRepository>(
    () => RestDecisionRepository(sl<DecisionMapper>()),
  );

  // Use cases — Decision
  sl.registerLazySingleton<GetTodayDecisionUseCase>(
    () => GetTodayDecisionUseCase(sl<RestDecisionRepository>()),
  );
  sl.registerLazySingleton<RecordDecisionLifecycleUseCase>(
    () => RecordDecisionLifecycleUseCase(sl<RestDecisionRepository>()),
  );
  sl.registerLazySingleton<GetDashboardFeedUseCase>(
    () => GetDashboardFeedUseCase(
      sl<RestDecisionRepository>(),
      sl<HardcodedPartnerRepository>(),
    ),
  );

  // Use cases — Partner
  sl.registerLazySingleton<GetPartnerProgramsUseCase>(
    () => GetPartnerProgramsUseCase(sl<HardcodedPartnerRepository>()),
  );

  // Use cases — Finance
  sl.registerLazySingleton<GetHealthScoreUseCase>(
    () => GetHealthScoreUseCase(sl<HealthScoreEngine>()),
  );
  sl.registerLazySingleton<GetFinancialAgeUseCase>(
    () => GetFinancialAgeUseCase(sl<FinancialAgeEngine>()),
  );
  sl.registerLazySingleton<GetResilienceIndexUseCase>(
    () => GetResilienceIndexUseCase(sl<ResilienceEngine>()),
  );
  sl.registerLazySingleton<GetMomentumUseCase>(
    () => GetMomentumUseCase(sl<MomentumEngine>()),
  );

  // Merchant Learning Queue — accumulates unresolved merchants across the session
  sl.registerLazySingleton<MerchantLearningQueue>(
    () => MerchantLearningQueue(),
  );

  // SMS Parser Registry — routes SMS to bank-specific parser
  sl.registerLazySingleton<SmsParserRegistry>(
    () => SmsParserRegistryImpl(),
  );

  // SMS Validation Engine — pre-debit filter + trusted sender check
  sl.registerLazySingleton<SmsValidationEngine>(
    () => const SmsValidationEngineImpl(),
  );

  // Event Replay Engine — stubs until SmsEventReplayEngine ships in Phase 8.2 upgrade
  sl.registerLazySingleton<EventReplayEngine>(
    () => const StubEventReplayEngine(),
  );

  // Use cases — Ingestion Pipeline
  sl.registerLazySingleton<IngestTransactionsUseCase>(
    () => IngestTransactionsUseCase(
      normalizer: sl<TransactionNormalizer>(),
      deduplicator: sl<DuplicateDetector>(),
    ),
  );

  // Use cases — Learning Loop
  sl.registerLazySingleton<RecordExecutionUseCase>(
    () => const RecordExecutionUseCase(),
  );
  sl.registerLazySingleton<EvaluateOutcomeUseCase>(
    () => EvaluateOutcomeUseCase(sl<DecisionLearningEngine>()),
  );
  sl.registerLazySingleton<GetLearningInsightsUseCase>(
    () => GetLearningInsightsUseCase(sl<DecisionLearningEngine>()),
  );
}
