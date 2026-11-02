class DiagnosisResult {
  final String id;
  final String imagePath;
  final String? overlayImagePath;
  final String? exgImagePath;
  final String? leafMaskImagePath;
  final String predictedClass;
  final double confidence;
  final int severityScore; // 0: Sehat, 1: Ringan, 2: Sedang, 3: Berat, 4: Sangat Berat
  final double lesionRatio; // Persentase 0.0 - 1.0
  final bool qualityPassed;
  final bool isLeaf;
  final double blurScore;
  final double brightness;
  final double leafAreaRatio;
  final String? rejectReason;
  final DateTime timestamp;
  final String plotName;

  DiagnosisResult({
    required this.id,
    required this.imagePath,
    this.overlayImagePath,
    this.exgImagePath,
    this.leafMaskImagePath,
    required this.predictedClass,
    required this.confidence,
    required this.severityScore,
    required this.lesionRatio,
    required this.qualityPassed,
    this.isLeaf = true,
    required this.blurScore,
    required this.brightness,
    required this.leafAreaRatio,
    this.rejectReason,
    required this.timestamp,
    this.plotName = 'Petak Sawah Utama',
  });

  String get severityLabel {
    switch (severityScore) {
      case 0:
        return 'Tingkat 0 (Sehat)';
      case 1:
        return 'Tingkat 1 (Ringan)';
      case 2:
        return 'Tingkat 2 (Sedang)';
      case 3:
        return 'Tingkat 3 (Berat)';
      case 4:
        return 'Tingkat 4 (Sangat Berat)';
      default:
        return 'Tingkat $severityScore';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'overlayImagePath': overlayImagePath,
        'exgImagePath': exgImagePath,
        'leafMaskImagePath': leafMaskImagePath,
        'predictedClass': predictedClass,
        'confidence': confidence,
        'severityScore': severityScore,
        'lesionRatio': lesionRatio,
        'qualityPassed': qualityPassed,
        'isLeaf': isLeaf,
        'blurScore': blurScore,
        'brightness': brightness,
        'leafAreaRatio': leafAreaRatio,
        'rejectReason': rejectReason,
        'timestamp': timestamp.toIso8601String(),
        'plotName': plotName,
      };

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) =>
      DiagnosisResult(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        overlayImagePath: json['overlayImagePath'] as String?,
        exgImagePath: json['exgImagePath'] as String?,
        leafMaskImagePath: json['leafMaskImagePath'] as String?,
        predictedClass: json['predictedClass'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        severityScore: json['severityScore'] as int,
        lesionRatio: (json['lesionRatio'] as num).toDouble(),
        qualityPassed: json['qualityPassed'] as bool,
        isLeaf: json['isLeaf'] as bool? ?? true,
        blurScore: (json['blurScore'] as num).toDouble(),
        brightness: (json['brightness'] as num).toDouble(),
        leafAreaRatio: (json['leafAreaRatio'] as num).toDouble(),
        rejectReason: json['rejectReason'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        plotName: json['plotName'] as String? ?? 'Petak Sawah Utama',
      );
}
