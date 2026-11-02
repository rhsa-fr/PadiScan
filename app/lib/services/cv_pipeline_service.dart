import 'dart:math';
import 'package:image/image.dart' as img;

class CVPipelineResult {
  final bool qualityPassed;
  final bool isLeaf;
  final double blurScore;
  final double brightness;
  final double leafAreaRatio;
  final String? rejectReason;
  final double lesionRatio;
  final int severityScore;
  final img.Image? overlayImage;
  final img.Image? exgImage;
  final img.Image? leafMaskImage;

  CVPipelineResult({
    required this.qualityPassed,
    this.isLeaf = true,
    required this.blurScore,
    required this.brightness,
    required this.leafAreaRatio,
    this.rejectReason,
    required this.lesionRatio,
    required this.severityScore,
    this.overlayImage,
    this.exgImage,
    this.leafMaskImage,
  });
}

class CVPipelineService {
  /// Memproses citra dengan pengolahan citra klasik (Quality Gate, ExG, CIELab, Severity)
  static CVPipelineResult process(img.Image original) {
    // 1. Skala turun citra untuk komputasi cepat di ponsel jika resolusi sangat besar (> 640px)
    final int maxDim = max(original.width, original.height);
    final img.Image workingImg = maxDim > 640
        ? img.copyResize(
            original,
            width: original.width > original.height ? 640 : null,
            height: original.height >= original.width ? 640 : null,
            interpolation: img.Interpolation.linear,
          )
        : original;

    final int width = workingImg.width;
    final int height = workingImg.height;
    final int totalPixels = width * height;

    // 2. Laplacian Blur Check
    final double blurScore = _computeLaplacianVariance(workingImg);

    // 3. Brightness Check
    final double brightness = _computeBrightness(workingImg);

    // 4. Quality Gate tahap 1: Blur & Cahaya
    final List<String> rejectReasons = [];
    if (blurScore < 60.0) {
      rejectReasons.add('Citra buram / fokus kurang tajam (skor: ${blurScore.toStringAsFixed(1)})');
    }
    if (brightness < 40.0) {
      rejectReasons.add('Pencahayaan terlalu gelap (${brightness.toStringAsFixed(1)})');
    } else if (brightness > 225.0) {
      rejectReasons.add('Pencahayaan terlalu terang / silau (${brightness.toStringAsFixed(1)})');
    }

    // 5. ExG (Excess Green) + Otsu Binarization untuk segmentasi daun
    final List<double> exgValues = List.filled(totalPixels, 0.0);
    final List<int> exg8Bit = List.filled(totalPixels, 0);

    double minExg = double.infinity;
    double maxExg = -double.infinity;

    int idx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = workingImg.getPixel(x, y);
        final double r = p.r.toDouble();
        final double g = p.g.toDouble();
        final double b = p.b.toDouble();
        final double sum = r + g + b + 0.00001;

        // Formula ExG: 2g - r - b
        final double exg = (2.0 * g - r - b) / sum;
        exgValues[idx] = exg;
        if (exg < minExg) minExg = exg;
        if (exg > maxExg) maxExg = exg;
        idx++;
      }
    }

    // Normalisasi ExG ke rentang 0 - 255
    final double exgRange = (maxExg - minExg) > 0 ? (maxExg - minExg) : 1.0;
    for (int i = 0; i < totalPixels; i++) {
      final val = ((exgValues[i] - minExg) / exgRange * 255.0).clamp(0.0, 255.0).round();
      exg8Bit[i] = val;
    }

    final int otsuThreshold = _calculateOtsuThreshold(exg8Bit);

    // Buat Leaf Mask awal dari Otsu
    List<bool> rawLeafMask = List.filled(totalPixels, false);
    for (int i = 0; i < totalPixels; i++) {
      if (exg8Bit[i] >= otsuThreshold) {
        rawLeafMask[i] = true;
      }
    }

    // Operasi Morfologi Closing untuk menutup lubang lesi di dalam helai daun
    final List<bool> leafMask = _morphologicalClose(rawLeafMask, width, height, radius: 6);

    int leafPixelCount = 0;
    for (int i = 0; i < totalPixels; i++) {
      if (leafMask[i]) leafPixelCount++;
    }

    final double leafAreaRatio = leafPixelCount / totalPixels;
    if (leafAreaRatio < 0.06) {
      rejectReasons.add('Daun terlalu kecil/jauh (${(leafAreaRatio * 100).toStringAsFixed(1)}% < 6%)');
    }

    // Validasi apakah objek merupakan daun / jaringan vegetasi tanaman
    double totalExg = 0.0;
    int greenVegCount = 0;
    for (int i = 0; i < totalPixels; i++) {
      totalExg += exgValues[i];
      if (exgValues[i] > 0.05) {
        greenVegCount++;
      }
    }
    final double meanExg = totalExg / totalPixels;
    final double greenVegRatio = greenVegCount / totalPixels;
    final bool isLeaf = greenVegRatio >= 0.05 && meanExg > -0.05 && leafAreaRatio >= 0.04;
    if (!isLeaf) {
      rejectReasons.add('Objek bukan daun padi (tidak terdeteksi klorofil/jaringan tanaman)');
    }

    // 6. Deteksi Lesi pada piksel daun dengan CIELab kanal a* & Klorosis ExG
    final List<bool> lesionMask = List.filled(totalPixels, false);
    int lesionPixelCount = 0;

    idx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (leafMask[idx]) {
          final p = workingImg.getPixel(x, y);
          final double aStar = _computeCieLabA(p.r.toDouble(), p.g.toDouble(), p.b.toDouble());
          // a* > 4.0 (nekrosis cokelat/merah) ATAU klorosis hawar menguning (ExG < 0.05 pada area daun)
          if (aStar > 4.0 || exgValues[idx] < 0.05) {
            lesionMask[idx] = true;
            lesionPixelCount++;
          }
        }
        idx++;
      }
    }

    // Rasio lesi terhadap total daun
    final double lesionRatio = leafPixelCount > 0 ? (lesionPixelCount / leafPixelCount) : 0.0;

    // Skor keparahan 0-4
    int severityScore = 0;
    if (lesionRatio > 0.30) {
      severityScore = 4;
    } else if (lesionRatio > 0.15) {
      severityScore = 3;
    } else if (lesionRatio > 0.05) {
      severityScore = 2;
    } else if (lesionRatio > 0.001) {
      severityScore = 1;
    }

    // 7. Buat citra intermediate tahapan visi komputer
    // 7a. Citra Indeks Klorofil ExG (Grayscale 8-bit)
    final img.Image exgImg = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int val = exg8Bit[y * width + x];
        exgImg.setPixelRgb(x, y, val, val, val);
      }
    }

    // 7b. Citra Mask Daun Segmentasi Otsu + Closing (Biner Hitam Putih)
    final img.Image leafMaskImg = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int val = leafMask[y * width + x] ? 255 : 0;
        leafMaskImg.setPixelRgb(x, y, val, val, val);
      }
    }

    // 7c. Citra Peta Overlay Lesi CIELab + Klorosis
    final img.Image overlayImg = workingImg.clone();
    idx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (lesionMask[idx]) {
          final p = overlayImg.getPixel(x, y);
          // Campurkan warna oranye-merah terang (255, 80, 0)
          final nr = (p.r * 0.35 + 255 * 0.65).round().clamp(0, 255);
          final ng = (p.g * 0.35 + 60 * 0.65).round().clamp(0, 255);
          final nb = (p.b * 0.35 + 0 * 0.65).round().clamp(0, 255);
          overlayImg.setPixelRgb(x, y, nr, ng, nb);
        }
        idx++;
      }
    }

    final bool qualityPassed = rejectReasons.isEmpty;

    return CVPipelineResult(
      qualityPassed: qualityPassed,
      isLeaf: isLeaf,
      blurScore: blurScore,
      brightness: brightness,
      leafAreaRatio: leafAreaRatio,
      rejectReason: rejectReasons.isEmpty ? null : rejectReasons.join('; '),
      lesionRatio: lesionRatio,
      severityScore: severityScore,
      overlayImage: overlayImg,
      exgImage: exgImg,
      leafMaskImage: leafMaskImg,
    );
  }

  /// Menghitung varian Laplacian untuk deteksi blur
  static double _computeLaplacianVariance(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    if (width < 3 || height < 3) return 0.0;

    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // Luminansi piksel sekitar
        final double center = image.getPixel(x, y).luminanceNormalized * 255.0;
        final double top = image.getPixel(x, y - 1).luminanceNormalized * 255.0;
        final double bottom = image.getPixel(x, y + 1).luminanceNormalized * 255.0;
        final double left = image.getPixel(x - 1, y).luminanceNormalized * 255.0;
        final double right = image.getPixel(x + 1, y).luminanceNormalized * 255.0;

        // Laplacian 3x3: top + bottom + left + right - 4 * center
        final double lap = top + bottom + left + right - 4.0 * center;
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final double mean = sum / count;
    final double variance = (sumSq / count) - (mean * mean);
    return max(0.0, variance);
  }

  /// Menghitung rata-rata intensitas pencahayaan
  static double _computeBrightness(img.Image image) {
    double totalLum = 0.0;
    final int count = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        totalLum += image.getPixel(x, y).luminanceNormalized * 255.0;
      }
    }
    return count > 0 ? (totalLum / count) : 0.0;
  }

  /// Morfologi closing (Dilation diikuti Erosion) untuk menutup lubang pada daun
  static List<bool> _morphologicalClose(List<bool> mask, int width, int height, {int radius = 3}) {
    // 1. Dilate secara separabel (Horizontal kemudian Vertikal)
    final tempDilated = List.filled(width * height, false);
    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        if (mask[rowOffset + x]) {
          final startX = max(0, x - radius);
          final endX = min(width - 1, x + radius);
          for (int nx = startX; nx <= endX; nx++) {
            tempDilated[rowOffset + nx] = true;
          }
        }
      }
    }

    final dilated = List.filled(width * height, false);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        if (tempDilated[y * width + x]) {
          final startY = max(0, y - radius);
          final endY = min(height - 1, y + radius);
          for (int ny = startY; ny <= endY; ny++) {
            dilated[ny * width + x] = true;
          }
        }
      }
    }

    // 2. Erode secara separabel
    final tempEroded = List.filled(width * height, false);
    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        bool allTrue = true;
        final startX = max(0, x - radius);
        final endX = min(width - 1, x + radius);
        for (int nx = startX; nx <= endX; nx++) {
          if (!dilated[rowOffset + nx]) {
            allTrue = false;
            break;
          }
        }
        tempEroded[rowOffset + x] = allTrue;
      }
    }

    final closed = List.filled(width * height, false);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        bool allTrue = true;
        final startY = max(0, y - radius);
        final endY = min(height - 1, y + radius);
        for (int ny = startY; ny <= endY; ny++) {
          if (!tempEroded[ny * width + x]) {
            allTrue = false;
            break;
          }
        }
        closed[y * width + x] = allTrue;
      }
    }

    return closed;
  }

  /// Ambang batas Otsu otomatis
  static int _calculateOtsuThreshold(List<int> values) {
    final List<int> hist = List.filled(256, 0);
    for (final v in values) {
      hist[v.clamp(0, 255)]++;
    }

    final int total = values.length;
    double sum = 0.0;
    for (int i = 0; i < 256; i++) {
      sum += i * hist[i];
    }

    double sumB = 0.0;
    int wB = 0;
    double maxVar = 0.0;
    int threshold = 128;

    for (int t = 0; t < 256; t++) {
      wB += hist[t];
      if (wB == 0) continue;
      final int wF = total - wB;
      if (wF == 0) break;

      sumB += t * hist[t];
      final double mB = sumB / wB;
      final double mF = (sum - sumB) / wF;

      final double varBetween = wB.toDouble() * wF.toDouble() * (mB - mF) * (mB - mF);
      if (varBetween > maxVar) {
        maxVar = varBetween;
        threshold = t;
      }
    }

    return threshold;
  }

  /// Konversi RGB ke CIELab kanal a*
  static double _computeCieLabA(double r, double g, double b) {
    // 1. Normalisasi sRGB ke linier
    double rl = r / 255.0;
    double gl = g / 255.0;
    double bl = b / 255.0;

    rl = (rl > 0.04045) ? pow((rl + 0.055) / 1.055, 2.4).toDouble() : rl / 12.92;
    gl = (gl > 0.04045) ? pow((gl + 0.055) / 1.055, 2.4).toDouble() : gl / 12.92;
    bl = (bl > 0.04045) ? pow((bl + 0.055) / 1.055, 2.4).toDouble() : bl / 12.92;

    // 2. Linear sRGB ke XYZ (D65)
    final double x = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) * 100.0;
    final double y = (rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750) * 100.0;

    // D65 reference white
    const double xn = 95.047;
    const double yn = 100.0;

    double fx = x / xn;
    double fy = y / yn;

    fx = (fx > 0.008856) ? pow(fx, 1.0 / 3.0).toDouble() : (7.787 * fx) + (16.0 / 116.0);
    fy = (fy > 0.008856) ? pow(fy, 1.0 / 3.0).toDouble() : (7.787 * fy) + (16.0 / 116.0);

    return 500.0 * (fx - fy);
  }
}
