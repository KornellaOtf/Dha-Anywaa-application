import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/anywaa_ai_page.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/services/retention_engine.dart';
import 'package:dha_anywaaa/services/share_helper.dart';
import 'package:dha_anywaaa/components/animal.dart';
import 'package:dha_anywaaa/components/bird.dart';
import 'package:dha_anywaaa/components/body_part.dart';
import 'package:dha_anywaaa/components/cloth.dart';
import 'package:dha_anywaaa/components/colors.dart';
import 'package:dha_anywaaa/components/fish.dart';
import 'package:dha_anywaaa/components/number.dart';
import 'package:dha_anywaaa/components/shape.dart';
import 'package:dha_anywaaa/home_page.dart';
import 'package:dha_anywaaa/nameEntry.dart';
import 'package:dha_anywaaa/pages/page1.dart';
import 'package:dha_anywaaa/pages/page2.dart';
import 'package:dha_anywaaa/pages/page3.dart';
import 'package:dha_anywaaa/pages/page4.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/wraper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:quick_actions/quick_actions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize Firebase (Analytics only - no FCM for now)
  try {
    await Firebase.initializeApp();
    // Set user properties so Firebase can segment users by app version
    // and distribution channel. Helps replace "(not set)" with real data.
    final analytics = FirebaseAnalytics.instance;
    final pkgInfo = await PackageInfo.fromPlatform();
    await analytics.setUserProperty(name: 'app_version', value: pkgInfo.version);
    await analytics.setUserProperty(name: 'build_number', value: pkgInfo.buildNumber);
    await analytics.setUserProperty(name: 'distribution', value: 'github');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize background downloader so OTA downloads survive backgrounding
  await OtaService.initialize();
  
  // Initialize retention engine for smart notifications
  try {
    await RetentionEngine.instance.initialize();
    await RetentionEngine.instance.requestPermission();
  } catch (e) {
    debugPrint('Retention engine initialization error: $e');
  }
  
  // Initialize home screen shortcuts (long-press app icon menu)
  const quickActions = QuickActions();
  await quickActions.setShortcutItems(<ShortcutItem>[
    const ShortcutItem(
      type: 'action_quiz',
      localizedTitle: 'Take a Quiz',
      icon: 'ic_launcher',
    ),
    const ShortcutItem(
      type: 'action_ai',
      localizedTitle: 'Ask Anywaa AI',
      icon: 'ic_launcher',
    ),
    const ShortcutItem(
      type: 'action_share',
      localizedTitle: 'Share App',
      icon: 'ic_launcher',
    ),
  ]);
  
  // Load the saved preference first so the correct theme is applied from the
  // very first frame instead of flashing the system theme on relaunch.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    AppSettings(
      notifier: AppSettingsNotifier(
        initialThemeMode:
            AppSettingsNotifier.modeFromIndex(prefs.getInt('theme_mode') ?? 0),
        initialSoundEnabled: prefs.getBool('sound_enabled') ?? true,
      ),
      child: MyApp(quickActions: quickActions),
    ),
  );
}

class MyApp extends StatefulWidget {
  final QuickActions quickActions;
  
  const MyApp({super.key, required this.quickActions});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    // Handle home screen shortcut taps
    widget.quickActions.initialize((String type) {
      if (type == 'action_quiz') {
        _navigatorKey.currentState?.pushNamed('quiz');
      } else if (type == 'action_ai') {
        _navigatorKey.currentState?.pushNamed('anywaa_ai');
      } else if (type == 'action_share') {
        ShareHelper.instance.shareApp();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Depend on the settings notifier so a theme change rebuilds MaterialApp.
    final settings = AppSettings.of(context);
    
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Dha Anywaa',
      theme: AppTheme.data,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      routes: {
        '/': (context) => const Wrapper(),
        'number': (context) => const Number(),
        'alphabet': (context) => const Page1(),
        'word': (context) => const Page2(),
        'shape': (context) => const Shpae(),
        'reading': (context) => const Page3(),
        'quiz': (context) => const Page4(),
        'anywaa_ai': (context) => const AnywaaAiPage(),
        'home_page': (context) => const HomePage(),
        'name_entry': (context) => const NameEntry(),
        'colors': (context) => const Kit(),
        'body': (context) => const BodyPart(),
        'fish': (context) => const Fish(),
        'animal': (context) => const Animal(),
        'bird': (context) => const Bird(),
        'clothes': (context) => const Cloth(),
      },
    );
  }
}
