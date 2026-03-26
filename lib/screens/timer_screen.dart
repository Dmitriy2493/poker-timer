import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/blind_level.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    final settings = context.read<SettingsProvider>();
    if (settings.keepAwake) WakelockPlus.enable();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WakelockPlus.disable();
    super.dispose();
  }

  void _goBack(TournamentProvider provider) {
    provider.stop();
    Navigator.pop(context);
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
    final isLandscape = size.width > size.height;
    final shortSide = min(size.width, size.height);
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

          final remaining = provider.state.remainingSeconds;
          final isRunning = provider.state.status == TimerStatus.running;
          final isWarning = remaining <= 60 && isRunning;
          if (isLandscape) {
            return _buildLandscapeLayout(context, provider, level, isWarning, scale);
          }
          return _buildPortraitLayout(context, provider, level, isWarning, scale);
        },
      ),
    );
  }

  Widget _buildTimerDisplay(TournamentProvider provider, bool isWarning, double fontSize, double scale) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        color: isWarning ? Colors.red[400]! : Colors.white,
        fontSize: fontSize * scale,
        fontWeight: FontWeight.w200,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child: Text(provider.formattedTime),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    TournamentProvider provider,
    BlindLevel level,
    bool isWarning,
    double scale,
  ) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < -200) {
                  provider.nextLevel();
                } else if (details.primaryVelocity! > 200) {
                  provider.previousLevel();
                }
              },
              child: Column(
                children: [
                  // Top bar with back button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                    child: Row(
                      children: [
                        IconButton(
                          iconSize: 22 * scale,
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
                          onPressed: () => _goBack(provider),
                        ),
                        Expanded(
                          child: Text(
                            level.isBreak
                                ? 'Break'
                                : 'Level ${provider.state.currentLevelIndex + 1}, ${formatChips(level.smallBlind)}/${formatChips(level.bigBlind)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isWarning ? Colors.red[300] : Colors.white70,
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 40 * scale),
                      ],
                    ),
                  ),

                  // Timer
                  Expanded(
                    child: Center(
                      child: _buildTimerDisplay(provider, isWarning, 120, scale),
                    ),
                  ),

                  // Progress bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40 * scale),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4 * scale),
                      child: LinearProgressIndicator(
                        value: provider.levelProgress,
                        minHeight: 6 * scale,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWarning ? Colors.red[400]! : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  _ControlsBar(provider: provider, scale: scale, onNewGame: () => _confirmNewGame(context, provider)),
                  SizedBox(height: 8 * scale),
                ],
              ),
            ),
          ),

          // Next Levels panel
          Container(
            width: 200 * scale,
            margin: EdgeInsets.symmetric(vertical: 12 * scale, horizontal: 8 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: _NextLevelsPanel(provider: provider, scale: scale),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    TournamentProvider provider,
    BlindLevel level,
    bool isWarning,
    double scale,
  ) {
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
            // Top bar with back button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 4 * scale),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 22 * scale,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
                    onPressed: () => _goBack(provider),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Level + blinds
            Text(
              level.isBreak
                  ? 'Break'
                  : 'Level ${provider.state.currentLevelIndex + 1}, ${formatChips(level.smallBlind)}/${formatChips(level.bigBlind)}',
              style: TextStyle(
                color: isWarning ? Colors.red[300] : Colors.white70,
                fontSize: 18 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Timer
            Expanded(
              flex: 3,
              child: Center(
                child: _buildTimerDisplay(provider, isWarning, 96, scale),
              ),
            ),

            // Progress bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40 * scale),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4 * scale),
                child: LinearProgressIndicator(
                  value: provider.levelProgress,
                  minHeight: 6 * scale,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWarning ? Colors.red[400]! : Colors.white38,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24 * scale),

            // Next levels
            Expanded(
              flex: 2,
              child: _NextLevelsPanel(provider: provider, scale: scale),
            ),

            _ControlsBar(provider: provider, scale: scale, onNewGame: () => _confirmNewGame(context, provider)),
            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }
}

class _NextLevelsPanel extends StatelessWidget {
  final TournamentProvider provider;
  final double scale;

  const _NextLevelsPanel({required this.provider, required this.scale});

  @override
  Widget build(BuildContext context) {
    final levels = provider.activeStructure?.levels ?? [];
    final currentIdx = provider.state.currentLevelIndex;
    final upcoming = <MapEntry<int, BlindLevel>>[];
    for (int i = currentIdx + 1; i < levels.length && upcoming.length < 3; i++) {
      upcoming.add(MapEntry(i, levels[i]));
    }

    if (upcoming.isEmpty) {
      return Center(
        child: Text('Final Level', style: TextStyle(color: Colors.white38, fontSize: 14 * scale)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Text(
            'Next Levels',
            style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.w600),
          ),
        ),
        ...upcoming.map((entry) {
          final idx = entry.key;
          final level = entry.value;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.white24, size: 14 * scale),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.isBreak ? 'Break' : 'Level ${idx + 1}',
                        style: TextStyle(color: Colors.white70, fontSize: 14 * scale, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        level.isBreak
                            ? '${level.durationMinutes}m'
                            : '${formatChips(level.smallBlind)}/${formatChips(level.bigBlind)}, ${level.durationMinutes}m',
                        style: TextStyle(color: Colors.white38, fontSize: 13 * scale),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final TournamentProvider provider;
  final double scale;
  final VoidCallback onNewGame;

  const _ControlsBar({
    required this.provider,
    required this.scale,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = provider.state.status == TimerStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous level (skip backward)
        IconButton(
          iconSize: 28 * scale,
          icon: const Icon(Icons.skip_previous, color: Colors.white54),
          onPressed: provider.state.currentLevelIndex > 0 ? provider.previousLevel : null,
        ),
        SizedBox(width: 8 * scale),

        // Play / Pause
        IconButton(
          iconSize: 36 * scale,
          icon: Icon(
            isRunning ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: isRunning ? provider.pause : provider.start,
        ),
        SizedBox(width: 8 * scale),

        // Next level (skip forward)
        IconButton(
          iconSize: 28 * scale,
          icon: const Icon(Icons.skip_next, color: Colors.white54),
          onPressed: !provider.isLastLevel ? provider.nextLevel : null,
        ),
        SizedBox(width: 16 * scale),

        // Reset / New game
        IconButton(
          iconSize: 24 * scale,
          icon: const Icon(Icons.refresh, color: Colors.white38),
          tooltip: 'New Game',
          onPressed: onNewGame,
        ),
      ],
    );
  }
}
