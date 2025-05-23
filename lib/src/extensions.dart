import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/network_error_factory.dart';

typedef BadResponseParser = ResultError Function(Response<dynamic> response);
BadResponseParser defaultBadResponseParser = (Response<dynamic> response) {
  return NetworkErrorFactory.instance.badResponseError(
    statusCode: response.statusCode,
  );
};

/// [ResponseExtenstion] is an extension on the [Response] class from Dio.
/// It provides a method to extract a [Result] object from the response.
/// The [withResult] method returns a new [Response] object with the data
/// transformed to a [Result] type.
///
/// This is useful for handling the response in a more functional way,
/// using the [Result] type to represent success and failure.
///
/// The [result] getter extracts the result from the response.
/// If the data is already a [Result], it returns it as is.
/// Otherwise, it wraps the data in a [Result.success] object.
extension ResponseExtenstion<T> on Response<T> {
  /// Converts the [Response] with data of type [T] to a [Response] with data of
  /// type [Result].
  Response<Result<T?>> withResult() {
    return Response<Result<T?>>(
      data: result,
      requestOptions: requestOptions,
      statusCode: statusCode,
      statusMessage: statusMessage,
      isRedirect: isRedirect,
      redirects: redirects,
      extra: extra,
      headers: headers,
    );
  }

  Result<T?> get result {
    if (data is Result<T?>) {
      return data! as Result<T?>;
    }
    return Result.success(data);
  }
}

/// [ResponseAsyncExtension] is an extension on the [Future<Response<T>>]
/// class from Dio. It allows to safely extract [FutureResult] from an async
/// response.
///
/// The [unSafeResult] getter extracts the result from the response.
/// If the [Future<Response<T>>] throws an exception, it will NOT be caught.
///
/// The [result] getter safely extracts the result from the response.
/// If an excpetion occurs, it returns a [Result] with the
/// error as [UnknownError].
extension ResponseAsyncExtension<T> on Future<Response<T>> {
  FutureResult<T?> get unSafeResult async {
    final response = await this;
    return response.result;
  }

  /// Safely extracts the result from the response.
  /// If an error occurs, it returns a [Result] with the error.
  /// This is useful for handling the response in a more functional way,
  /// using the [Result] type to represent success and failure.
  FutureResult<T?> get result async {
    try {
      return await unSafeResult;
    } catch (e) {
      return Result.exception(e);
    }
  }
}

/// [DioExceptionExtension] is an extension on the [DioException] class from
/// Dio. It provides a method to convert the exception into a [ResultError].
/// The [getResultError] method returns a [ResultError] based on the type
/// of DioException encountered.
///
/// [NetworkErrorFactory] is used to create instances of [ResultError]
/// based on the type of network error encountered.
extension DioExceptionExtension on DioException {
  NetworkErrorFactory get _errFactory => NetworkErrorFactory.instance;
  ResultError getResultError({BadResponseParser? badResponseParser}) {
    final error = switch (type) {
      DioExceptionType.connectionTimeout =>
        _errFactory.connectionTimeoutError(),
      DioExceptionType.sendTimeout => _errFactory.sendTimeoutError(),
      DioExceptionType.receiveTimeout => _errFactory.receiveTimeoutError(),
      DioExceptionType.badCertificate => _errFactory.badCertificateError(),
      DioExceptionType.cancel => _errFactory.cancelError(),
      DioExceptionType.connectionError => _errFactory.connectionError(),
      DioExceptionType.badResponse => _handleBadResponse(
        badResponseParser ?? defaultBadResponseParser,
      ),
      _ => UnknownError(message: toString()),
    };

    return error;
  }

  ResultError _handleBadResponse(BadResponseParser badResponseParser) {
    try {
      return switch (response?.data) {
        final String message => _errFactory.badResponseError(message: message),
        null => _errFactory.badResponseError(statusCode: response?.statusCode),
        _ when response != null => badResponseParser(response!),
        _ => _errFactory.badResponseError(),
      };
    } catch (e) {
      return UnknownError(message: e.toString());
    }
  }
}
