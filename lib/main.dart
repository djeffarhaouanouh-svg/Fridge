import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_tokens.dart';
import 'features/navigation/widgets/bottom_nav.dart';
import 'features/camera/screens/camera_screen.dart';
import 'features/meals/screens/results_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
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
        scaffoldBackgroundColor: AppTokens.bg,
        colorScheme: ColorScheme.dark(
          primary: AppTokens.accent,
          surface: AppTokens.surface,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: const [
          CameraScreen(),
          ResultsScreen(),
          PlanScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
