import 'package:dha_anywaaa/app_settings.dart';
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

void main() {
  runApp(
    AppSettings(
      notifier: AppSettingsNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dha Anywaa',
      theme: AppTheme.data,
      routes: {
        '/': (context) => const Wrapper(),
        'number': (context) => const Number(),
        'alphabet': (context) => const Page1(),
        'word': (context) => const Page2(),
        'shape': (context) => const Shpae(),
        'reading': (context) => const Page3(),
        'quiz': (context) => const Page4(),
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
