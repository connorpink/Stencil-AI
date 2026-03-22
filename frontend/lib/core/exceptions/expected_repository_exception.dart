// expected repository exceptions are exceptions that originate in the repository from an expected source with expected properties
class ExpectedRepositoryException implements Exception {
  final String message;
  const ExpectedRepositoryException(this.message);

  @override
  String toString() => 'ExpectedRepositoryException: $message';
}