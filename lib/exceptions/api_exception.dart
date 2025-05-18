class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final StackTrace? stackTrace;

  const ApiException(this.message, [this.statusCode, this.stackTrace]);

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status $statusCode)' : ''}';
  }
}