abstract class RestApi {
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final String baseUrl;
  RestApi({String baseUrl = configuredBaseUrl})
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
}
