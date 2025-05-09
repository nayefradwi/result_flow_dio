// ignore_for_file: cascade_invocations

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/result_flow_dio.dart';
import 'package:test/test.dart';

class MockInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockDioException extends Mock implements DioException {}

class FakeResponse extends Fake implements Response<dynamic> {}

class FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
  });

  group('ResultMapperInterceptor - successful response mapping', () {
    late MockInterceptorHandler handler;

    setUp(() {
      handler = MockInterceptorHandler();
      when(() => handler.next(any())).thenReturn(null);
      when(() => handler.resolve(any())).thenReturn(null);
      when(() => handler.reject(any())).thenReturn(null);
    });

    tearDown(() {
      reset(handler);
    });

    test('should map response.data to result success of the same type', () {
      final mockData = {'id': 1, 'name': 'test'};
      final response = Response<Map<String, dynamic>>(
        data: mockData,
        requestOptions: RequestOptions(path: '/test'),
      );

      final resultResponse = response.withResult();
      expect(resultResponse.data, isA<Result<Map<String, dynamic>?>>());
      expect(resultResponse.data?.isSuccess, isTrue);
      expect(resultResponse.data?.data, equals(mockData));
    });

    test('should map null data to result success with null data', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
      );

      final resultResponse = response.withResult();

      expect(resultResponse.data, isA<Result<dynamic>>());
      expect(resultResponse.data?.isSuccess, isTrue);
      expect(resultResponse.data?.data, isNull);
    });

    test(
      'should perform correct on response action either next or resolve',
      () {
        const interceptor = ResultMapperInterceptor();
        final resolveHandler = MockInterceptorHandler();

        when(() => resolveHandler.next(any())).thenReturn(null);
        when(() => resolveHandler.resolve(any())).thenReturn(null);

        final response = Response<dynamic>(
          data: 'test',
          requestOptions: RequestOptions(path: '/test'),
        );

        interceptor.onResponse(response, resolveHandler);

        verify(() => resolveHandler.resolve(any())).called(1);
        verifyNever(() => resolveHandler.next(any()));

        final nextHandler = MockInterceptorHandler();
        when(() => nextHandler.next(any())).thenReturn(null);
        when(() => nextHandler.resolve(any())).thenReturn(null);

        const nextInterceptor = ResultMapperInterceptor(
          onResponseAction: OnResponseAction.next,
        );

        nextInterceptor.onResponse(response, nextHandler);

        verify(() => nextHandler.next(any())).called(1);
        verifyNever(() => nextHandler.resolve(any()));
      },
    );

    test(
      'should receive correct responses from interceptors before mapper',
      () {
        const interceptor = ResultMapperInterceptor();

        const modifiedData = 'modified by previous interceptor';
        final response = Response<dynamic>(
          data: modifiedData,
          requestOptions: RequestOptions(path: '/test'),
        );

        interceptor.onResponse(response, handler);

        final capturedResponse =
            verify(() => handler.resolve(captureAny())).captured.first
                as Response;
        expect(capturedResponse.data, isA<Result<dynamic>>());
        expect(capturedResponse.data.data, equals(modifiedData));
      },
    );
  });

  group(
    'ResultMapperInterceptor - dio exception mapping for not bad response',
    () {
      late MockErrorInterceptorHandler errorHandler;

      setUp(() {
        errorHandler = MockErrorInterceptorHandler();
        when(() => errorHandler.next(any())).thenReturn(null);
        when(() => errorHandler.resolve(any())).thenReturn(null);
        when(() => errorHandler.reject(any())).thenReturn(null);
      });

      tearDown(() {
        reset(errorHandler);
      });

      test('should parse dio exception to have result error as response', () {
        final dioException = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        const interceptor = ResultMapperInterceptor();

        interceptor.onError(dioException, errorHandler);

        final capturedResponse =
            verify(() => errorHandler.resolve(captureAny())).captured.first
                as Response;

        expect(capturedResponse.data, isA<Result<dynamic>>());
        expect(capturedResponse.data?.isSuccess, isFalse);
        expect(capturedResponse.data?.error, isA<NetworkError>());
      });
      test(
        '''should map non bad response dio exceptions to the correct default message and code''',
        () {
          final dioException = DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/test'),
          );

          const interceptor = ResultMapperInterceptor();

          interceptor.onError(dioException, errorHandler);

          final capturedResponse =
              verify(() => errorHandler.resolve(captureAny())).captured.first
                  as Response;

          final error = capturedResponse.data?.error as NetworkError;
          expect(error.message, equals('Connection timeout occurred'));
          expect(error.code, equals(ResultNetworkCode.connectionTimeoutCode));
        },
      );

      test(
        'should use overriden error messages for non bad response errors',
        () {
          final originalOptions = NetworkErrorFactory.instance.options;
          const customOptions = NetworkErrorOptions(
            onConnectionTimeoutMessage: 'Custom timeout error',
          );

          NetworkErrorFactory.setOptions(customOptions);

          final dioException = DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/test'),
          );

          const interceptor = ResultMapperInterceptor();

          interceptor.onError(dioException, errorHandler);

          final capturedResponse =
              verify(() => errorHandler.resolve(captureAny())).captured.first
                  as Response;

          final error = capturedResponse.data?.error as NetworkError;
          expect(error.message, equals('Custom timeout error'));

          // Reset to original options
          NetworkErrorFactory.setOptions(originalOptions);
        },
      );
    },
  );

  group('ResultMapperInterceptor - dio exception mapping for bad response', () {
    late MockErrorInterceptorHandler errorHandler;

    setUp(() {
      errorHandler = MockErrorInterceptorHandler();
      when(() => errorHandler.next(any())).thenReturn(null);
      when(() => errorHandler.resolve(any())).thenReturn(null);
      when(() => errorHandler.reject(any())).thenReturn(null);
    });

    tearDown(() {
      reset(errorHandler);
    });

    test('should parse dio exception to have result error as response', () {
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      const interceptor = ResultMapperInterceptor();

      interceptor.onError(dioException, errorHandler);

      final capturedResponse =
          verify(() => errorHandler.resolve(captureAny())).captured.first
              as Response;

      expect(capturedResponse.data, isA<Result<dynamic>>());
      expect(capturedResponse.data?.isSuccess, isFalse);
      expect(capturedResponse.data?.error, isA<NetworkError>());
      expect(
        (capturedResponse.data?.error as NetworkError).code,
        equals(ResultNetworkCode.badResponseCode),
      );
    });

    test('should use default parser if no parser is passed', () {
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      const interceptor = ResultMapperInterceptor();

      interceptor.onError(dioException, errorHandler);

      final capturedResponse =
          verify(() => errorHandler.resolve(captureAny())).captured.first
              as Response;

      final error = capturedResponse.data?.error as NetworkError;
      expect(error.statusCode, equals(404));
      expect(error.code, equals(ResultNetworkCode.badResponseCode));
    });

    test(
      'should perform correct on error action either next, resolve, or reject ',
      () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
        );

        // Test resolve action
        const resolveInterceptor = ResultMapperInterceptor();
        final resolveHandler = MockErrorInterceptorHandler();
        when(() => resolveHandler.next(any())).thenReturn(null);
        when(() => resolveHandler.resolve(any())).thenReturn(null);
        when(() => resolveHandler.reject(any())).thenReturn(null);

        resolveInterceptor.onError(dioException, resolveHandler);

        verify(() => resolveHandler.resolve(any())).called(1);
        verifyNever(() => resolveHandler.next(any()));
        verifyNever(() => resolveHandler.reject(any()));

        // Test next action
        const nextInterceptor = ResultMapperInterceptor(
          onErrorAction: OnErrorAction.next,
        );
        final nextHandler = MockErrorInterceptorHandler();
        when(() => nextHandler.next(any())).thenReturn(null);
        when(() => nextHandler.resolve(any())).thenReturn(null);
        when(() => nextHandler.reject(any())).thenReturn(null);

        nextInterceptor.onError(dioException, nextHandler);

        verify(() => nextHandler.next(any())).called(1);
        verifyNever(() => nextHandler.resolve(any()));
        verifyNever(() => nextHandler.reject(any()));

        // Test reject action
        const rejectInterceptor = ResultMapperInterceptor(
          onErrorAction: OnErrorAction.throwException,
        );
        final rejectHandler = MockErrorInterceptorHandler();
        when(() => rejectHandler.next(any())).thenReturn(null);
        when(() => rejectHandler.resolve(any())).thenReturn(null);
        when(() => rejectHandler.reject(any())).thenReturn(null);

        rejectInterceptor.onError(dioException, rejectHandler);

        verify(() => rejectHandler.reject(any())).called(1);
        verifyNever(() => rejectHandler.resolve(any()));
        verifyNever(() => rejectHandler.next(any()));
      },
    );

    test(
      '''should auto map string responses to network error with message and status''',
      () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            data: 'Custom error message from server',
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
        );

        // Create a separate test instance
        final testErrorHandler = MockErrorInterceptorHandler();
        when(() => testErrorHandler.next(any())).thenReturn(null);
        when(() => testErrorHandler.resolve(any())).thenReturn(null);
        when(() => testErrorHandler.reject(any())).thenReturn(null);

        final originalOptions = NetworkErrorFactory.instance.options;
        const customOptions = NetworkErrorOptions(onBadResponseStatusCode: 500);
        NetworkErrorFactory.setOptions(customOptions);

        const interceptor = ResultMapperInterceptor();

        interceptor.onError(dioException, testErrorHandler);

        final capturedResponse =
            verify(() => testErrorHandler.resolve(captureAny())).captured.first
                as Response;

        final error = capturedResponse.data?.error as NetworkError;
        expect(error.message, equals('Custom error message from server'));
        expect(error.code, equals(ResultNetworkCode.badResponseCode));
        expect(error.statusCode, equals(500));

        // Reset to original options
        NetworkErrorFactory.setOptions(originalOptions);
      },
    );

    test(
      'should extract correct result error based on custom response parser',
      () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            data: {'error': 'Custom error', 'code': 'custom_code'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/test'),
          ),
        );

        // Create a separate test instance
        final testErrorHandler = MockErrorInterceptorHandler();
        when(() => testErrorHandler.next(any())).thenReturn(null);
        when(() => testErrorHandler.resolve(any())).thenReturn(null);
        when(() => testErrorHandler.reject(any())).thenReturn(null);

        NetworkError customParser(Response<dynamic> response) {
          return NetworkError(
            'Custom error',
            code: 'custom_code',
            statusCode: 400,
          );
        }

        final interceptor = ResultMapperInterceptor(
          badResponseParser: customParser,
        );

        interceptor.onError(dioException, testErrorHandler);

        final capturedResponse =
            verify(() => testErrorHandler.resolve(captureAny())).captured.first
                as Response;

        final error = capturedResponse.data?.error as NetworkError;
        expect(error.message, equals('Custom error'));
        expect(error.code, equals('custom_code'));
        expect(error.statusCode, equals(400));
      },
    );

    test('should map error to unknown error if parser throws an exception', () {
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          data: {'invalid': 'format'},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Create a separate test instance
      final testErrorHandler = MockErrorInterceptorHandler();
      when(() => testErrorHandler.next(any())).thenReturn(null);
      when(() => testErrorHandler.resolve(any())).thenReturn(null);
      when(() => testErrorHandler.reject(any())).thenReturn(null);

      ResultError throwingParser(Response<dynamic> response) {
        throw Exception('Parser error');
      }

      final interceptor = ResultMapperInterceptor(
        badResponseParser: throwingParser,
      );

      interceptor.onError(dioException, testErrorHandler);

      final capturedResponse =
          verify(() => testErrorHandler.resolve(captureAny())).captured.first
              as Response;

      expect(capturedResponse.data?.error, isA<UnknownError>());
    });
  });
}
