import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:lichess_mobile/src/binding.dart';
import 'package:lichess_mobile/src/model/engine/engine.dart';
import 'package:lichess_mobile/src/model/engine/uci_protocol.dart';
import 'package:lichess_mobile/src/model/engine/work.dart';
import 'package:logging/logging.dart';
import 'package:multistockfish/multistockfish.dart';

/// Service to interface with Stockfish engine for computer game move generation.
class ComputerGameEngine {
  ComputerGameEngine() : _log = Logger('ComputerGameEngine');

  final Logger _log;
  StockfishEngine? _engine;
  final UCIProtocol _protocol = UCIProtocol();

  /// Initialize the Stockfish engine for computer games.
  Future<void> initialize() async {
    if (_engine != null) {
      return; // Already initialized
    }

    try {
      _log.info('Initializing Stockfish engine for computer game');
      // Use SF16 flavor for computer games (smaller, no NNUE needed for lower levels)
      _engine = StockfishEngine(StockfishFlavor.sf16);
      
      // Start the engine to ensure it's ready
      await _engine!.start(Work(
        position: Chess.initial,
        initialPositionEval: null,
        variant: Variant.standard,
        multiPv: 1,
      )).first;
      
      _engine!.stop();
      _log.info('Stockfish engine initialized successfully');
    } catch (e, s) {
      _log.severe('Failed to initialize Stockfish engine', e, s);
      rethrow;
    }
  }

  /// Get the best move for the current position at the specified difficulty level.
  /// 
  /// Difficulty levels 1-8 are mapped to Stockfish parameters:
  /// - Level 1-2: Depth 1-3, Skill Level 0-3 (Beginner)
  /// - Level 3-4: Depth 5-8, Skill Level 5-10 (Intermediate)
  /// - Level 5-6: Depth 10-13, Skill Level 12-15 (Advanced)
  /// - Level 7-8: Depth 15-20, Skill Level 17-20 (Expert)
  Future<Move?> getMove(Position position, int level, Variant variant) async {
    if (_engine == null) {
      await initialize();
    }

    if (_engine == null) {
      throw StateError('Engine failed to initialize');
    }

    final (depth, skillLevel) = _getLevelParameters(level);

    _log.info('Getting move at level $level (depth: $depth, skill: $skillLevel)');

    try {
      // Create work for the engine
      final work = Work(
        position: position,
        initialPositionEval: null,
        variant: variant,
        multiPv: 1,
      );

      // Start engine computation with level-specific parameters
      final evalStream = _engine!.start(work);

      // Set UCI options for difficulty
      // Note: Actual UCI option setting would need to be done via engine stdin
      // For now, we'll use depth limiting in the work object

      Move? bestMove;
      int pvCount = 0;

      // Collect eval results up to target depth
      await for (final (_, eval) in evalStream) {
        if (eval.depth >= depth) {
          bestMove = eval.bestMove;
          break;
        }
        pvCount++;
        
        // Safety: stop after reasonable number of updates
        if (pvCount > 100) {
          bestMove = eval.bestMove;
          break;
        }
      }

      _engine!.stop();

      if (bestMove == null) {
        _log.warning('No move found by engine');
      }

      return bestMove;
    } catch (e, s) {
      _log.severe('Error getting move from engine', e, s);
      _engine!.stop();
      return null;
    }
  }

  /// Map difficulty level (1-8) to engine depth and skill level.
  (int depth, int skillLevel) _getLevelParameters(int level) {
    return switch (level) {
      1 => (1, 0),   // Beginner - very weak
      2 => (3, 3),   // Beginner
      3 => (5, 5),   // Novice
      4 => (8, 10),  // Novice/Intermediate
      5 => (10, 12), // Intermediate
      6 => (13, 15), // Advanced
      7 => (15, 17), // Expert
      8 => (20, 20), // Expert - full strength
      _ => (10, 10), // Default to medium
    };
  }

  /// Dispose the engine.
  Future<void> dispose() async {
    if (_engine != null) {
      _log.info('Disposing computer game engine');
      await _engine!.dispose();
      _engine = null;
    }
  }
}
