import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/network/cookie_manager.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:logging/logging.dart';

class AuthRepository {
  AuthRepository(LichessClient client, Ref ref)
    : _client = client,
      _ref = ref;

  final LichessClient _client;
  final Ref _ref;
  final Logger _log = Logger('AuthRepository');

  /// Sign in with username/email and password (cookie-based).
  ///
  /// This method posts the credentials to the /login endpoint and receives
  /// a session cookie in return. The cookie is automatically managed by the
  /// HTTP client's cookie jar.
  Future<AuthSessionState> signIn(String username, String password, {bool remember = true}) async {
    _log.info('Attempting to sign in with username: $username');

    try {
      // Post login credentials
      _log.info('Sending POST request to /login endpoint');
      final response = await _client.post(
        Uri(path: '/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          // Request JSON response for mobile
          'Accept': 'application/json',
        },
        body: {
          'username': username,
          'password': password,
          'remember': remember.toString(),
        },
      );

      _log.info('Login response status: ${response.statusCode}');
      _log.info('Login response headers: ${response.headers}');
      _log.info('Login response body: ${response.body}');

      if (response.statusCode >= 400) {
        _log.warning('Login failed with status ${response.statusCode}: ${response.body}');
        
        // 提供使用者友好的錯誤訊息
        String errorMessage;
        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = 'Invalid username or password.\n\nStatus: ${response.statusCode}';
        } else if (response.statusCode == 429) {
          errorMessage = 'Too many login attempts.\n\nPlease try again later.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error (${response.statusCode})\n\nLichess server is having issues. Please try again later.';
        } else {
          errorMessage = 'Login failed (Status: ${response.statusCode})\n\n${response.body}';
        }
        
        throw Exception(errorMessage);
      }

      // Cookie is automatically saved by the CookieManager in LichessClient
      // Now fetch user account data
      _log.info('Fetching user account data from /api/account');
      final user = await _client.readJson(
        Uri(path: '/api/account'),
        mapper: User.fromServerJson,
      );

      _log.info('Successfully signed in as ${user.username}');

      return AuthSessionState(user: user.lightUser);
    } on Exception {
      // 重新拋出 Exception（已經有友好訊息）
      rethrow;
    } catch (e, st) {
      _log.severe('Sign in failed: $e', e, st);
      
      // 將其他錯誤包裝成友好的訊息
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Network error\n\nCannot connect to lichess.org\n\nError: ${e.toString()}');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout\n\nServer took too long to respond\n\nError: ${e.toString()}');
      } else {
        throw Exception('Unexpected error\n\n${e.toString()}');
      }
    }
  }

  /// Sign out by calling the /logout endpoint and clearing cookies.
  Future<void> signOut() async {
    _log.info('Signing out');

    try {
      // Call logout endpoint
      await _client.post(Uri(path: '/logout'));

      // Clear all cookies
      final cookieJar = await _ref.read(cookieJarProvider.future);
      await cookieJar.deleteAll();

      _log.info('Successfully signed out');
    } catch (e, st) {
      _log.warning('Sign out error (continuing anyway)', e, st);
      // Still try to clear cookies even if the API call failed
      try {
        final cookieJar = await _ref.read(cookieJarProvider.future);
        await cookieJar.deleteAll();
      } catch (_) {}
    }
  }
}
