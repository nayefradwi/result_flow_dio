// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/extensions.dart';
import 'package:result_flow_dio/src/interceptor.dart';

void main() async {
  const title = 'Inception';
  final dioLoggerPrefix = createDioLoggerPrefix();

  final result =
      await dioLoggerPrefix
          .get<dynamic>('https://www.omdbapi.com/?apikey=YOUR_API_KEY&t=$title')
          .result;

  result.on(
    success: (data) {
      print(data);
    },
    error: (err) {
      print(err.message);
      print(err.runtimeType);
      print(err.stackTrace);
    },
  );
}

Dio createDioLoggerPrefix() {
  final dio = Dio();
  dio.interceptors.add(LoggerInterceptor());
  dio.interceptors.add(
    ResultMapperInterceptor(
      badResponseParser: (r) {
        final message = r.data?['Error'] as String? ?? 'Unknown error';
        return NetworkError(message);
      },
    ),
  );
  return dio;
}

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('Request: ${options.method} ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    print('Response: ${response.statusCode} ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler handler) {
    print('Error: ${e.message} ${e.response?.data}');
    super.onError(e, handler);
  }
}
