import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/constants.dart';

typedef BadResponseParser = ResultError Function(Response<dynamic> response);
BadResponseParser defaultBadResponseParser = (Response<dynamic> response) {
  return NetworkErrors.badResponseError(
    message: response.statusMessage,
    statusCode: response.statusCode,
  );
};

extension ResponseExtenstion<T> on Response<T> {
  Response<Result<T?>> withResult() {
    return Response<Result<T?>>(
      data: Result.success(data),
      requestOptions: requestOptions,
      statusCode: statusCode,
      statusMessage: statusMessage,
      isRedirect: isRedirect,
      redirects: redirects,
      extra: extra,
      headers: headers,
    );
  }
}

extension DioExceptionExtension on DioException {
  ResultError getResultError({BadResponseParser? badResponseParser}) {
    final error = switch (type) {
      DioExceptionType.connectionTimeout =>
        NetworkErrors.connectionTimeoutError(),
      DioExceptionType.sendTimeout => NetworkErrors.sendTimeoutError(),
      DioExceptionType.receiveTimeout => NetworkErrors.receiveTimeoutError(),
      DioExceptionType.badCertificate => NetworkErrors.badCertificateError(),
      DioExceptionType.cancel => NetworkErrors.cancelError(),
      DioExceptionType.connectionError => NetworkErrors.connectionError(),
      DioExceptionType.badResponse => _handleBadResponse(
        badResponseParser ?? defaultBadResponseParser,
      ),
      _ => UnknownError(message: toString()),
    };

    return error;
  }

  ResultError _handleBadResponse(BadResponseParser badResponseParser) {
    return switch (response?.data) {
      final String message => NetworkErrors.badResponseError(message: message),
      final Response<dynamic> r => badResponseParser(r),
      null => NetworkErrors.badResponseError(statusCode: response?.statusCode),
      _ => NetworkErrors.badResponseError(),
    };
  }
}

extension NetworkErrors on ResultError {
  static NetworkError connectionTimeoutError() => NetworkError(
    'Connection timeout occurred',
    code: ResultNetworkCode.connectionTimeoutCode,
  );

  static NetworkError sendTimeoutError() => NetworkError(
    'Send timeout occurred',
    code: ResultNetworkCode.sendTimeoutCode,
  );

  static NetworkError receiveTimeoutError() => NetworkError(
    'Receive timeout occurred',
    code: ResultNetworkCode.receiveTimeoutCode,
  );

  static NetworkError cancelError() =>
      NetworkError('Request was cancelled', code: ResultNetworkCode.cancelCode);

  static NetworkError badCertificateError() => NetworkError(
    'Bad certificate encountered',
    code: ResultNetworkCode.badCertificateCode,
  );

  static NetworkError connectionError() => NetworkError(
    'Connection error occurred',
    code: ResultNetworkCode.connectionErrorCode,
  );

  static NetworkError badResponseError({String? message, int? statusCode}) {
    return NetworkError(
      message ?? 'Bad response received',
      code: ResultNetworkCode.badResponseCode,
      statusCode: statusCode ?? 0,
    );
  }
}
