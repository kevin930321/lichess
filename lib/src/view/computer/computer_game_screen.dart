import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/analysis/analysis_controller.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/computer/computer_game_controller.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:lichess_mobile/src/utils/immersive_mode.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/view/analysis/analysis_screen.dart';
import 'package:lichess_mobile/src/view/game/game_player.dart';
import 'package:lichess_mobile/src/view/game/game_result_dialog.dart';
import 'package:lichess_mobile/src/widgets/adaptive_action_sheet.dart';
import 'package:lichess_mobile/src/widgets/bottom_bar.dart';
import 'package:lichess_mobile/src/widgets/game_layout.dart';
import 'package:lichess_mobile/src/widgets/yes_no_dialog.dart';

/// Screen for playing against the computer (Stockfish engine).
class ComputerGameScreen extends ConsumerStatefulWidget {
  const ComputerGameScreen({
    required this.level,
    required this.playerSide,
    required this.variant,
    super.key,
  });

  final int level;
  final Side playerSide;
  final Variant variant;

  @override
  ConsumerState<ComputerGameScreen> createState() => _ComputerGameScreenState();
}

class _ComputerGameScreenState extends ConsumerState<ComputerGameScreen> {
  final _boardKey = GlobalKey(debugLabel: 'boardOnComputerGameScreen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(computerGameControllerProvider.notifier).startNewGame(
            level: widget.level,
            playerSide: widget.playerSide,
            variant: widget.variant,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(computerGameControllerProvider);

    ref.listen(computerGameControllerProvider, (previous, newGameState) {
      if (previous?.finished == false && newGameState.finished) {
        Timer(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            showAdaptiveDialog<void>(
              context: context,
              builder: (context) => ComputerGameResultDialog(
                game: newGameState.game,
                onRematch: () {
                  Navigator.pop(context);
                  ref.read(computerGameControllerProvider.notifier).startNewGame(
                        level: widget.level,
                        playerSide: widget.playerSide,
                        variant: widget.variant,
                      );
                },
              ),
              barrierDismissible: true,
            );
          }
        });
      }

      if (previous?.game.isThreefoldRepetition == false &&
          newGameState.game.isThreefoldRepetition == true) {
        Timer(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            showAdaptiveDialog<void>(
              context: context,
              builder: (context) => YesNoDialog(
                title: Text(context.l10n.threefoldRepetition),
                content: const Text('Accept draw?'),
                onYes: () {
                  Navigator.pop(context);
                  ref.read(computerGameControllerProvider.notifier).draw();
                },
                onNo: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
        });
      }
    });

    return WakelockWidget(
      child: Scaffold(
        appBar: AppBar(
          title: Text('vs Stockfish (Level ${widget.level})'),
          actions: [
            if (gameState.isEngineThinking)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) {
              return;
            }

            final navigator = Navigator.of(context);
            final game = gameState.game;
            if (game.abortable) {
              return navigator.pop();
            }

            if (game.playable) {
              final shouldPop = await showAdaptiveDialog<bool>(
                context: context,
                builder: (context) {
                  return YesNoDialog(
                    title: Text(context.l10n.mobileAreYouSure),
                    content: const Text('Your game will be lost.'),
                    onNo: () => Navigator.of(context).pop(false),
                    onYes: () => Navigator.of(context).pop(true),
                  );
                },
              );
              if (shouldPop == true) {
                navigator.pop();
              }
            } else {
              navigator.pop();
            }
          },
          child: SafeArea(
            child: GameLayout(
              key: _boardKey,
              topTable: _Player(
                side: widget.playerSide.opposite,
                isAI: true,
                level: widget.level,
              ),
              bottomTable: _Player(
                side: widget.playerSide,
                isAI: false,
              ),
              orientation: widget.playerSide,
              fen: gameState.currentPosition.fen,
              lastMove: gameState.lastMove,
              interactiveBoardParams: (
                variant: gameState.game.meta.variant,
                position: gameState.currentPosition,
                playerSide: gameState.game.finished
                    ? PlayerSide.none
                    : gameState.playerSide == Side.white
                        ? PlayerSide.white
                        : PlayerSide.black,
                onPromotionSelection:
                    ref.read(computerGameControllerProvider.notifier).onPromotionSelection,
                promotionMove: gameState.promotionMove,
                onMove: (move, {isDrop}) {
                  if (!gameState.isEngineThinking) {
                    ref.read(computerGameControllerProvider.notifier).makePlayerMove(move);
                  }
                },
                premovable: null,
              ),
              moves: gameState.moves,
              currentMoveIndex: gameState.stepCursor,
              userActionsBar: _BottomBar(level: widget.level),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.level});

  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(computerGameControllerProvider);

    return BottomBar(
      children: [
        BottomBarButton(
          label: context.l10n.menu,
          onTap: () {
            _showGameMenu(context, ref);
          },
          icon: Icons.menu,
        ),
        BottomBarButton(
          label: 'Previous',
          onTap: gameState.canGoBack && !gameState.isEngineThinking
              ? () {
                  ref.read(computerGameControllerProvider.notifier).goBack();
                }
              : null,
          icon: CupertinoIcons.chevron_back,
        ),
        BottomBarButton(
          label: 'Next',
          onTap: gameState.canGoForward && !gameState.isEngineThinking
              ? () {
                  ref.read(computerGameControllerProvider.notifier).goForward();
                }
              : null,
          icon: CupertinoIcons.chevron_forward,
        ),
      ],
    );
  }

  Future<void> _showGameMenu(BuildContext context, WidgetRef ref) {
    final gameState = ref.read(computerGameControllerProvider);
    return showAdaptiveActionSheet(
      context: context,
      actions: [
        if (gameState.game.finished)
          BottomSheetAction(
            makeLabel: (context) => Text(context.l10n.analysis),
            onPressed: () => Navigator.of(context).push(
              AnalysisScreen.buildRoute(
                context,
                AnalysisOptions.standalone(
                  orientation: Side.white,
                  pgn: gameState.game.makePgn(),
                  isComputerAnalysisAllowed: true,
                  variant: gameState.game.meta.variant,
                ),
              ),
            ),
          ),
        if (gameState.game.drawable)
          BottomSheetAction(
            makeLabel: (context) => Text(context.l10n.offerDraw),
            onPressed: () {
              showAdaptiveDialog<void>(
                context: context,
                builder: (context) => YesNoDialog(
                  title: Text('${context.l10n.draw}?'),
                  content: const Text('Offer draw to computer?'),
                  onYes: () {
                    Navigator.pop(context);
                    ref.read(computerGameControllerProvider.notifier).draw();
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
          ),
        if (gameState.game.resignable)
          BottomSheetAction(
            makeLabel: (context) => Text(context.l10n.resign),
            onPressed: () {
              showAdaptiveDialog<void>(
                context: context,
                builder: (context) => YesNoDialog(
                  title: Text('${context.l10n.resign}?'),
                  content: const Text('Are you sure you want to resign?'),
                  onYes: () {
                    Navigator.pop(context);
                    ref.read(computerGameControllerProvider.notifier).resign();
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({
    required this.side,
    required this.isAI,
    this.level,
  });

  final Side side;
  final bool isAI;
  final int? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(computerGameControllerProvider);
    final boardPreferences = ref.watch(boardPreferencesProvider);

    return GamePlayer(
      game: gameState.game,
      side: side,
      materialDiff: boardPreferences.materialDifferenceFormat.visible
          ? gameState.currentMaterialDiff(side)
          : null,
      materialDifferenceFormat: boardPreferences.materialDifferenceFormat,
      shouldLinkToUserProfile: false,
    );
  }
}

/// Game result dialog for computer games.
class ComputerGameResultDialog extends StatelessWidget {
  const ComputerGameResultDialog({
    required this.game,
    required this.onRematch,
    super.key,
  });

  final dynamic game; // OverTheBoardGame
  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    return GameResultDialog(
      game: game,
      onRematchRequest: onRematch,
    );
  }
}
