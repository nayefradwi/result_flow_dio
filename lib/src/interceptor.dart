import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/result_flow_dio.dart';

enum OnErrorAction { throwException, resolve, next }

enum OnResponseAction { resolve, next }

/// [ResultMapperInterceptor] is a Dio interceptor that transforms the
/// response and error objects into a [Result] type. It allows you to handle
/// errors and responses in a more functional way, using the [Result] type
/// to represent success and failure.
///
/// It allows you to customize the error handling behavior using the
/// [onErrorAction] and [onResponseAction] parameters.
class ResultMapperInterceptor extends Interceptor {
  /// Using [OnErrorAction] and [OnResponseAction] enums to determine
  /// how to handle errors and responses.
  ///
  /// The [OnErrorAction] enum has three options:
  /// - [OnErrorAction.throwException]: Throws the error as a DioException.
  /// - [OnErrorAction.resolve]: Resolves the error as a Result.
  /// - [OnErrorAction.next]: Passes the error to the next interceptor.
  ///
  /// The [OnResponseAction] enum has three options:
  /// - [OnResponseAction.resolve]: Resolves the response as a Result.
  /// - [OnResponseAction.next]: Passes the response to the next interceptor.
  ///
  /// The [badResponseParser] is a function that takes a [Response] and
  /// returns a [ResultError]. This is used to parse the response in case of
  /// a bad response. If not provided, the default parser will be used.
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
