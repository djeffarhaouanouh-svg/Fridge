import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_tokens.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/meals/models/meal.dart';
import 'features/meals/providers/meals_provider.dart';
import 'features/navigation/widgets/bottom_nav.dart';
import 'features/camera/screens/camera_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'firebase_options.dart';
import 'core/services/neon_service.dart';

// Provider global pour l'état de connexion
final authStateProvider = StateProvider<bool>((ref) => false);

/// Série de jours consécutifs avec ouverture de l’app (persistée en base).
final loginStreakProvider = StateProvider<int>((ref) => 0);

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

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTokens.paper,
        colorScheme: ColorScheme.light(
          primary: AppTokens.coral,
          surface: AppTokens.surface,
          background: AppTokens.paper,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
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

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await AuthService.getSession();
    if (session != null) {
      ref.read(authStateProvider.notifier).state = true;
    }
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: AppTokens.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppTokens.coral),
        ),
      );
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
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrapRemoteState();
  }

  Future<void> _bootstrapRemoteState() async {
    try {
      final db = NeonService();
      await db.ensureUserSyncSchema();
      final streak = await db.recordDailyLoginAndGetStreak();
      ref.read(loginStreakProvider.notifier).state = streak;

      final fridge = await db.loadFridgeIngredients();
      ref.read(detectedIngredientsProvider.notifier).state = fridge;

      final plan = await db.loadPlanSelections();
      if (plan != null && plan.isNotEmpty) {
        ref.read(planMealSelectionsProvider.notifier).state = plan;
      }

      await ref.read(mealsProvider.notifier).loadFromDatabase();
    } catch (e, st) {
      debugPrint('Sync Neon au démarrage: $e\n$st');
    } finally {
      if (mounted) setState(() => _bootstrapped = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);

    if (!_bootstrapped) {
      return const Scaffold(
        backgroundColor: AppTokens.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppTokens.coral),
        ),
      );
    }

    ref.listen<List<String>>(detectedIngredientsProvider, (prev, next) {
      NeonService().saveFridgeIngredients(next).catchError((_) {});
    });
    ref.listen<Map<String, Meal>>(planMealSelectionsProvider, (prev, next) {
      NeonService().savePlanSelections(next).catchError((_) {});
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
