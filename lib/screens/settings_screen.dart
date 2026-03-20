import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tournament_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<SettingsProvider, TournamentProvider>(
        builder: (context, settings, tournament, _) {
          return ListView(
            children: [
              _SectionHeader('Timer'),
              SwitchListTile(
                secondary: const Icon(Icons.screen_lock_portrait),
                title: const Text('Keep Screen Awake'),
                subtitle: const Text('Prevent screen from sleeping during timer'),
                value: settings.keepAwake,
                onChanged: settings.setKeepAwake,
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Warning Time'),
                subtitle: Text('Alert at ${settings.warningSeconds} seconds remaining'),
                trailing: DropdownButton<int>(
                  value: settings.warningSeconds,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                    DropdownMenuItem(value: 120, child: Text('2m')),
                    DropdownMenuItem(value: 180, child: Text('3m')),
                    DropdownMenuItem(value: 300, child: Text('5m')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      settings.setWarningSeconds(v);
                      tournament.updateWarningSeconds(v);
                    }
                  },
                ),
              ),

              _SectionHeader('Alerts'),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('Sound'),
                subtitle: const Text('Play sounds at level end and warning'),
                value: settings.soundEnabled,
                onChanged: (v) {
                  settings.setSoundEnabled(v);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate at level transitions'),
                value: settings.vibrationEnabled,
                onChanged: settings.setVibrationEnabled,
              ),

              _SectionHeader('Appearance'),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme throughout the app'),
                value: settings.darkMode,
                onChanged: settings.setDarkMode,
              ),

              _SectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
