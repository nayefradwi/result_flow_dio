import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/network_error_factory.dart';

typedef BadResponseParser = ResultError Function(Response<dynamic> response);
BadResponseParser defaultBadResponseParser = (Response<dynamic> response) {
  return NetworkErrorFactory.instance.badResponseError(
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
        _ =>
          response != null
              ? badResponseParser(response!)
              : _errFactory.badResponseError(),
      };
    } catch (e) {
      return UnknownError(message: e.toString());
    }
  }
}
