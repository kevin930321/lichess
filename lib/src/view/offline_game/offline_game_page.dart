import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/engine/offline_game_service.dart';

class OfflineGamePage extends ConsumerStatefulWidget {
  const OfflineGamePage({super.key});

  static Route buildRoute(BuildContext context) {
    return MaterialPageRoute(builder: (context) => const OfflineGamePage());
  }

  @override
  ConsumerState<OfflineGamePage> createState() => _OfflineGamePageState();
}

class _OfflineGamePageState extends ConsumerState<OfflineGamePage> {
  double _difficulty = 4.0;
  d.Position? _game;

  @override
  void initState() {
    super.initState();
    // Start a new game immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewGame();
    });
  }

  void _startNewGame() {
    final service = ref.read(offlineGameServiceProvider);
    service.newGame();
    service.setDifficulty(_difficulty.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(offlineGameServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline vs Computer'),
      ),
      body: StreamBuilder<d.Position>(
        stream: service.gameStream,
        builder: (context, snapshot) {
          _game = snapshot.data;
          final game = _game;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: game == null
                        ? const CircularProgressIndicator()
                        : ValueListenableBuilder<bool>(
                            valueListenable: service.isComputerThinking,
                            builder: (context, isThinking, child) {
                              return Chessboard(
                                fen: game.fen,
                                orientation: d.Side.white,
                                game: GameData(
                                  playerSide: isThinking
                                      ? PlayerSide.none
                                      : PlayerSide.white,
                                  validMoves: game.legalMoves,
                                  sideToMove: game.turn,
                                  isCheck: game.isCheck,
                                  onMove: (move) {
                                    if (isThinking) return;
                                    final uci =
                                        '${move.from.name}${move.to.name}${move.promotion?.name ?? ''}';
                                    service.makeMove(uci);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Difficulty: ${_difficulty.toInt()}'),
                    Slider(
                      value: _difficulty,
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: _difficulty.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value;
                        });
                        service.setDifficulty(_difficulty.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: service.isComputerThinking,
                      builder: (context, isThinking, child) {
                        if (isThinking) {
                          return const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Computer is thinking...'),
                            ],
                          );
                        }
                        if (game?.isGameOver ?? false) {
                           return Text('Game Over: ${game?.outcome?.toString() ?? ""}');
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startNewGame,
                      child: const Text('New Game'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}