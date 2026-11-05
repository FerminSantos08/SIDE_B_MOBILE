class ApiConfig {
  ApiConfig._();

  /// Hosts LAN conocidos para SIDE B. El primero es el preferido y los
  /// siguientes se usan automáticamente si no se puede establecer conexión.
  static const List<String> baseUrls = [
    'http://10.223.22.245:8000',
    'http://192.168.3.15:8000',
  ];

  static String get baseUrl => baseUrls.first;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
