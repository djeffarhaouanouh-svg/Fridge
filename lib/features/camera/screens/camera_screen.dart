import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show lerpDouble;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/claude_service.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/services/neon_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/screens/results_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final List<Uint8List> _photos = [];
  final _viewfinderKey = GlobalKey();
  final _thumbnailKey = GlobalKey();

  late final AnimationController _flyController;
  late final Animation<double> _flyAnim;
  late final AnimationController _flashController;
  late final Animation<double> _flashAnim;

  OverlayEntry? _flyEntry;
  bool _isAnimating = false;

  // Live camera preview
  CameraController? _cameraController;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flyAnim = CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeInOut,
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _flashAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _cameraController = ctrl;
        _cameraReady = true;
      });
    } catch (_) {
      // Permission refusée ou caméra indisponible → fond noir conservé
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    _flashController.dispose();
    _flyEntry?.remove();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _showSourcePicker() async {
    if (_isAnimating) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2420),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _SourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () => Navigator.pop(_, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _SourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Choisir dans la galerie',
              onTap: () => Navigator.pop(_, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickAndProcess(source);
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();

    if (!mounted) return;

    // Lance l'animation d'abord, puis ajoute la photo dans la vignette.
    setState(() => _isAnimating = true);
    try {
      await NeonService().saveUserPhotoBytes(bytes);
    } catch (e, st) {
      debugPrint('saveUserPhotoBytes: $e\n$st');
    }

    // Animation fly (cosmétique uniquement, en parallèle)
    final vfBox = _viewfinderKey.currentContext?.findRenderObject() as RenderBox?;
    final thumbBox = _thumbnailKey.currentContext?.findRenderObject() as RenderBox?;

    if (vfBox != null && thumbBox != null && mounted) {
      final startRect = vfBox.localToGlobal(Offset.zero) & vfBox.size;
      final endRect = thumbBox.localToGlobal(Offset.zero) & thumbBox.size;

      _flashController.forward(from: 0);

      _flyEntry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
          animation: _flyAnim,
          builder: (context, _) {
            final t = _flyAnim.value;
            final rect = Rect.lerp(startRect, endRect, t)!;
            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: Transform.rotate(
                angle: t * 2 * math.pi,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(lerpDouble(20, 12, t)!),
                  child: Image.memory(bytes, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      );

      Overlay.of(context).insert(_flyEntry!);

      _flyController.forward(from: 0).then((_) {
        _flyEntry?.remove();
        _flyEntry = null;
        if (!mounted) return;
        setState(() {
          _photos.add(bytes);
          _isAnimating = false;
        });
        ref.read(capturedPhotosProvider.notifier).state = List.from(_photos);
      });
    } else {
      // Fallback sans animation: on ajoute immédiatement.
      setState(() {
        _photos.add(bytes);
        _isAnimating = false;
      });
      ref.read(capturedPhotosProvider.notifier).state = List.from(_photos);
    }
  }


  void _removeLastPhoto() {
    if (_photos.isEmpty) return;
    setState(() => _photos.removeLast());
    ref.read(capturedPhotosProvider.notifier).state = List.from(_photos);
  }

  Future<void> _analyzePhotos() async {
    if (_photos.isEmpty) return;

    ref.read(scanStatusProvider.notifier).state = ScanStatus.loading;
    ref.read(latestScanMealsProvider.notifier).state = const [];
    ref.read(latestScanIngredientsProvider.notifier).state = const [];

    try {
      await _runPhotoAnalysis().timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException('scan'),
      );
    } on TimeoutException {
      _showError('Délai dépassé. Vérifie ta connexion et réessaie.');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
    } catch (e) {
      _showError('Erreur : $e');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
    } finally {
      if (ref.read(scanStatusProvider) == ScanStatus.loading) {
        ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
      }
    }
  }

  Future<void> _runPhotoAnalysis() async {
    final claude = ClaudeService();
    final ingredients = await claude.detectIngredients(_photos.last);

    if (ingredients.isEmpty) {
      _showError(
          'Aucun ingrédient détecté. Réessaie avec une meilleure photo.');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
      return;
    }

    final existing = ref.read(detectedIngredientsProvider);
    final latestDetected = <String>[];
    final latestSeen = <String>{};
    for (final item in ingredients) {
      final v = item.trim();
      if (v.isEmpty) continue;
      final key = v.toLowerCase();
      if (latestSeen.add(key)) latestDetected.add(v);
    }
    final merged = <String>[];
    final seen = <String>{};
    for (final item in [...existing, ...latestDetected]) {
      final v = item.trim();
      if (v.isEmpty) continue;
      final key = v.toLowerCase();
      if (seen.add(key)) merged.add(v);
    }
    ref.read(detectedIngredientsProvider.notifier).state = merged;
    ref.read(latestScanIngredientsProvider.notifier).state = latestDetected;
    await persistFridgeToNeon(merged);

    final profile = ref.read(userProfileProvider);
    final meals = await claude.findRecipes(ingredients, profile: profile);
    if (meals.isNotEmpty) {
      ref.read(latestScanMealsProvider.notifier).state = meals;
      await ref.read(mealsProvider.notifier).mergeScanResultsAndPersist(meals);
    }

    ref.read(scanStatusProvider.notifier).state = ScanStatus.done;
    setState(() => _photos.clear());
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
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
      backgroundColor: const Color(0xFF1C1816),
      body: Stack(
          children: [
            // Viewfinder plein écran — live preview ou fond noir si indispo
            Positioned.fill(
              child: _cameraReady && _cameraController != null
                  ? CameraPreview(
                      _cameraController!,
                      child: Container(key: _viewfinderKey),
                    )
                  : Container(
                      key: _viewfinderKey,
                      color: const Color(0xFF1C1816),
                    ),
            ),

            // Frame de scan centré
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -60),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 64,
                      height: MediaQuery.of(context).size.height * 0.52,
                      child: const CustomPaint(painter: _ScanFramePainter()),
                    ),
                  ),
                ),
              ),
            ),

            // Analyse en cours
            if (isScanning)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTokens.coral, strokeWidth: 2),
                    const SizedBox(height: 16),
                    Text('Analyse en cours…',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Flash shutter — Positioned.fill doit être enfant direct du Stack
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flashAnim,
                  builder: (_, __) => ColoredBox(
                    color: Colors.white.withValues(alpha: _flashAnim.value),
                  ),
                ),
              ),
            ),

            // Header : X + logo
            Positioned(
              top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.kitchen_outlined, color: AppTokens.coral, size: 24),
                          const SizedBox(width: 7),
                          Text('fridge·ai',
                            style: GoogleFonts.fraunces(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.coral,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Contrôles bas : miniature + bouton capture
            // viewPadding.bottom + 8 (margin nav) + 56 (nav height) + 44 (spacing)
            Positioned(
              bottom: MediaQuery.of(context).viewPadding.bottom + 108, left: 32, right: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Miniature / envoyer
                  Positioned(
                    left: 0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 172,
                          height: 70,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: Container(
                                  key: _thumbnailKey,
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hasPhotos ? AppTokens.coral : Colors.white24,
                                      width: hasPhotos ? 2 : 1,
                                    ),
                                    color: Colors.white10,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (!hasPhotos)
                                        const Center(
                                          child: Icon(
                                            Icons.grid_view_rounded,
                                            color: Colors.white38,
                                            size: 22,
                                          ),
                                        )
                                      else if (_photos.length == 1)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            _photos.last,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else ...[
                                        Positioned(
                                          left: -8,
                                          top: 7,
                                          child: Transform.rotate(
                                            angle: -0.26,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.memory(
                                                _photos[_photos.length - 2],
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 12,
                                          top: -4,
                                          child: Transform.rotate(
                                            angle: 0.22,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.memory(
                                                _photos.last,
                                                width: 46,
                                                height: 46,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (hasPhotos && !isScanning)
                                Positioned(
                                  left: 72,
                                  bottom: 10,
                                  child: GestureDetector(
                                    onTap: _analyzePhotos,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 34,
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: AppTokens.coral,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white, width: 1.4),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'envoyer',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: const Offset(-1, 0),
                                          child: const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Bulle X — supprimer la dernière photo
                        if (hasPhotos && !isScanning)
                          Positioned(
                            top: -7, left: -7,
                            child: GestureDetector(
                              onTap: _removeLastPhoto,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.close, size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Center(
                    child: GestureDetector(
                      onTap: (isScanning || _isAnimating) ? null : _showSourcePicker,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTokens.coral, size: 22),
            const SizedBox(width: 14),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEE5C42)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 28.0;
    const r = 6.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    _drawCorner(canvas, paint, 0, 0, arm, r, _CornerType.topLeft);
    // Top-right
    _drawCorner(canvas, paint, w, 0, arm, r, _CornerType.topRight);
    // Bottom-left
    _drawCorner(canvas, paint, 0, h, arm, r, _CornerType.bottomLeft);
    // Bottom-right
    _drawCorner(canvas, paint, w, h, arm, r, _CornerType.bottomRight);
  }

  void _drawCorner(Canvas canvas, Paint paint, double x, double y,
      double arm, double r, _CornerType type) {
    final path = Path();
    switch (type) {
      case _CornerType.topLeft:
        path.moveTo(x, y + arm);
        path.lineTo(x, y + r);
        path.arcToPoint(Offset(x + r, y), radius: Radius.circular(r));
        path.lineTo(x + arm, y);
      case _CornerType.topRight:
        path.moveTo(x - arm, y);
        path.lineTo(x - r, y);
        path.arcToPoint(Offset(x, y + r), radius: Radius.circular(r));
        path.lineTo(x, y + arm);
      case _CornerType.bottomLeft:
        path.moveTo(x, y - arm);
        path.lineTo(x, y - r);
        path.arcToPoint(Offset(x + r, y), radius: Radius.circular(r), clockwise: false);
        path.lineTo(x + arm, y);
      case _CornerType.bottomRight:
        path.moveTo(x - arm, y);
        path.lineTo(x - r, y);
        path.arcToPoint(Offset(x, y - r), radius: Radius.circular(r), clockwise: false);
        path.lineTo(x, y - arm);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => false;
}

enum _CornerType { topLeft, topRight, bottomLeft, bottomRight }

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
      ..color = const Color(0xFFEE5C42)
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
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
      path.lineTo(w, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
      path.lineTo(w, h);
    } else if (bottomLeft) {
      path.moveTo(w, h);
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
      path.lineTo(0, 0);
    } else if (bottomRight) {
      path.moveTo(0, h);
      path.lineTo(w - r, h);
      path.arcToPoint(Offset(w, h - r),
          radius: Radius.circular(r), clockwise: false);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
