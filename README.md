# result_flow_dio

[![pub package](https://img.shields.io/pub/v/result_flow_dio.svg)](https://pub.dev/packages/result_flow_dio) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This package provides a convenient integration layer for using the `result_flow` package with the `dio` HTTP client in Dart and Flutter. It extends `dio`'s capabilities to return API responses and handle network errors directly as `Result` types, promoting a more robust and functional approach to managing the outcomes of your HTTP requests.

## Features

- ✨ **API Outcomes as Explicit Results:** Transform `Future<Response<T>>` from dio into `Future<Result<T>>`. The success case (`Result.success<T>`) contains the response's data payload (`response.data`), while the error case (`Result.error<ResultError>`) contains a mapped error.
- 🔌 **Seamless Dio Integration:** Easily integrate result_flow into your dio workflows by adding the `ResultMapperInterceptor` to your Dio instance. This, combined with the `.result` extension getter, automatically transforms standard dio futures into `Future<Result<T>>`.
- 🌐 **Comprehensive Dio Error Handling:** Automatically maps common `DioExceptionTypes` (like `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `badCertificate`, `cancel`, `connectionError`, and `badResponse`) to specific `ResultError` types (like `NetworkError` or `UnknownError`), providing structured error information within the `Result.error`.
- ✏️ **Customizable Default Messages:** Override the default error messages for various network error types by providing a `NetworkErrorOptions` instance to the `NetworkErrorFactory`, allowing for localized or application-specific error descriptions in the resulting `ResultError` objects.
- 🛡️ **Guaranteed Result Type:** Ensures that a `Future<Result<T>>` is always the outcome of an intercepted and extended dio call (either a success with the response data or an error containing a default `ResultError` based on the `DioException` or a custom bad response mapping), preventing unhandled exceptions in your API call chain.
- ↩️ **Customizable Bad Response Mapping:** Define how non-2xx HTTP responses or API-specific error payloads from dio are mapped to custom ResultError types using the `badResponseParser` in `ResultMapperInterceptor`. This parser receives the full Response and should return a `ResultError`.
- ❓ **Safe Data and Error Access:** Access the success data (T) or the mapped `ResultError` on failure safely using result_flow's getters (data and error) on the resulting `Result<T>` object, which return null for the incorrect state.
- 🧹 **Cleaner API Call Code:** Reduce the need for repetitive try-catch blocks around dio calls and status code checks by adopting the Result pattern for managing API interaction outcomes and accessing data or errors directly from the `Result<T>`.

## Getting started

Add the package to your project using dart pub add or flutter pub add:

```bash
# For Dart projects
dart pub add result_flow_dio result_flow dio

# For Flutter projects
flutter pub add result_flow_dio result_flow dio
```

## Usage

To integrate result_flow with dio, add the `ResultMapperInterceptor` to your Dio instance. This, combined with the `.result` extension getter, automatically wraps your API call outcomes in a Result type, allowing you to use result_flow methods (`on`, `mapTo`, `continueWith`, etc.) for functional error handling and data processing.

Here's a common workflow demonstrating an API request and result processing using method chaining:

```dart
import 'package:dio/dio.dart';
import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/result_flow_dio.dart';

class SomeClass {
  final String someField;
  SomeClass(this.someField);

  factory SomeClass.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('Title')) {
       return SomeClass(json['Title'] as String);
    }
    throw FormatException('Expected "Title" field not found in response');
  }

  @override
  String toString() => 'SomeClass(someField: $someField)';
}

void _handleData(SomeClass data) {
  print('Successfully processed data: $data');
}

void _handleError(ResultError error) {
  print('Failed with error: ${error.message}');
  print('Error Type: ${error.runtimeType}');
   if (error is NetworkError) {
     print('Status Code: ${error.statusCode}');
     print('Error Code: ${error.code}');
   } else {
      print('Error Code: ${error.code}');
   }
}

void main() async {
  const title = 'Inception';

  final dio = Dio();

  dio.interceptors.add(
    ResultMapperInterceptor(
      badResponseParser: (Response response) {
        final message = response.data?['Error'] as String? ?? 'Unknown API error';
        return NetworkError(message, statusCode: response.statusCode);
      },
    ),
  );

  final initialResult =
      await dio.get<dynamic>('https://www.omdbapi.com/?apikey=YOUR_API_KEY&t=$title').result;

  initialResult
      // Use mapTo to transform the success data from dynamic to SomeClass.
      // Exceptions thrown inside this callback are automatically caught and
      // converted into a Result.error by mapTo itself.
      .mapTo((data) => Result.success(SomeClass.fromJson(data as Map<String, dynamic>)))
      // Use on() to handle the final outcome (either Success<SomeClass> or Error<ResultError>)
      .on(
        success: (data) => _handleData(data),
        error: (error) => _handleError(error),
      );
}

// Note: NetworkError and ResultError are part of the result_flow package,
// so you don't need to define them here.
```

## Related Packages

`result_flow_dio` is built to integrate `result_flow` with `dio`.

| Package             | Pub.dev Link                                                                                                     |
| :------------------ | :--------------------------------------------------------------------------------------------------------------- |
| `fetch_result_bloc` | [![pub package](https://img.shields.io/pub/v/fetch_result_bloc.svg)](https://pub.dev/packages/fetch_result_bloc) |
| `result_flow`       | [![pub package](https://img.shields.io/pub/v/result_flow.svg)](https://pub.dev/packages/result_flow)             |
| `result_flow_dio`   | [![pub package](https://img.shields.io/pub/v/result_flow_dio.svg)](https://pub.dev/packages/result_flow_dio)     |
