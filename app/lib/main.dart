import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/main_navigation_shell.dart';
import 'services/classifier_service.dart';
import 'theme/app_theme.dart';

List<CameraDescription> availableCamerasList = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi daftar kamera perangkat
  try {
    availableCamerasList = await availableCameras();
  } catch (e) {
    debugPrint('Tidak dapat mendeteksi kamera lokal (menggunakan fallback galeri): $e');
  }

  // 2. Inisialisasi servis model TFLite
  final classifierService = ClassifierService();
  try {
    await classifierService.loadModel();
  } catch (e) {
    debugPrint('Gagal memuat model TFLite: $e');
  }

  runApp(PadiScanApp(
    cameras: availableCamerasList,
    classifierService: classifierService,
  ));
}

class PadiScanApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final ClassifierService classifierService;

  const PadiScanApp({
    super.key,
    required this.cameras,
    required this.classifierService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadiScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainNavigationShell(
        cameras: cameras,
        classifierService: classifierService,
      ),
    );
  }
}
