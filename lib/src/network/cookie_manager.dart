import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cookie_manager.g.dart';

/// Cookie jar provider for persistent cookie storage
@Riverpod(keepAlive: true)
Future<PersistCookieJar> cookieJar(Ref ref) async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final String appDocPath = appDocDir.path;
  final jar = PersistCookieJar(
    storage: FileStorage('$appDocPath/.cookies/'),
  );
  return jar;
}

/// Cookie manager for HTTP client
class CookieManager {
  CookieManager(this.cookieJar);

  final CookieJar cookieJar;

  /// Get cookies for a specific URI
  Future<List<Cookie>> getCookies(Uri uri) async {
    return await cookieJar.loadForRequest(uri);
  }

  /// Save cookies from response
  Future<void> saveCookies(Uri uri, List<Cookie> cookies) async {
    await cookieJar.saveFromResponse(uri, cookies);
  }

  /// Clear all cookies
  Future<void> clearAll() async {
    await cookieJar.deleteAll();
  }

  /// Get cookie header string for a URI
  Future<String?> getCookieHeader(Uri uri) async {
    final cookies = await getCookies(uri);
    if (cookies.isEmpty) return null;
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }

  /// Parse and save Set-Cookie headers from response
  Future<void> saveFromSetCookieHeader(Uri uri, String? setCookieHeader) async {
    if (setCookieHeader == null || setCookieHeader.isEmpty) return;

    // Set-Cookie header can contain multiple cookies separated by comma
    // But we need to be careful because cookie values can also contain commas
    final cookies = _parseSetCookieHeader(setCookieHeader);
    if (cookies.isNotEmpty) {
      await saveCookies(uri, cookies);
    }
  }

  /// Parse Set-Cookie header value into Cookie objects
  List<Cookie> _parseSetCookieHeader(String setCookieHeader) {
    final List<Cookie> cookies = [];
    try {
      // Try to parse as a single cookie first
      final cookie = Cookie.fromSetCookieValue(setCookieHeader);
      cookies.add(cookie);
    } catch (e) {
      // If that fails, try splitting by comma (simple approach)
      // This may not work for all edge cases but should work for most
      final parts = setCookieHeader.split(',');
      for (final part in parts) {
        try {
          final cookie = Cookie.fromSetCookieValue(part.trim());
          cookies.add(cookie);
        } catch (_) {
          // Skip malformed cookies
        }
      }
    }
    return cookies;
  }
}
