import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartchess/dartchess.dart' as d;
import 'package:lichess_mobile/src/model/engine/engine.dart';
import 'package:multistockfish/multistockfish.dart';

final offlineGameServiceProvider = Provider((ref) {
  final service = OfflineGameService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class OfflineGameService {
  final Ref _ref;
  StockfishEngine? _engine;
  d.Position? _game;
  final _gameController = StreamController<d.Position>.broadcast();

  ValueNotifier<bool> isComputerThinking = ValueNotifier(false);

  OfflineGameService(this._ref) {
    _engine = StockfishEngine(StockfishFlavor.sf16);
  }

  Stream<d.Position> get gameStream => _gameController.stream;

  void newGame() {
    _engine?.ensureInitialized();
    _game = d.Position.initial();
    _gameController.add(_game!);
  }

  Future<void> setDifficulty(int level) async {
    if (_engine == null) return;
    // Stockfish skill level is 0-20. Map 1-8 to this range.
    final skillLevel = ((level - 1) / 7 * 20).round();
    _engine!.setOption('Skill Level', skillLevel.toString());
  }

  Future<void> makeMove(String uciMove) async {
    if (_game == null || isComputerThinking.value) return;

    final move = d.Move.fromUci(uciMove);
    if (_game!.isLegal(move)) {
      _game = _game!.play(move);
      _gameController.add(_game!);
      
      if (!_game!.isGameOver) {
        isComputerThinking.value = true;
        await _askComputerToMove();
        isComputerThinking.value = false;
      }
    }
  }

  Future<void> _askComputerToMove() async {
    if (_game == null || _engine == null) return;
    
    final bestMoveUci = await _engine!.getBestMove(
      _game!.fen,
      const Duration(seconds: 2), // Give the engine 2 seconds to think
    );

    if (bestMoveUci.isNotEmpty) {
      final move = d.Move.fromUci(bestMoveUci);
      if (_game!.isLegal(move)) {
        _game = _game!.play(move);
        _gameController.add(_game!);
      }
    }
  }

  void dispose() {
    _engine?.dispose();
    _gameController.close();
    isComputerThinking.dispose();
  }
}
