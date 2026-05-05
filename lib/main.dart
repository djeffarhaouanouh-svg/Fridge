import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_tokens.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/meals/models/meal.dart';
import 'features/navigation/widgets/bottom_nav.dart';
import 'features/camera/screens/camera_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'firebase_options.dart';

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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTokens.paper,
            body: Center(
              child: CircularProgressIndicator(color: AppTokens.coral),
            ),
          );
        }
        return snapshot.hasData ? const MainScreen() : const AuthScreen();
      },
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedTab,
        children: const [
          HomeScreen(),    // 0 — Home
          PlanScreen(),    // 1 — Plan de la semaine
          CameraScreen(),  // 2 — Scanner
          ProfileScreen(), // 3 — Profil
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}

