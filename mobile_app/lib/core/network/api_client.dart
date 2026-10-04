import 'package:dio/dio.dart';
import 'package:uczciwa_cena/core/auth/token_storage.dart';
import 'package:uczciwa_cena/core/config/api_config.dart';

/// Dio client that attaches the stored access token to every non-auth request.
Dio createApiClient(TokenStorage tokens) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthEndpoint = options.path.startsWith('/auth/');
        final token = isAuthEndpoint ? null : await tokens.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}
