import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/app_theme.dart';
import 'core/config/env.dart';
import 'core/routing/app_router.dart';
import 'core/storage/storage_service.dart';
import 'core/providers/providers.dart';
import 'data/local/database.dart';

/// Application Entry Point
/// 
/// Initializes the Flutter app with necessary configurations for POS terminals
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for POS terminals
  if (Environment.lockPortraitOrientation) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightOverlayStyle);

  // Initialize storage service
  final storageService = await StorageService.init();

  // Initialize local database
  final database = AppDatabase();

  // Run the app with Riverpod state management
  runApp(
    ProviderScope(
      overrides: [
        // Override storage service provider with initialized instance
        storageServiceProvider.overrideWithValue(storageService),
        // Override database provider with initialized instance
        localDatabaseProvider.overrideWithValue(database),
      ],
      child: const CountryboyApp(),
    ),
  );
}

/// Root application widget
/// Optimized for Android POS terminals with large fonts and touch targets
class CountryboyApp extends ConsumerWidget {
  const CountryboyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      // Design size based on typical POS terminal
      designSize: const Size(360, 640),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: Environment.appName,
          debugShowCheckedModeBanner: Environment.enableDebugBanner,
          theme: AppTheme.lightTheme,
          
          // Text scale factor limits for POS terminals
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaleFactor.clamp(
                    Environment.minTextScaleFactor,
                    Environment.maxTextScaleFactor,
                  ),
                ),
              ),
              child: widget!,
            );
          },
          
          // Routing configuration
          initialRoute: AppRouter.splash,
          routes: AppRouter.routes,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: AppRouter.onUnknownRoute,
        );
      },
    );
  }
}
