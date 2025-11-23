import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/settings/preferences_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_preferences.freezed.dart';
part 'game_preferences.g.dart';

/// Local game preferences, defined client-side only.
@Riverpod(keepAlive: true)
class GamePreferences extends _$GamePreferences with PreferencesStorage<GamePrefs> {
  @override
  @protected
  final prefCategory = PrefCategory.game;

  @override
  @protected
  GamePrefs get defaults => GamePrefs.defaults;

  @override
  GamePrefs fromJson(Map<String, dynamic> json) => GamePrefs.fromJson(json);

  @override
  GamePrefs build() {
    return fetch();
  }

  Future<void> toggleChat() {
    final newState = state.copyWith(enableChat: !(state.enableChat ?? false));
    return save(newState);
  }

  Future<void> toggleBlindfoldMode() {
    return save(state.copyWith(blindfoldMode: !(state.blindfoldMode ?? false)));
  }

  Future<void> toggleRealTimeAnalysis() {
    return save(state.copyWith(enableRealTimeAnalysis: !(state.enableRealTimeAnalysis ?? false)));
  }
}

@Freezed(fromJson: true, toJson: true)
sealed class GamePrefs with _$GamePrefs implements Serializable {
  const factory GamePrefs({bool? enableChat, bool? blindfoldMode, bool? enableRealTimeAnalysis}) = _GamePrefs;

  static const defaults = GamePrefs(enableChat: true, enableRealTimeAnalysis: false);

  factory GamePrefs.fromJson(Map<String, dynamic> json) => _$GamePrefsFromJson(json);
}
