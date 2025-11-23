import 'package:lichess_mobile/src/model/auth/auth_repository.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/notifications/notification_service.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/network/socket.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Sign in with username/email and password.
  ///
  /// [username] can be either a username or email address.
  /// [password] is the user's password.
  /// [remember] whether to create a persistent session (default: true).
  Future<void> signIn(String username, String password, {bool remember = true}) async {
    state = const AsyncLoading();

    try {
      final session = await ref.withClient(
        (client) => AuthRepository(client, ref).signIn(username, password, remember: remember)
      );

      await ref.read(authSessionProvider.notifier).update(session);

      // register device and reconnect to the current socket with the new session
      await Future.wait([
        ref.read(notificationServiceProvider).registerDevice(),
        // force reconnect to the current socket with the new cookie-based session
        ref.read(socketPoolProvider).currentClient.connect(),
      ]);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      await ref.read(notificationServiceProvider).unregister();
      await ref.withClient((client) => AuthRepository(client, ref).signOut());
      await ref.read(authSessionProvider.notifier).delete();
      // force reconnect to the current socket
      await ref.read(socketPoolProvider).currentClient.connect();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
