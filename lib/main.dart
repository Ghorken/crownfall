// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/screens/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Forza orientamento verticale (schermata fissa)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CrownFallApp());
}

class CrownFallApp extends StatelessWidget {
  const CrownFallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Profilo giocatore globale (in produzione salvare su SharedPreferences)
      create: (_) => PlayerProfile(name: 'Giocatore'),
      child: MaterialApp(
        title: 'Crown Fall',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: const MainMenuScreen(),
      ),
    );
  }
}
