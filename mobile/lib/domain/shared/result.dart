// Defines a Result<T> type for explicit success/failure handling without exceptions.

/// A discriminated union representing either a successful value or a failure.
sealed class Result<T> {
  const Result();

  factory Result.success(T value) => Success<T>(value);

  factory Result.failure(String message, [Exception? exception]) =>
      Failure<T>(message, exception);

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>() => null,
      };

  String? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(message: final m) => m,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(String message, Exception? exception) onFailure,
  }) =>
      switch (this) {
        Success<T>(value: final v) => onSuccess(v),
        Failure<T>(message: final m, exception: final e) => onFailure(m, e),
      };
}

/// The success variant of [Result].
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// The failure variant of [Result].
final class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> && other.message == message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Failure($message)';
}
