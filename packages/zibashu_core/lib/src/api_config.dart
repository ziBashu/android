/// Runtime API configuration shared by all ziBashu apps.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = defaultBaseUrl,
    this.demoMode = false,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  static const String defaultBaseUrl = 'https://zibashu4.com';
  static const String websiteUrl = 'https://zibashu4.com';

  /// Production site origin (no trailing slash).
  final String baseUrl;

  /// When true, apps skip live network and use local fixtures.
  final bool demoMode;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  Uri uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }

  ApiConfig copyWith({
    String? baseUrl,
    bool? demoMode,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      demoMode: demoMode ?? this.demoMode,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }
}
