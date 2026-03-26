import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/blind_level.dart';
import 'models/structure.dart';
import 'providers/settings_provider.dart';
import 'providers/tournament_provider.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(BlindLevelAdapter());
  Hive.registerAdapter(StructureAdapter());

  // Init services
  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioService();
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (_) => TournamentProvider(audioService, storageService),
        ),
      ],
      child: const PokerTimerApp(),
    ),
  );
}

class PokerTimerApp extends StatefulWidget {
  const PokerTimerApp({super.key});

  @override
  State<PokerTimerApp> createState() => _PokerTimerAppState();
}

class _PokerTimerAppState extends State<PokerTimerApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      final tournament = context.read<TournamentProvider>();
      tournament.setSoundEnabled(settings.soundEnabled);
      tournament.init(settings.warningSeconds);
      setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Poker Timer',
          debugShowCheckedModeBanner: false,
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: _initialized ? const HomeScreen() : const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}
