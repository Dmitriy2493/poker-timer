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

class PokerTimerApp extends StatelessWidget {
  const PokerTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // Init tournament provider with warning seconds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TournamentProvider>().init(settings.warningSeconds);
        });

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
          home: const HomeScreen(),
        );
      },
    );
  }
}
