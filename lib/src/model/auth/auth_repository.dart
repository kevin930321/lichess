import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/network/cookie_manager.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

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

      _log.fine('Login response status: ${response.statusCode}');

      if (response.statusCode >= 400) {
        _log.warning('Login failed with status ${response.statusCode}: ${response.body}');
        throw Exception('Login failed: ${response.reasonPhrase}');
      }

      // Cookie is automatically saved by the CookieManager in LichessClient
      // Now fetch user account data
      final user = await _client.readJson(
        Uri(path: '/api/account'),
        mapper: User.fromServerJson,
      );

      _log.info('Successfully signed in as ${user.username}');

      return AuthSessionState(user: user.lightUser);
    } catch (e, st) {
      _log.severe('Sign in failed', e, st);
      rethrow;
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
