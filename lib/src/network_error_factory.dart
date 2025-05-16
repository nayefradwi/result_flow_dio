import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/constants.dart';

/// [NetworkErrorOptions] is used to configure error messages based on the
/// Network Error type. It utilizes the [ResultNetworkCode] to give a unique
/// identifier to each error while allowing customization of the error message.
class NetworkErrorOptions {
  const NetworkErrorOptions({
    this.onConnectionTimeoutMessage = 'Connection timeout occurred',
    this.onSendTimeoutMessage = 'Send timeout occurred',
    this.onReceiveTimeoutMessage = 'Receive timeout occurred',
    this.onCancelMessage = 'Request was cancelled',
    this.onBadCertificateMessage = 'Bad certificate encountered',
    this.onConnectionErrorMessage = 'Connection error occurred',
    this.onBadResponseMessage = 'Bad response received',
    this.onUnknownErrorMessage = 'Unknown error occurred',
    this.onBadResponseStatusCode = 0,
  });

  final String onConnectionTimeoutMessage;
  final String onSendTimeoutMessage;
  final String onReceiveTimeoutMessage;
  final String onCancelMessage;
  final String onBadCertificateMessage;
  final String onConnectionErrorMessage;
  final String onBadResponseMessage;
  final String onUnknownErrorMessage;

  final int onBadResponseStatusCode;
}

/// [NetworkErrorFactory] is a singleton class that provides methods to create
/// instances of [NetworkError] based on the type of network error encountered.
/// It uses the [NetworkErrorOptions] to customize the error messages.
/// The factory methods return instances of [NetworkError] with appropriate
/// error messages and codes.
///
/// The factory methods are designed to be used in a network request context
/// where different types of network errors can occur.
class NetworkErrorFactory {
  NetworkErrorFactory._internal({this.options = const NetworkErrorOptions()});
  static NetworkErrorFactory instance = NetworkErrorFactory._internal();
  final NetworkErrorOptions options;

  /// [setOptions] allows you to set a new instance of [NetworkErrorOptions]
  /// to customize the error messages. This is useful for changing the
  /// default error messages provided by the factory.
  static void setOptions(NetworkErrorOptions newOptions) {
    instance = NetworkErrorFactory._internal(options: newOptions);
  }

  NetworkError connectionTimeoutError() => NetworkError(
    options.onConnectionTimeoutMessage,
    code: ResultNetworkCode.connectionTimeoutCode,
  );

  NetworkError sendTimeoutError() => NetworkError(
    options.onSendTimeoutMessage,
    code: ResultNetworkCode.sendTimeoutCode,
  );

  NetworkError receiveTimeoutError() => NetworkError(
    options.onReceiveTimeoutMessage,
    code: ResultNetworkCode.receiveTimeoutCode,
  );

  NetworkError cancelError() =>
      NetworkError(options.onCancelMessage, code: ResultNetworkCode.cancelCode);

  NetworkError badCertificateError() => NetworkError(
    options.onBadCertificateMessage,
    code: ResultNetworkCode.badCertificateCode,
  );

  NetworkError connectionError() => NetworkError(
    options.onConnectionErrorMessage,
    code: ResultNetworkCode.connectionErrorCode,
  );

  NetworkError badResponseError({String? message, int? statusCode}) {
    return NetworkError(
      message ?? options.onBadResponseMessage,
      code: ResultNetworkCode.badResponseCode,
      statusCode: statusCode ?? options.onBadResponseStatusCode,
    );
  }
}
