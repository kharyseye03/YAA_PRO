sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiSuccess<T>;
  const factory ApiResult.failure(String message, {int? statusCode}) = ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final message, :final statusCode) => failure(message, statusCode),
    };
  }

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(:final data) => data,
    _ => null,
  };
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const ApiFailure(this.message, {this.statusCode});
}
