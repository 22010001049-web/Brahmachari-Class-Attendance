import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/supabase_config.dart';
import 'config/url_strategy.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'models/brahmachari_model.dart';
import 'data/brahmachari_names.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  await _seedBrahmacharis();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const BrahmachariAttendanceApp());
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Supabase is not configured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set NEXT_PUBLIC_SUPABASE_URL and\nNEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY\nin your build environment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _seedBrahmacharis() async {
  try {
    final service = SupabaseService();
    final existing = await service.getBrahmacharis();
    final existingNames =
        existing.map((b) => b.name.trim().toLowerCase()).toSet();

    for (final name in initialBrahmachariNames) {
      if (!existingNames.contains(name.trim().toLowerCase())) {
        await service.createBrahmachari(BrahmachariModel(name: name));
      }
    }
  } catch (e) {
    debugPrint('Error seeding brahmacharis: $e');
  }
}

class BrahmachariAttendanceApp extends StatefulWidget {
  const BrahmachariAttendanceApp({super.key});

  @override
  State<BrahmachariAttendanceApp> createState() =>
      _BrahmachariAttendanceAppState();
}

class _BrahmachariAttendanceAppState extends State<BrahmachariAttendanceApp> {
  @override
  void initState() {
    super.initState();
    themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brahmachari Class Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      themeMode: themeModeNotifier.value,
      home: const HomeScreen(),
    );
  }
}
