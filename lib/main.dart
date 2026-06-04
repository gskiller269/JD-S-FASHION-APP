import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using Dart environment variables for production readiness
  // Usage: flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://srtmangifebgvysddenp.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_OinhRPcHtVPk-qUbt6P5ZQ_hRvttwsL');

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: JDsFashionApp(),
    ),
  );
}

class JDsFashionApp extends ConsumerWidget {
  const JDsFashionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'JD\'s Fashion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto switch based on OS
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
