import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/tournament_state.dart';
import '../providers/tournament_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final settings = context.read<SettingsProvider>();
    if (settings.keepAwake) WakelockPlus.enable();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  void _confirmNewGame(BuildContext context, TournamentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Game'),
        content: const Text('Reset blinds to Level 1 and start a new game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.stop();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortSide = min(size.width, size.height);
    // Scale factor: 1.0 for phones (~360dp), up to ~2.5 for large tablets (~900dp)
    final scale = (shortSide / 360).clamp(1.0, 2.5);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          final level = provider.currentLevel;
          if (level == null) {
            return Center(
              child: Text(
                'No structure selected',
                style: TextStyle(color: Colors.white, fontSize: 16 * scale),
              ),
            );
          }

          final isWarning = provider.state.remainingSeconds <= 60 &&
              provider.state.status == TimerStatus.running;

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -200) {
                provider.nextLevel();
              } else if (details.primaryVelocity! > 200) {
                provider.previousLevel();
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    child: Row(
                      children: [
                        IconButton(
                          iconSize: 24 * scale,
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          onPressed: () {
                            provider.stop();
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            provider.activeStructure?.name ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 16 * scale),
                          ),
                        ),
                        SizedBox(width: 48 * scale),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Level indicator
                        Text(
                          'LEVEL ${provider.state.currentLevelIndex + 1}',
                          style: TextStyle(
                            color: isWarning ? Colors.red[300] : Colors.white38,
                            fontSize: 14 * scale,
                            letterSpacing: 3 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8 * scale),

                        // Blinds display
                        if (!level.isBreak) ...[
                          Text(
                            '${formatChips(level.smallBlind)} / ${formatChips(level.bigBlind)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48 * scale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2 * scale,
                            ),
                          ),
                          if (level.ante > 0)
                            Text(
                              'Ante: ${formatChips(level.ante)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18 * scale,
                              ),
                            ),
                        ] else
                          Text(
                            level.label ?? 'BREAK',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 40 * scale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4 * scale,
                            ),
                          ),

                        SizedBox(height: 32 * scale),

                        // Timer
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isWarning ? Colors.red[400]! : Colors.white,
                            fontSize: 96 * scale,
                            fontWeight: FontWeight.w200,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          child: Text(provider.formattedTime),
                        ),

                        SizedBox(height: 16 * scale),

                        // Progress bar
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 48 * scale),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2 * scale),
                            child: LinearProgressIndicator(
                              value: provider.levelProgress,
                              minHeight: 4 * scale,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isWarning ? Colors.red[400]! : Colors.white38,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 48 * scale),

                        // Next level preview
                        if (provider.peekNextLevel != null)
                          _NextLevelPreview(provider: provider, scale: scale),
                      ],
                    ),
                  ),

                  // Controls
                  Padding(
                    padding: EdgeInsets.only(bottom: 40 * scale),
                    child: _TimerControls(provider: provider, scale: scale),
                  ),

                  // Bottom toolbar
                  Padding(
                    padding: EdgeInsets.only(bottom: 16 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 24 * scale,
                          icon: const Icon(Icons.refresh, color: Colors.white38),
                          tooltip: 'New Game',
                          onPressed: () => _confirmNewGame(context, provider),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NextLevelPreview extends StatelessWidget {
  final TournamentProvider provider;
  final double scale;

  const _NextLevelPreview({required this.provider, required this.scale});

  @override
  Widget build(BuildContext context) {
    final next = provider.peekNextLevel!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Next: ', style: TextStyle(color: Colors.white38, fontSize: 14 * scale)),
          Text(
            next.isBreak
                ? (next.label ?? 'Break')
                : '${formatChips(next.smallBlind)} / ${formatChips(next.bigBlind)}',
            style: TextStyle(color: Colors.white60, fontSize: 14 * scale, fontWeight: FontWeight.w600),
          ),
          Text(' • ', style: TextStyle(color: Colors.white24, fontSize: 14 * scale)),
          Text(
            '${next.durationMinutes}m',
            style: TextStyle(color: Colors.white38, fontSize: 14 * scale),
          ),
        ],
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  final TournamentProvider provider;
  final double scale;

  const _TimerControls({required this.provider, required this.scale});

  @override
  Widget build(BuildContext context) {
    final isRunning = provider.state.status == TimerStatus.running;
    final buttonSize = 80 * scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        IconButton(
          iconSize: 36 * scale,
          icon: const Icon(Icons.skip_previous, color: Colors.white38),
          onPressed: provider.state.currentLevelIndex > 0
              ? () => provider.previousLevel()
              : null,
        ),
        SizedBox(width: 16 * scale),

        // Play / Pause
        GestureDetector(
          onTap: isRunning ? provider.pause : provider.start,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20 * scale,
                  spreadRadius: 2 * scale,
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              size: 44 * scale,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: 16 * scale),

        // Next
        IconButton(
          iconSize: 36 * scale,
          icon: const Icon(Icons.skip_next, color: Colors.white38),
          onPressed: !provider.isLastLevel
              ? () => provider.nextLevel()
              : null,
        ),
      ],
    );
  }
}
