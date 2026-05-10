import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show lerpDouble, instantiateImageCodec, ImageByteFormat;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/services/claude_service.dart';
import '../../../core/services/openai_vision_service.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/services/neon_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/screens/results_screen.dart';

// ─── Ingredient entry with per-tag animation ─────────────────────────────────

class _DetectedIngredient {
  final String name;
  final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  _DetectedIngredient({required this.name, required this.controller}) {
    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    slide = Tween<Offset>(
      begin: const Offset(0, 0.7),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  void dispose() => controller.dispose();
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  // Existing photo capture state
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
  CameraController? _cameraController;
  bool _cameraReady = false;

  // Futuristic overlay animations
  late final AnimationController _scanLineController;
  late final AnimationController _glowController;

  // Live detection state
  Timer? _liveDetectionTimer;
  Timer? _liveDetectionTimeoutTimer;
  bool _isProcessingFrame = false;
  bool _liveDetectionPaused = false;
  final Set<String> _detectedSet = {};
  final List<_DetectedIngredient> _detectedList = [];
  final Map<String, int> _lastSeenMs = {};

  static const _coral = Color(0xFFEE5C42);

  @override
  void initState() {
    super.initState();

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flyAnim = CurvedAnimation(parent: _flyController, curve: Curves.easeInOut);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _flashAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

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
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
      _startLiveDetection();
    } catch (_) {}
  }

  void _startLiveDetection() {
    _liveDetectionTimer?.cancel();
    _liveDetectionTimeoutTimer?.cancel();

    _liveDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 950),
      (_) => _captureAndAnalyze(),
    );

    _liveDetectionTimeoutTimer = Timer(
      const Duration(seconds: 20),
      () {
        _liveDetectionTimer?.cancel();
        _liveDetectionTimer = null;
      },
    );
  }

  Future<Uint8List> _compressFrame(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes, targetWidth: 512);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ImageByteFormat.png);
    frame.image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _captureAndAnalyze() async {
    if (!_cameraReady || _cameraController == null) return;
    if (_isProcessingFrame || _liveDetectionPaused) return;

    _isProcessingFrame = true;
    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      try {
        File(xFile.path).deleteSync();
      } catch (_) {}

      final compressed = await _compressFrame(bytes);
      final ingredients = await OpenAiVisionService().detectIngredients([compressed], lowDetail: true);
      if (mounted) {
        _handleNewIngredients(ingredients);
        _pruneStaleIngredients();
      }
    } catch (_) {
      // Camera busy or API error — silently skip
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _handleNewIngredients(List<String> incoming) {
    final now = DateTime.now().millisecondsSinceEpoch;
    bool foundNew = false;

    for (final raw in incoming) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();

      _lastSeenMs[key] = now;

      if (_detectedSet.contains(key)) continue;

      // Re-show if currently fading out
      final fadingIdx = _detectedList.indexWhere((i) => i.name.toLowerCase() == key);
      if (fadingIdx != -1) {
        _detectedSet.add(key);
        _detectedList[fadingIdx].controller.forward();
        continue;
      }

      _detectedSet.add(key);
      foundNew = true;

      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      final ingredient = _DetectedIngredient(name: trimmed, controller: ctrl);

      setState(() {
        _detectedList.add(ingredient);
        if (_detectedList.length > 6) {
          _detectedList.removeAt(0).dispose();
        }
      });
      ctrl.forward();
    }

    if (foundNew) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _pruneStaleIngredients() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const staleMs = 2500;

    final staleKeys = _lastSeenMs.entries
        .where((e) => now - e.value > staleMs)
        .map((e) => e.key)
        .toList();

    for (final key in staleKeys) {
      _lastSeenMs.remove(key);
      _detectedSet.remove(key);

      final idx = _detectedList.indexWhere((i) => i.name.toLowerCase() == key);
      if (idx == -1) continue;

      final ingredient = _detectedList[idx];
      ingredient.controller.reverse().then((_) {
        if (!mounted) {
          ingredient.dispose();
          return;
        }
        setState(() => _detectedList.remove(ingredient));
        ingredient.dispose();
      });
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    _flashController.dispose();
    _scanLineController.dispose();
    _glowController.dispose();
    _flyEntry?.remove();
    _liveDetectionTimer?.cancel();
    _liveDetectionTimeoutTimer?.cancel();
    for (final tag in _detectedList) {
      tag.dispose();
    }
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _showSourcePicker() async {
    if (_isAnimating) return;
    _liveDetectionPaused = true;

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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _SourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _SourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Choisir dans la galerie',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) {
      _liveDetectionPaused = false;
      return;
    }
    await _pickAndProcess(source);
    _liveDetectionPaused = false;
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    setState(() => _isAnimating = true);
    try {
      await NeonService().saveUserPhotoBytes(bytes);
    } catch (e) {
      debugPrint('saveUserPhotoBytes: $e');
    }

    final vfBox =
        _viewfinderKey.currentContext?.findRenderObject() as RenderBox?;
    final thumbBox =
        _thumbnailKey.currentContext?.findRenderObject() as RenderBox?;

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

    _liveDetectionTimer?.cancel();
    _liveDetectionPaused = true;

    ref.read(scanStatusProvider.notifier).state = ScanStatus.loading;
    ref.read(latestScanMealsProvider.notifier).state = const [];
    ref.read(latestScanIngredientsProvider.notifier).state = const [];
    final claude = ClaudeService();
    final vision = OpenAiVisionService();

    try {
      final ingredients = await vision.detectIngredients(List.from(_photos));

      if (ingredients.isEmpty) {
        _showError('Aucun ingrédient détecté. Réessaie avec une meilleure photo.');
        ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
        _liveDetectionPaused = false;
        _startLiveDetection();
        return;
      }

      final existing = ref.read(detectedIngredientsProvider);
      final latestDetected = <String>[];
      final latestSeen = <String>{};
      for (final item in ingredients) {
        final v = item.trim();
        if (v.isEmpty) continue;
        if (latestSeen.add(v.toLowerCase())) latestDetected.add(v);
      }
      final merged = <String>[];
      final seen = <String>{};
      for (final item in [...existing, ...latestDetected]) {
        final v = item.trim();
        if (v.isEmpty) continue;
        if (seen.add(v.toLowerCase())) merged.add(v);
      }
      ref.read(detectedIngredientsProvider.notifier).state = merged;
      ref.read(latestScanIngredientsProvider.notifier).state = latestDetected;
      await persistFridgeToNeon(merged);

      final profile = ref.read(userProfileProvider);
      final meals = await claude.findRecipes(merged, profile: profile);
      if (meals.isNotEmpty) {
        ref.read(latestScanMealsProvider.notifier).state = meals;
        await ref.read(mealsProvider.notifier).mergeScanResultsAndPersist(meals);
      }

      ref.read(scanStatusProvider.notifier).state = ScanStatus.done;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scan_date', DateTime.now().toIso8601String());
      setState(() => _photos.clear());
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      }
    } catch (e) {
      _showError('Erreur : $e');
      ref.read(scanStatusProvider.notifier).state = ScanStatus.idle;
      _liveDetectionPaused = false;
      _startLiveDetection();
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
    final size = MediaQuery.of(context).size;
    final vPad = MediaQuery.of(context).viewPadding.bottom;
    final frameW = size.width - 64;
    final frameH = size.height * 0.52;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1816),
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────────────────
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

          // ── Futuristic scan overlay (corners + scan line + AI badge) ────
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -60),
                  child: SizedBox(
                    width: frameW,
                    height: frameH,
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_scanLineController, _glowController]),
                      builder: (_, __) => CustomPaint(
                        painter: _FuturisticScanPainter(
                          scanProgress: _scanLineController.value,
                          glowIntensity: _glowController.value,
                          isActive: _cameraReady && !isScanning,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Live ingredient tags (below scan frame) ──────────────────────
          if (_detectedList.isNotEmpty && !isScanning)
            Positioned(
              top: size.height * 0.76 - 48,
              left: 20,
              right: 20,
              child: _LiveIngredientTags(ingredients: _detectedList),
            ),

          // ── Scan progress overlay ────────────────────────────────────────
          if (isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: _coral,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Analyse IA en cours…',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Génération de vos recettes',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Shutter flash ────────────────────────────────────────────────
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

          // ── Header ──────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(selectedTabProvider.notifier).state = 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.kitchen_outlined,
                            color: _coral, size: 24),
                        const SizedBox(width: 7),
                        Text(
                          'fridge·ai',
                          style: GoogleFonts.fraunces(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: _coral,
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

          // ── Scan tips (hidden once ingredients detected) ─────────────────
          Positioned(
            bottom: vPad + 190,
            left: 40,
            right: 40,
            child: AnimatedOpacity(
              opacity: _detectedList.isEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: const _ScanTips(),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            bottom: vPad + 76,
            left: 32,
            right: 32,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Thumbnail gallery
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
                                    color: hasPhotos
                                        ? _coral
                                        : Colors.white24,
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
                                        borderRadius:
                                            BorderRadius.circular(10),
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
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                          ],
                        ),
                      ),
                      if (hasPhotos && !isScanning)
                        Positioned(
                          top: -7,
                          left: -7,
                          child: GestureDetector(
                            onTap: _removeLastPhoto,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.close,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Capture button
                Center(
                  child: GestureDetector(
                    onTap: (isScanning || _isAnimating)
                        ? null
                        : _showSourcePicker,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
                ),

                // Send button
                if (hasPhotos && !isScanning)
                  Positioned(
                    right: 0,
                    bottom: 10,
                    child: GestureDetector(
                      onTap: _analyzePhotos,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            decoration: BoxDecoration(
                              color: _coral,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white, width: 1.4),
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
        ],
      ),
    );
  }
}

// ─── Futuristic scan frame painter ───────────────────────────────────────────

class _FuturisticScanPainter extends CustomPainter {
  final double scanProgress;
  final double glowIntensity;
  final bool isActive;

  const _FuturisticScanPainter({
    required this.scanProgress,
    required this.glowIntensity,
    required this.isActive,
  });

  static const _coral = Color(0xFFEE5C42);
  static const _arm = 28.0;
  static const _r = 6.0;
  static const _topLift = 10.0;
  static const _bottomDrop = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow layer
    final glowPaint = Paint()
      ..color = _coral.withOpacity(0.28 + 0.18 * glowIntensity)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    // Solid layer
    final solidPaint = Paint()
      ..color = _coral
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final paint in [glowPaint, solidPaint]) {
      _corner(canvas, paint, 0, -_topLift, _CornerType.topLeft);
      _corner(canvas, paint, w, -_topLift, _CornerType.topRight);
      _corner(canvas, paint, 0, h + _bottomDrop, _CornerType.bottomLeft);
      _corner(canvas, paint, w, h + _bottomDrop, _CornerType.bottomRight);
    }

    if (!isActive) return;

    // Scan line sweeps the full visual range (topLift to bottomDrop)
    final totalH = h + _topLift + _bottomDrop;
    final scanY = -_topLift + totalH * scanProgress;

    // Gradient scan line
    final shader = LinearGradient(
      colors: [
        Colors.transparent,
        _coral.withOpacity(0.55),
        _coral.withOpacity(0.95),
        _coral.withOpacity(0.55),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    ).createShader(Rect.fromLTWH(0, scanY - 1, w, 2));

    canvas.drawLine(
      Offset(0, scanY),
      Offset(w, scanY),
      Paint()
        ..shader = shader
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Glow below scan line
    canvas.drawLine(
      Offset(0, scanY),
      Offset(w, scanY),
      Paint()
        ..color = _coral.withOpacity(0.12)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _corner(Canvas canvas, Paint paint, double x, double y,
      _CornerType type) {
    final path = Path();
    switch (type) {
      case _CornerType.topLeft:
        path.moveTo(x, y + _arm);
        path.lineTo(x, y + _r);
        path.arcToPoint(Offset(x + _r, y), radius: Radius.circular(_r));
        path.lineTo(x + _arm, y);
      case _CornerType.topRight:
        path.moveTo(x - _arm, y);
        path.lineTo(x - _r, y);
        path.arcToPoint(Offset(x, y + _r), radius: Radius.circular(_r));
        path.lineTo(x, y + _arm);
      case _CornerType.bottomLeft:
        path.moveTo(x, y - _arm);
        path.lineTo(x, y - _r);
        path.arcToPoint(Offset(x + _r, y),
            radius: Radius.circular(_r), clockwise: false);
        path.lineTo(x + _arm, y);
      case _CornerType.bottomRight:
        path.moveTo(x - _arm, y);
        path.lineTo(x - _r, y);
        path.arcToPoint(Offset(x, y - _r),
            radius: Radius.circular(_r), clockwise: false);
        path.lineTo(x, y - _arm);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FuturisticScanPainter old) =>
      old.scanProgress != scanProgress ||
      old.glowIntensity != glowIntensity ||
      old.isActive != isActive;
}

enum _CornerType { topLeft, topRight, bottomLeft, bottomRight }

// ─── Live ingredient tags ─────────────────────────────────────────────────────

class _LiveIngredientTags extends StatelessWidget {
  final List<_DetectedIngredient> ingredients;
  const _LiveIngredientTags({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: ingredients
          .map((i) => _SingleIngredientTag(ingredient: i))
          .toList(),
    );
  }
}

class _SingleIngredientTag extends StatelessWidget {
  final _DetectedIngredient ingredient;
  const _SingleIngredientTag({required this.ingredient, super.key});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: ingredient.fade,
      child: SlideTransition(
        position: ingredient.slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEE5C42).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEE5C42).withOpacity(0.18),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEE5C42),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEE5C42).withOpacity(0.85),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                ingredient.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Source picker option ─────────────────────────────────────────────────────

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

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
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rotating scan tips ───────────────────────────────────────────────────────

class _ScanTips extends StatefulWidget {
  const _ScanTips();

  @override
  State<_ScanTips> createState() => _ScanTipsState();
}

class _ScanTipsState extends State<_ScanTips> {
  static const _tips = [
    'Tu peux envoyer plusieurs photos à la fois',
    'Mets bien les produits de face',
    'Plus c\'est lumineux, meilleure est la détection',
    'Ouvre le frigo en grand pour tout capturer',
    'Les étiquettes aident à mieux identifier les produits',
    'Rapproche-toi pour les petits emballages',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        _tips[_index],
        key: ValueKey(_index),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.white60,
        ),
      ),
    );
  }
}
