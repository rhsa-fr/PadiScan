import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diagnosis_result.dart';
import '../services/classifier_service.dart';
import '../services/cv_pipeline_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scanner_reticle.dart';
import '../widgets/animated_shutter_button.dart';
import '../widgets/padiscan_logo.dart';
import 'diagnosis_screen.dart';

class ScannerScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final ClassifierService classifierService;

  const ScannerScreen({
    super.key,
    this.cameras,
    required this.classifierService,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras != null && widget.cameras!.isNotEmpty) {
      final camera = widget.cameras!.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Camera init error: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(newFlash ? FlashMode.torch : FlashMode.off);
      setState(() => _isFlashOn = newFlash);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      await _runDiagnosisPipeline(file.path);
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        await _runDiagnosisPipeline(file.path);
      } catch (e) {
        debugPrint('Capture error: $e');
      }
    } else {
      // Fallback jika kamera tidak aktif (bisa langsung pilih galeri)
      await _pickFromGallery();
    }
  }

  Future<void> _runDiagnosisPipeline(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      // 1. Baca dan decode citra
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Gagal membaca data citra.');
      }

      // 2. Simpan salinan permanen ke dokumen aplikasi
      final String scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final String savedImagePath = await HistoryService.persistImage(imagePath, 'scan_$scanId.jpg');

      // 3. Jalankan Pengolahan Citra Klasik (Quality Gate + ExG + CIELab Lesion)
      final cvResult = CVPipelineService.process(decoded);

      // 4. Validasi Objek Bukan Daun: Munculkan Peringatan Modal
      if (!cvResult.isLeaf) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        final bool? continueAnyway = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 40, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bukan Daun Padi Terdeteksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Citra yang Anda ambil tidak menunjukkan ciri klorofil atau jaringan daun padi. Hasil prediksi penyakit mungkin tidak valid.\n\nDisarankan untuk mengambil ulang foto daun secara tegak lurus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Foto Ulang', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tetap Analisis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        if (continueAnyway != true || !mounted) {
          return;
        }
        setState(() => _isProcessing = true);
      }

      // 5. Simpan Citra Tahapan Visi Komputer
      String? overlayPath;
      String? exgPath;
      String? leafMaskPath;
      final appDir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${appDir.path}/scans');
      if (!scansDir.existsSync()) {
        scansDir.createSync(recursive: true);
      }

      if (cvResult.overlayImage != null) {
        final overlayFile = File('${scansDir.path}/overlay_$scanId.jpg');
        await overlayFile.writeAsBytes(img.encodeJpg(cvResult.overlayImage!));
        overlayPath = overlayFile.path;
      }
      if (cvResult.exgImage != null) {
        final exgFile = File('${scansDir.path}/exg_$scanId.jpg');
        await exgFile.writeAsBytes(img.encodeJpg(cvResult.exgImage!));
        exgPath = exgFile.path;
      }
      if (cvResult.leafMaskImage != null) {
        final leafFile = File('${scansDir.path}/leaf_$scanId.jpg');
        await leafFile.writeAsBytes(img.encodeJpg(cvResult.leafMaskImage!));
        leafMaskPath = leafFile.path;
      }

      // 6. Jalankan Klasifikasi CNN TFLite dengan Decision Fusion
      final cnnResult = await widget.classifierService.predict(
        decoded,
        cvLesionRatio: cvResult.lesionRatio,
        cvSeverityScore: cvResult.severityScore,
      );

      // 7. Bentuk objek DiagnosisResult
      final result = DiagnosisResult(
        id: scanId,
        imagePath: savedImagePath,
        overlayImagePath: overlayPath,
        exgImagePath: exgPath,
        leafMaskImagePath: leafMaskPath,
        predictedClass: cnnResult['predicted_class'] as String,
        confidence: cnnResult['confidence'] as double,
        severityScore: cvResult.severityScore,
        lesionRatio: cvResult.lesionRatio,
        qualityPassed: cvResult.qualityPassed,
        isLeaf: cvResult.isLeaf,
        blurScore: cvResult.blurScore,
        brightness: cvResult.brightness,
        leafAreaRatio: cvResult.leafAreaRatio,
        rejectReason: cvResult.rejectReason,
        timestamp: DateTime.now(),
        plotName: 'Sawah Blok Jatibarang, Indramayu',
      );

      // 8. Simpan ke Riwayat Lokal
      await HistoryService.saveResult(result);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview atau Fallback
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    color: const Color(0xFF1E293B),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'Kamera Siap Digunakan',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pilih Foto dari Galeri'),
                            onPressed: _pickFromGallery,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Top Header Strip dengan Logo PadiScan & GPS Telemetri
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const PadiScanLogo(size: 26),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'PadiScan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Indramayu, Jawa Barat • Luring',
                                style: TextStyle(color: Colors.white60, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.sensors, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'AI Siap',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Quality Gate HUD Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHudItem(Icons.check_circle, 'Fokus: Tajam'),
                      Container(width: 1, height: 12, color: Colors.white24),
                      _buildHudItem(Icons.check_circle, 'Cahaya: Cukup'),
                      Container(width: 1, height: 12, color: Colors.white24),
                      _buildHudItem(Icons.check_circle, 'Jarak: Pas'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. AI Reticle Animasi Laser Scan
          const Center(
            child: AnimatedScannerReticle(
              size: 260,
              isScanning: true,
            ),
          ),

          // 4. Petunjuk Melayang
          Positioned(
            bottom: 125,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke helai daun yang bergejala',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // 5. Tombol Kontrol Kamera di Bawah
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Galeri
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                  tooltip: 'Ambil dari Galeri',
                  onPressed: _pickFromGallery,
                ),

                // Shutter Button Beranimasi Pulse Ring
                AnimatedShutterButton(
                  isProcessing: _isProcessing,
                  onTap: _capturePhoto,
                ),

                // Tombol Flashlight
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.amber : Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Lampu Kilat',
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // 6. Loading Overlay saat analisis
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: AppTheme.primaryContainer),
                        SizedBox(height: 16),
                        Text(
                          'Menganalisis Citra Daun...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Quality Gate • Segmentasi Lesi • CNN',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHudItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
