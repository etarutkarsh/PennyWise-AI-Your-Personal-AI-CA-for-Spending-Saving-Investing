import '../../domain/shared/result.dart';

/// Base contract for all use cases.
abstract class UseCase<Input, Output> {
  Future<Result<Output>> call(Input params);
}

/// For use cases with no input
abstract class NoParamUseCase<Output> {
  Future<Result<Output>> call();
}
