import 'package:dio/dio.dart';
import 'package:uczciwa_cena/core/auth/token_storage.dart';

class AuthRepository {
  AuthRepository({required this.dio, required this.tokens});

  final Dio dio;
  final TokenStorage tokens;

  /// Sends the SMS code. [localNumber] is the nine digits the user typed.
  Future<void> requestCode(String localNumber) {
    return dio.post<void>(
      '/auth/phone/start',
      data: {'phone_number': _toE164(localNumber)},
    );
  }

  /// Exchanges the SMS code for tokens and stores them.
  Future<void> verifyCode(String localNumber, String code) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/phone/verify',
      data: {'phone_number': _toE164(localNumber), 'code': code},
    );
    await _saveTokens(response.data);
  }

  /// Returns true when the user can stay signed in.
  ///
  /// A valid access token is kept as is. A rejected one is refreshed. Tokens
  /// are cleared only when the server rejects the refresh token, so being
  /// offline or hitting a server error never signs the user out.
  Future<bool> restoreSession() async {
    final access = await tokens.readAccessToken();
    if (access == null) {
      return _refresh();
    }

    try {
      await dio.get<void>('/me');
      return true;
    } on DioException catch (error) {
      if (_isServerUnreachable(error)) {
        return true;
      }
      return _refresh();
    }
  }

  Future<void> logout() => tokens.clear();

  Future<bool> _refresh() async {
    final refresh = await tokens.readRefreshToken();
    if (refresh == null) {
      return false;
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      await _saveTokens(response.data);
      return true;
    } on DioException catch (error) {
      if (!_isServerUnreachable(error)) {
        await tokens.clear();
      }
      return false;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic>? body) {
    return tokens.save(
      accessToken: body!['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
    );
  }

  static bool _isServerUnreachable(DioException error) {
    const offlineTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    };
    final status = error.response?.statusCode ?? 0;
    return offlineTypes.contains(error.type) || status >= 500;
  }

  /// The backend expects E.164. The app only collects Polish numbers.
  static String _toE164(String localNumber) => '+48$localNumber';
}
