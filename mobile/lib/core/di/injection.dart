import 'package:get_it/get_it.dart';

import '../../application/decision/get_dashboard_feed_use_case.dart';
import '../../application/decision/get_today_decision_use_case.dart';
import '../../application/decision/record_decision_lifecycle_use_case.dart';
import '../../application/finance/get_health_score_use_case.dart';
import '../../application/partner/get_partner_programs_use_case.dart';
import '../../domain/engines/evidence_builder.dart';
import '../../domain/engines/health_score_engine.dart';
import '../../domain/engines/partner_matching_engine.dart';
import '../../domain/engines/product_knowledge_graph.dart';
import '../../domain/partner/product_catalog.dart';
import '../../infrastructure/engines/hardcoded_product_knowledge_graph.dart';
import '../../infrastructure/engines/rule_based_health_score_engine.dart';
import '../../infrastructure/engines/rule_based_partner_matching_engine.dart';
import '../../infrastructure/engines/stub_evidence_builder.dart';
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

  // Use cases
  sl.registerLazySingleton<GetTodayDecisionUseCase>(
    () => GetTodayDecisionUseCase(sl<RestDecisionRepository>()),
  );
  sl.registerLazySingleton<RecordDecisionLifecycleUseCase>(
    () => RecordDecisionLifecycleUseCase(sl<RestDecisionRepository>()),
  );
  sl.registerLazySingleton<GetPartnerProgramsUseCase>(
    () => GetPartnerProgramsUseCase(sl<HardcodedPartnerRepository>()),
  );
  sl.registerLazySingleton<GetHealthScoreUseCase>(
    () => GetHealthScoreUseCase(sl<HealthScoreEngine>()),
  );
  sl.registerLazySingleton<GetDashboardFeedUseCase>(
    () => GetDashboardFeedUseCase(
      sl<RestDecisionRepository>(),
      sl<HardcodedPartnerRepository>(),
    ),
  );
}
