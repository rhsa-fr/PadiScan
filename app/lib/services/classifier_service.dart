import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;

  static const List<String> classNames = [
    'Bacterial Leaf Blight',
    'Brown Spot',
    'Healthy',
    'Leaf Blast',
    'Leaf Scald',
    'Sheath Blight',
  ];

  static const int inputSize = 224;

  bool get isReady => _interpreter != null;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/visikom_mobilenetv2_float16.tflite',
        options: options,
      );
      debugPrint('ClassifierService: TFLite model loaded successfully.');
    } catch (e) {
      debugPrint('ClassifierService Error loading model: $e');
      rethrow;
    }
  }

  /// Prediksi citra dari path berkas atau objek img.Image
  Future<Map<String, dynamic>> predict(dynamic imageInput) async {
    if (_interpreter == null) {
      await loadModel();
    }

    img.Image? decoded;
    if (imageInput is String) {
      final bytes = await File(imageInput).readAsBytes();
      decoded = img.decodeImage(bytes);
    } else if (imageInput is File) {
      final bytes = await imageInput.readAsBytes();
      decoded = img.decodeImage(bytes);
    } else if (imageInput is img.Image) {
      decoded = imageInput;
    }

    if (decoded == null) {
      throw Exception('Gagal mendekode gambar untuk klasifikasi.');
    }

    // Resize ke 224x224 RGB
    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Siapkan input tensor [1, 224, 224, 3] float32 piksel [0.0 - 255.0]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    // Output buffer [1, 6]
    final output = List.generate(1, (_) => List.filled(classNames.length, 0.0));

    // Jalankan inferensi TFLite
    _interpreter!.run(input, output);

    final probabilities = output[0];
    int maxIdx = 0;
    double maxConf = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConf) {
        maxConf = probabilities[i];
        maxIdx = i;
      }
    }

    return {
      'predicted_class': classNames[maxIdx],
      'confidence': maxConf,
      'probabilities': probabilities,
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
