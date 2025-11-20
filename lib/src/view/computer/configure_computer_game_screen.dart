import 'package:dartchess/dartchess.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/computer/computer_game_preferences.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/view/computer/computer_game_screen.dart';
import 'package:lichess_mobile/src/widgets/adaptive_choice_picker.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';

/// Screen to configure a new computer game.
class ConfigureComputerGameScreen extends StatelessWidget {
  const ConfigureComputerGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _buildAndroid,
      iosBuilder: _buildIos,
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play vs Computer'),
      ),
      body: const _ConfigureBody(),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Play vs Computer'),
      ),
      child: const _ConfigureBody(),
    );
  }
}

class _ConfigureBody extends ConsumerWidget {
  const _ConfigureBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(computerGamePreferencesProvider);
    final level = prefs.level;
    final side = prefs.side;
    final variant = prefs.variant;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            _buildLevelSelector(context, ref, level),
            const SizedBox(height: 24.0),
            _buildSideSelector(context, ref, side),
            const SizedBox(height: 24.0),
            _buildVariantSelector(context, ref, variant),
            const Spacer(),
            FatButton(
              semanticsLabel: 'Start Game',
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => ComputerGameScreen(
                      level: level,
                      playerSide: side,
                      variant: variant,
                    ),
                  ),
                );
              },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector(BuildContext context, WidgetRef ref, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textShade(context, 0.7),
          ),
        ),
        const SizedBox(height: 12.0),
        OutlinedButton(
          onPressed: () {
            showChoicePicker(
              context,
              title: const Text('Select Difficulty'),
              choices: List.generate(8, (index) => index + 1),
              selectedItem: level,
              labelBuilder: (int lvl) => Text(_getLevelLabel(lvl)),
              onSelectedItemChanged: (int newLevel) {
                ref.read(computerGamePreferencesProvider.notifier).setLevel(newLevel);
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_getLevelLabel(level)),
              Text(
                'Level $level',
                style: TextStyle(
                  color: textShade(context, 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideSelector(BuildContext context, WidgetRef ref, Side side) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Play as',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textShade(context, 0.7),
          ),
        ),
        const SizedBox(height: 12.0),
        OutlinedButton(
          onPressed: () {
            showChoicePicker(
              context,
              title: const Text('Choose Side'),
              choices: [Side.white, Side.black],
              selectedItem: side,
              labelBuilder: (Side s) => Text(s == Side.white ? 'White' : 'Black'),
              onSelectedItemChanged: (Side newSide) {
                ref.read(computerGamePreferencesProvider.notifier).setSide(newSide);
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    side == Side.white ? Icons.circle_outlined : Icons.circle,
                    size: 20,
                    color: side == Side.white ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(side == Side.white ? 'White' : 'Black'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSelector(BuildContext context, WidgetRef ref, Variant variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.variant,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textShade(context, 0.7),
          ),
        ),
        const SizedBox(height: 12.0),
        OutlinedButton(
          onPressed: () {
            showChoicePicker(
              context,
              title: Text(context.l10n.variant),
              choices: [Variant.standard, Variant.chess960],
              selectedItem: variant,
              labelBuilder: (Variant v) => Text(v.label),
              onSelectedItemChanged: (Variant newVariant) {
                ref.read(computerGamePreferencesProvider.notifier).setVariant(newVariant);
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(variant.label),
              if (variant != Variant.standard) Icon(variant.icon),
            ],
          ),
        ),
      ],
    );
  }

  String _getLevelLabel(int level) {
    return switch (level) {
      1 => '初學者 (Beginner)',
      2 => '初學者+ (Beginner+)',
      3 => '新手 (Novice)',
      4 => '新手+ (Novice+)',
      5 => '中級 (Intermediate)',
      6 => '進階 (Advanced)',
      7 => '專家 (Expert)',
      8 => '大師 (Master)',
      _ => 'Level $level',
    };
  }
}
