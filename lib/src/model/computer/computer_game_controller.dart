import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/common/service/move_feedback.dart';
import 'package:lichess_mobile/src/model/common/speed.dart';
import 'package:lichess_mobile/src/model/computer/computer_game_engine.dart';
import 'package:lichess_mobile/src/model/game/game.dart';
import 'package:lichess_mobile/src/model/game/game_status.dart';
import 'package:lichess_mobile/src/model/game/material_diff.dart';
import 'package:lichess_mobile/src/model/game/over_the_board_game.dart';
import 'package:lichess_mobile/src/model/game/player.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'computer_game_controller.freezed.dart';
part 'computer_game_controller.g.dart';

@riverpod
class ComputerGameController extends _$ComputerGameController {
  ComputerGameEngine? _engine;

  @override
  ComputerGameState build() {
    ref.onDispose(() {
      _engine?.dispose();
      _engine = null;
    });

    return ComputerGameState.initial();
  }

  /// Start a new game against the computer.
  Future<void> startNewGame({
    required int level,
    required Side playerSide,
    required Variant variant,
  }) async {
    // Initialize engine if needed
    _engine ??= ComputerGameEngine();
    await _engine!.initialize();

    final initialPosition = variant == Variant.chess960
        ? randomChess960Position()
        : variant.initialPosition;

    final game = OverTheBoardGame(
      steps: [GameStep(position: initialPosition)].lock,
      status: GameStatus.started,
      initialFen: initialPosition.fen,
      meta: GameMeta(
        createdAt: DateTime.now(),
        rated: false,
        variant: variant,
        speed: Speed.correspondence, // Use correspondence for untimed games
        perf: Perf.fromVariantAndSpeed(variant, Speed.correspondence),
      ),
      // Set white and black players with AI level for opponent
      white: playerSide == Side.white
          ? const Player()
          : Player(aiLevel: level, name: 'Stockfish'),
      black: playerSide == Side.black
          ? const Player()
          : Player(aiLevel: level, name: 'Stockfish'),
    );

    state = ComputerGameState(
      game: game,
      stepCursor: 0,
      engineLevel: level,
      playerSide: playerSide,
      isEngineThinking: false,
      promotionMove: null,
    );

    // If engine plays first (player is black), make the engine move
    if (playerSide == Side.black) {
      await _makeEngineMove();
    }
  }

  /// Make a move for the player.
  Future<void> makePlayerMove(NormalMove move) async {
    if (state.isEngineThinking) {
      return; // Don't allow moves while engine is thinking
    }

    if (state.currentPosition.turn != state.playerSide) {
      return; // Not player's turn
    }

    if (isPromotionPawnMove(state.currentPosition, move)) {
      state = state.copyWith(promotionMove: move);
      return;
    }

    _executeMove(move);

    // After player move, check if game is finished
    if (!state.finished) {
      // Make engine move
      await _makeEngineMove();
    }
  }

  /// Handle promotion piece selection.
  Future<void> onPromotionSelection(Role? role) async {
    if (role == null) {
      state = state.copyWith(promotionMove: null);
      return;
    }

    final promotionMove = state.promotionMove;
    if (promotionMove != null) {
      final move = promotionMove.withPromotion(role);
      state = state.copyWith(promotionMove: null);
      _executeMove(move);

      // After player move, check if game is finished
      if (!state.finished) {
        // Make engine move
        await _makeEngineMove();
      }
    }
  }

  /// Execute a move on the board.
  void _executeMove(NormalMove move) {
    final (newPos, newSan) = state.currentPosition.makeSan(Move.parse(move.uci)!);
    final sanMove = SanMove(newSan, move);
    final newStep = GameStep(
      position: newPos,
      sanMove: sanMove,
      diff: MaterialDiff.fromBoard(newPos.board),
    );

    // Support implicit takebacks like over-the-board mode
    state = state.copyWith(
      game: state.game.copyWith(
        steps: state.game.steps
            .removeRange(state.stepCursor + 1, state.game.steps.length)
            .add(newStep),
      ),
      stepCursor: state.stepCursor + 1,
    );

    // Check for threefold repetition
    if (state.game.steps.count((p) => p.position.board == newStep.position.board) == 3) {
      state = state.copyWith(game: state.game.copyWith(isThreefoldRepetition: true));
    } else {
      state = state.copyWith(game: state.game.copyWith(isThreefoldRepetition: false));
    }

    // Check for game end conditions
    if (state.currentPosition.isCheckmate) {
      state = state.copyWith(
        game: state.game.copyWith(
          status: GameStatus.mate,
          winner: state.turn.opposite,
        ),
      );
    } else if (state.currentPosition.isStalemate) {
      state = state.copyWith(game: state.game.copyWith(status: GameStatus.stalemate));
    }

    _moveFeedback(sanMove);
  }

  /// Make a move for the engine.
  Future<void> _makeEngineMove() async {
    if (state.finished) {
      return;
    }

    if (state.currentPosition.turn == state.playerSide) {
      return; // Not engine's turn
    }

    state = state.copyWith(isEngineThinking: true);

    try {
      final move = await _engine?.getMove(
        state.currentPosition,
        state.engineLevel,
        state.game.meta.variant,
      );

      if (move != null && !state.finished) {
        // Small delay to make it feel more natural
        await Future.delayed(const Duration(milliseconds: 300));
        _executeMove(NormalMove.fromUci(move.uci)!);
      }
    } finally {
      if (state.isEngineThinking) {
        state = state.copyWith(isEngineThinking: false);
      }
    }
  }

  /// Resign the game.
  void resign() {
    state = state.copyWith(
      game: state.game.copyWith(
        status: GameStatus.resign,
        winner: state.playerSide.opposite,
      ),
    );
  }

  /// Offer/accept draw.
  void draw() {
    state = state.copyWith(game: state.game.copyWith(status: GameStatus.draw));
  }

  /// Navigate forward through moves.
  void goForward() {
    if (state.canGoForward) {
      state = state.copyWith(stepCursor: state.stepCursor + 1, promotionMove: null);
    }
  }

  /// Navigate backward through moves.
  void goBack() {
    if (state.canGoBack) {
      state = state.copyWith(stepCursor: state.stepCursor - 1, promotionMove: null);
    }
  }

  void _moveFeedback(SanMove sanMove) {
    final isCheck = sanMove.san.contains('+');
    if (sanMove.san.contains('x')) {
      ref.read(moveFeedbackServiceProvider).captureFeedback(check: isCheck);
    } else {
      ref.read(moveFeedbackServiceProvider).moveFeedback(check: isCheck);
    }
  }
}

@freezed
class ComputerGameState with _$ComputerGameState {
  const ComputerGameState._();

  const factory ComputerGameState({
    required OverTheBoardGame game,
    @Default(0) int stepCursor,
    required int engineLevel,
    required Side playerSide,
    @Default(false) bool isEngineThinking,
    @Default(null) NormalMove? promotionMove,
  }) = _ComputerGameState;

  factory ComputerGameState.initial() => ComputerGameState(
        game: OverTheBoardGame(
          steps: [GameStep(position: Chess.initial)].lock,
          status: GameStatus.started,
          initialFen: Chess.initial.fen,
          meta: GameMeta(
            createdAt: DateTime.now(),
            rated: false,
            variant: Variant.standard,
            speed: Speed.correspondence,
            perf: Perf.standard,
          ),
        ),
        stepCursor: 0,
        engineLevel: 1,
        playerSide: Side.white,
        isEngineThinking: false,
      );

  Position get currentPosition => game.stepAt(stepCursor).position;
  Side get turn => currentPosition.turn;
  bool get finished => game.finished;
  NormalMove? get lastMove =>
      stepCursor > 0 ? NormalMove.fromUci(game.steps[stepCursor].sanMove!.move.uci) : null;

  MaterialDiffSide? currentMaterialDiff(Side side) {
    return game.steps[stepCursor].diff?.bySide(side);
  }

  List<String> get moves => game.steps.skip(1).map((e) => e.sanMove!.san).toList(growable: false);

  bool get canGoForward => stepCursor < game.steps.length - 1;
  bool get canGoBack => stepCursor > 0;
}
