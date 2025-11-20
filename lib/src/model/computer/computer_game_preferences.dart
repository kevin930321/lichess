import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/settings/preferences_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'computer_game_preferences.freezed.dart';
part 'computer_game_preferences.g.dart';

@Riverpod(keepAlive: true)
class ComputerGamePreferences extends _$ComputerGamePreferences
    with SessionPreferencesStorage<ComputerGamePrefs> {
  @override
  @protected
  final prefCategory = PrefCategory.computerGame;

  @override
  ComputerGamePrefs defaults({dynamic user}) => ComputerGamePrefs.defaults;

  @override
  ComputerGamePrefs fromJson(Map<String, dynamic> json) => ComputerGamePrefs.fromJson(json);

  @override
  ComputerGamePrefs build() {
    return fetch();
  }

  Future<void> setLevel(int level) {
    return save(state.copyWith(level: level));
  }

  Future<void> setSide(Side side) {
    return save(state.copyWith(side: side));
  }

  Future<void> setVariant(Variant variant) {
    return save(state.copyWith(variant: variant));
  }
}

@Freezed(fromJson: true, toJson: true)
sealed class ComputerGamePrefs with _$ComputerGamePrefs implements Serializable {
  const ComputerGamePrefs._();

  const factory ComputerGamePrefs({
    required int level,
    required Side side,
    required Variant variant,
  }) = _ComputerGamePrefs;

  static const defaults = ComputerGamePrefs(
    level: 1,
    side: Side.white,
    variant: Variant.standard,
  );

  factory ComputerGamePrefs.fromJson(Map<String, dynamic> json) {
    try {
      return _$ComputerGamePrefsFromJson(json);
    } catch (_) {
      return defaults;
    }
  }
}
