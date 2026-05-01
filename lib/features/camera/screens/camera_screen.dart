import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/google_vision_service.dart';
import '../../../core/services/spoonacular_service.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../../meals/providers/meals_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  String _scanStep = '';

  Future<void> _handleScan() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return;

    ref.read(scanStatusProvider.notifier).state = ScanStatus.loading;

    try {
      final bytes = await photo.readAsBytes();

      setState(() => _scanStep = 'Détection des ingrédients…');
      final ingredients = await GoogleVisionService().detectIngredients(bytes);
      ref.read(detectedIngredientsProvider.notifier).state = ingredients;

      setState(() => _scanStep = 'Recherche des recettes…');
      if (ingredients.isNotEmpty) {
        final meals = await SpoonacularService().findByIngredients(ingredients);
        if (meals.isNotEmpty) {
          ref.read(mealsProvider.notifier).setMeals(meals);
        }
      }

      ref.read(scanStatusProvider.notifier).state = ScanStatus.done;
    } catch (e) {
      debugPrint('Scan error: $e');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.error;
    }

    setState(() => _scanStep = '');
    if (mounted) ref.read(selectedTabProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(scanStatusProvider) == ScanStatus.loading;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Scanne ton frigo',
                  style: GoogleFonts.syne(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prends une photo de tes ingrédients',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppTokens.muted),
                ),
                const Spacer(),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTokens.surface,
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Icon(
                    Icons.kitchen_outlined,
                    size: 80,
                    color: AppTokens.muted,
                  ),
                ),
                const SizedBox(height: 40),
                if (_scanStep.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _scanStep,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTokens.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: isScanning ? null : _handleScan,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTokens.accent,
                      boxShadow: AppTokens.accentGlow,
                      border: Border.all(color: AppTokens.text, width: 4),
                    ),
                    child: isScanning
                        ? Center(
                            child: CircularProgressIndicator(
                                color: AppTokens.bg, strokeWidth: 3))
                        : Icon(Icons.camera_alt, size: 36, color: AppTokens.bg),
                  ),
                ),
                const SizedBox(height: 50),
                if (!isScanning)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTokens.card.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: AppTokens.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTokens.accentDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lightbulb_outline,
                              color: AppTokens.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Place plusieurs ingrédients dans le cadre',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: AppTokens.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
