import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/claude_service.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../../meals/providers/meals_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  final List<Uint8List> _photos = [];
  String _selectedSpeed = 'Rapide';
  String _selectedDiet = 'Sportif';

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    setState(() => _photos.add(bytes));
    ref.read(capturedPhotosProvider.notifier).state = List.from(_photos);
  }

  Future<void> _analyzePhotos() async {
    if (_photos.isEmpty) return;

    ref.read(scanStatusProvider.notifier).state = ScanStatus.loading;
    final claude = ClaudeService();

    try {
      // On envoie la dernière photo pour la détection
      final ingredients = await claude.detectIngredients(_photos.last);

      if (ingredients.isEmpty) {
        _showError('Aucun ingrédient détecté. Réessaie avec une meilleure photo.');
        ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
        return;
      }

      ref.read(detectedIngredientsProvider.notifier).state = ingredients;

      final meals = await claude.findRecipes(ingredients);
      if (meals.isNotEmpty) {
        ref.read(mealsProvider.notifier).setMeals(meals);
      }

      ref.read(scanStatusProvider.notifier).state = ScanStatus.done;
      setState(() => _photos.clear());
      if (mounted) ref.read(selectedTabProvider.notifier).state = 1;
    } catch (e) {
      _showError('Erreur : $e');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(scanStatusProvider) == ScanStatus.loading;
    final hasPhotos = _photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF080D08),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Filtres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    value: _selectedSpeed,
                    options: const ['Rapide', 'Moyen', 'Lent'],
                    onChanged: (v) => setState(() => _selectedSpeed = v),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    value: _selectedDiet,
                    options: const ['Sportif', 'Vegan', 'Léger'],
                    onChanged: (v) => setState(() => _selectedDiet = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Viewfinder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF0A1A0A),
                      ),
                      const Positioned(top: 20, left: 20, child: _Corner(topLeft: true)),
                      const Positioned(top: 20, right: 20, child: _Corner(topRight: true)),
                      const Positioned(bottom: 20, left: 20, child: _Corner(bottomLeft: true)),
                      const Positioned(bottom: 20, right: 20, child: _Corner(bottomRight: true)),
                      if (isScanning)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppTokens.accent, strokeWidth: 2),
                              const SizedBox(height: 16),
                              Text(
                                'Analyse en cours…',
                                style: GoogleFonts.dmSans(
                                    color: AppTokens.accent, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bas : miniature + capture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Miniature — appuyer pour envoyer à l'IA
                  GestureDetector(
                    onTap: isScanning ? null : (hasPhotos ? _analyzePhotos : null),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasPhotos ? AppTokens.accent : Colors.white12,
                          width: hasPhotos ? 2 : 1,
                        ),
                        color: const Color(0xFF1A2A1A),
                      ),
                      child: Stack(
                        children: [
                          // Photo ou icône vide
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: hasPhotos
                                ? Image.memory(
                                    _photos.last,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(Icons.grid_view_rounded,
                                        color: AppTokens.muted, size: 22),
                                  ),
                          ),
                          // Badge compteur
                          if (hasPhotos)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTokens.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_photos.length}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTokens.bg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Icône "envoyer" au survol si photos présentes
                          if (hasPhotos && !isScanning)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                child: const Center(
                                  child: Icon(Icons.send_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton capture
                  GestureDetector(
                    onTap: isScanning ? null : _takePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: isScanning
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTokens.bg,
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Espace symétrie
                  const SizedBox(width: 56),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: const Color(0xFF111811),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (o) => ListTile(
                    title: Text(o,
                        style: GoogleFonts.dmSans(color: Colors.white)),
                    trailing: o == value
                        ? Icon(Icons.check, color: AppTokens.accent)
                        : null,
                    onTap: () => Navigator.pop(context, o),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
          if (selected != null) onChanged(selected);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141F14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 6.0;
    final w = size.width;
    final h = size.height;
    final path = Path();

    if (topLeft) {
      path.moveTo(0, h);
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
      path.lineTo(w, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: const Radius.circular(r));
      path.lineTo(w, h);
    } else if (bottomLeft) {
      path.moveTo(w, h);
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: const Radius.circular(r));
      path.lineTo(0, 0);
    } else if (bottomRight) {
      path.moveTo(0, h);
      path.lineTo(w - r, h);
      path.arcToPoint(Offset(w, h - r),
          radius: const Radius.circular(r), clockwise: false);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
