import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/result_flow_dio.dart';

enum OnErrorAction { throwException, resolve, next }

enum OnResponseAction { resolve, next }

class ResultMapperInterceptor extends Interceptor {
  const ResultMapperInterceptor({
    this.badResponseParser,
    this.onErrorAction = OnErrorAction.resolve,
    this.onResponseAction = OnResponseAction.resolve,
  });

  final BadResponseParser? badResponseParser;
  final OnErrorAction onErrorAction;
  final OnResponseAction onResponseAction;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final responseWithResult = response.withResult();
    return switch (onResponseAction) {
      OnResponseAction.resolve => handler.resolve(responseWithResult),
      OnResponseAction.next => handler.next(responseWithResult),
    };
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final error = err.getResultError(badResponseParser: badResponseParser);
    final response = Response(
      data: Result<dynamic>.error(error),
      requestOptions: err.requestOptions,
      statusCode: err.response?.statusCode,
      statusMessage: err.response?.statusMessage,
      isRedirect: err.response?.isRedirect ?? false,
      redirects: err.response?.redirects ?? [],
      extra: err.response?.extra,
      headers: err.response?.headers,
    );

    final errWithResult = err.copyWith(response: response);

    return switch (onErrorAction) {
      OnErrorAction.throwException => handler.reject(errWithResult),
      OnErrorAction.resolve => handler.resolve(response),
      OnErrorAction.next => handler.next(errWithResult),
    };
  }
}
