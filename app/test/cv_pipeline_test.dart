import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:app/services/cv_pipeline_service.dart';
import 'package:app/models/diagnosis_result.dart';

void main() {
  test('CV Pipeline: Proses citra sintetis dan deteksi lesi/Quality Gate', () {
    // Buat citra sintetis 100x100 dengan daun hijau dan bercak cokelat
    final testImg = img.Image(width: 100, height: 100);

    // Latar belakang abu-abu tanah
    img.fill(testImg, color: img.ColorRgb8(120, 110, 100));

    // Gambar daun padi (hijau cerah di tengah)
    for (int y = 20; y < 80; y++) {
      for (int x = 40; x < 60; x++) {
        testImg.setPixelRgb(x, y, 40, 180, 50); // hijau klorofil
      }
    }

    // Gambar bercak lesi cokelat di daun
    for (int y = 45; y < 55; y++) {
      for (int x = 45; x < 55; x++) {
        testImg.setPixelRgb(x, y, 190, 80, 20); // cokelat kemerahan
      }
    }

    final result = CVPipelineService.process(testImg);

    expect(result.brightness, greaterThan(30.0));
    expect(result.leafAreaRatio, greaterThan(0.05));
    expect(result.lesionRatio, greaterThan(0.0));
    expect(result.severityScore, greaterThanOrEqualTo(1));
    expect(result.overlayImage, isNotNull);
  });

  test('DiagnosisResult: Serialisasi dan Deserialisasi JSON', () {
    final now = DateTime.now();
    final original = DiagnosisResult(
      id: 'test_123',
      imagePath: '/path/to/img.jpg',
      overlayImagePath: '/path/to/overlay.jpg',
      predictedClass: 'Leaf Blast',
      confidence: 0.967,
      severityScore: 2,
      lesionRatio: 0.084,
      qualityPassed: true,
      blurScore: 1250.5,
      brightness: 128.4,
      leafAreaRatio: 0.155,
      timestamp: now,
      plotName: 'Petak Sawah Ciherang',
    );

    final json = original.toJson();
    final restored = DiagnosisResult.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.predictedClass, original.predictedClass);
    expect(restored.confidence, original.confidence);
    expect(restored.severityScore, 2);
    expect(restored.severityLabel, 'Tingkat 2 (Sedang)');
    expect(restored.plotName, 'Petak Sawah Ciherang');
  });
}
