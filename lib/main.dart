import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notifications_service.dart';
import 'core/theme/app_tokens.dart';
import 'core/widgets/app_splash_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/meals/models/meal.dart';
import 'features/meals/providers/meals_provider.dart';
import 'features/navigation/widgets/bottom_nav.dart';
import 'features/camera/screens/camera_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'firebase_options.dart';
import 'core/services/neon_service.dart';

// Provider global pour l'état de connexion
final authStateProvider = StateProvider<bool>((ref) => false);

/// Série de jours consécutifs avec ouverture de l’app (persistée en base).
final loginStreakProvider = StateProvider<int>((ref) => 0);

/// Nombre de recettes terminées (bouton "Terminer" en fin de recette).
final cookedCountProvider = StateProvider<int>((ref) => 0);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(IngredientAdapter());

    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }
  } catch (e, stack) {
    debugPrint('=== CRASH AU DEMARRAGE ===');
    debugPrint(e.toString());
    debugPrint(stack.toString());
  }

  FlutterError.onError = (details) {
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTokens.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: FridgeApp()));
}

class FridgeApp extends ConsumerWidget {
  const FridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(themePreferenceProvider);
    final themeMode = themePreference == ThemePreference.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return MaterialApp(
      title: 'Fridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTokens.paper,
        colorScheme: const ColorScheme.light(
          primary: AppTokens.coral,
          surface: AppTokens.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF151515),
        colorScheme: const ColorScheme.dark(
          primary: AppTokens.coral,
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _checked = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await AuthService.getSession();
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('profile_onboarding_done_v1') ?? false;
    if (session != null) {
      ref.read(authStateProvider.notifier).state = true;
    }
    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingDone;
        _checked = true;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_onboarding_done_v1', true);
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const AppSplashScreen(
        subtitle: 'Vérification de la session...',
      );
    }
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    final isLoggedIn = ref.watch(authStateProvider);
    return isLoggedIn ? const MainScreen() : const AuthScreen();
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _remoteReady = false;

  @override
  void initState() {
    super.initState();
    _bootstrapRemoteState();
  }

  Future<void> _bootstrapRemoteState() async {
    try {
      final db = NeonService();
      await db.ensureUserSyncSchema();

      final session = await AuthService.getSession();
      if (session != null) {
        await db.upsertUser(
          session['name'] ?? 'Utilisateur',
          session['email'] ?? '',
        );
        final savedTheme = await db.loadThemePreference();
        if (savedTheme == 'dark') {
          ref.read(themePreferenceProvider.notifier).state = ThemePreference.dark;
        } else if (savedTheme == 'light') {
          ref.read(themePreferenceProvider.notifier).state = ThemePreference.light;
        }
        final savedAiTone = await db.loadAiTonePreference();
        if (savedAiTone != null) {
          for (final t in AiTone.values) {
            if (t.name == savedAiTone) {
              ref.read(aiToneProvider.notifier).state = t;
              break;
            }
          }
        }
        await PushNotificationsService.instance.initialize();
      }

      // Requêtes indépendantes en parallèle (moins de latence qu’en série).
      await Future.wait([
        (() async {
          final streak = await db.recordDailyLoginAndGetStreak();
          ref.read(loginStreakProvider.notifier).state = streak;
        })(),
        (() async {
          final count = await db.getCookedCount();
          ref.read(cookedCountProvider.notifier).state = count;
        })(),
        (() async {
          final fridge = await db.loadFridgeIngredients();
          ref.read(detectedIngredientsProvider.notifier).state = fridge;
        })(),
        (() async {
          final plan = await db.loadPlanSelections();
          if (plan != null && plan.isNotEmpty) {
            ref.read(planMealSelectionsProvider.notifier).state = plan;
          }
        })(),
        ref.read(mealsProvider.notifier).loadFromDatabase(),
      ]);
    } catch (e, st) {
      debugPrint('Sync Neon au démarrage: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _remoteReady = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);

    if (!_remoteReady) {
      return const AppSplashScreen(
        subtitle: 'Chargement de tes recettes et préférences...',
      );
    }

    ref.listen<List<String>>(detectedIngredientsProvider, (prev, next) {
      NeonService().saveFridgeIngredients(next).catchError((_) {});
    });
    ref.listen<Map<String, Meal>>(planMealSelectionsProvider, (prev, next) {
      NeonService().savePlanSelections(next).catchError((_) {});
    });
    ref.listen<ThemePreference>(themePreferenceProvider, (prev, next) {
      final theme = next == ThemePreference.dark ? 'dark' : 'light';
      NeonService().saveThemePreference(theme).catchError((_) {});
    });
    ref.listen<AiTone>(aiToneProvider, (prev, next) {
      NeonService().saveAiTonePreference(next.name).catchError((_) {});
    });

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedTab,
        children: const [
          HomeScreen(),
          PlanScreen(),
          CameraScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
