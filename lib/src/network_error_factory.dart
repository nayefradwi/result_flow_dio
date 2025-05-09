import 'package:result_flow/result_flow.dart';
import 'package:result_flow_dio/src/constants.dart';

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

class NetworkErrorFactory {
  NetworkErrorFactory._internal({this.options = const NetworkErrorOptions()});
  static NetworkErrorFactory instance = NetworkErrorFactory._internal();
  final NetworkErrorOptions options;
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
