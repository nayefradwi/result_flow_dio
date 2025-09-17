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
      // data can then be parsed as a Map<String, dynamic> or a List<dynamic>
      // depending on the API response.
      // For example, if the API returns a JSON object:
      // final movie = Movie.fromJson(data as Map<String, dynamic>);
      // print(movie.title);
      // Or if the API returns a JSON array:
      // final movies = (data as List<dynamic>)
      //     .map((item) => Movie.fromJson(item as Map<String, dynamic>))
      //     .toList();
      // print(movies);
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
      badResponseParser: (r, {trace}) {
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
