/// [ResultNetworkCode] contains the error codes for network requests.
/// These codes are used in to uniquely identify the reason an api
/// request failed.
abstract class ResultNetworkCode {
  static const connectionTimeoutCode = 'connection_timeout';
  static const sendTimeoutCode = 'send_timeout';
  static const receiveTimeoutCode = 'receive_timeout';
  static const badCertificateCode = 'bad_certificate';
  static const cancelCode = 'cancel';
  static const connectionErrorCode = 'connection_error';
  static const badResponseCode = 'bad_response';
}
