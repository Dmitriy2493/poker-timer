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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          final level = provider.currentLevel;
          if (level == null) {
            return const Center(child: Text('No structure selected', style: TextStyle(color: Colors.white)));
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
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
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 48),
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
                            fontSize: 14,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Blinds display
                        if (!level.isBreak) ...[
                          Text(
                            '${formatChips(level.smallBlind)} / ${formatChips(level.bigBlind)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          if (level.ante > 0)
                            Text(
                              'Ante: ${formatChips(level.ante)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                              ),
                            ),
                        ] else
                          Text(
                            level.label ?? 'BREAK',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Timer
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isWarning ? Colors.red[400]! : Colors.white,
                            fontSize: 96,
                            fontWeight: FontWeight.w200,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          child: Text(provider.formattedTime),
                        ),

                        const SizedBox(height: 16),

                        // Progress bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: provider.levelProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isWarning ? Colors.red[400]! : Colors.white38,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Next level preview
                        if (provider.peekNextLevel != null)
                          _NextLevelPreview(provider: provider),
                      ],
                    ),
                  ),

                  // Controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _TimerControls(provider: provider),
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

  const _NextLevelPreview({required this.provider});

  @override
  Widget build(BuildContext context) {
    final next = provider.peekNextLevel!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Next: ', style: TextStyle(color: Colors.white38, fontSize: 14)),
          Text(
            next.isBreak
                ? (next.label ?? 'Break')
                : '${formatChips(next.smallBlind)} / ${formatChips(next.bigBlind)}',
            style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Text(' • ', style: TextStyle(color: Colors.white24)),
          Text(
            '${next.durationMinutes}m',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  final TournamentProvider provider;

  const _TimerControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isRunning = provider.state.status == TimerStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_previous, color: Colors.white38),
          onPressed: provider.state.currentLevelIndex > 0
              ? () => provider.previousLevel()
              : null,
        ),
        const SizedBox(width: 16),

        // Play / Pause
        GestureDetector(
          onTap: isRunning ? provider.pause : provider.start,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              size: 44,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_next, color: Colors.white38),
          onPressed: !provider.isLastLevel
              ? () => provider.nextLevel()
              : null,
        ),
      ],
    );
  }
}
