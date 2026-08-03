import 'package:get_it/get_it.dart';

import '../../application/decision/get_dashboard_feed_use_case.dart';
import '../../application/decision/get_today_decision_use_case.dart';
import '../../application/decision/record_decision_lifecycle_use_case.dart';
import '../../application/partner/get_partner_programs_use_case.dart';
import '../../infrastructure/mappers/decision_mapper.dart';
import '../../infrastructure/mappers/partner_mapper.dart';
import '../../infrastructure/repositories/hardcoded_partner_repository.dart';
import '../../infrastructure/repositories/rest_decision_repository.dart';
import '../../infrastructure/services/partner_asset_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Services — initialized eagerly so manifest is ready before first render
  await PartnerAssetService.instance.initialize();

  // Mappers
  sl.registerLazySingleton<PartnerMapper>(() => const PartnerMapper());
  sl.registerLazySingleton<DecisionMapper>(
    () => DecisionMapper(sl<PartnerMapper>()),
  );

  // Repositories (concrete implementations behind domain interfaces)
  sl.registerLazySingleton<HardcodedPartnerRepository>(
    () => HardcodedPartnerRepository(sl<PartnerMapper>()),
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
  sl.registerLazySingleton<GetDashboardFeedUseCase>(
    () => GetDashboardFeedUseCase(
      sl<RestDecisionRepository>(),
      sl<HardcodedPartnerRepository>(),
    ),
  );
}
