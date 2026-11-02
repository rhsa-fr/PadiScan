import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';
import '../theme/app_theme.dart';
import '../widgets/padiscan_logo.dart';
import 'recommendation_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  final DiagnosisResult result;

  const DiagnosisScreen({super.key, required this.result});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  int _selectedStage = 0; // 0: Asli, 1: ExG Klorofil, 2: Mask Daun, 3: Peta Lesi

  final List<Map<String, dynamic>> _stages = const [
    {
      'title': 'Foto Asli',
      'short': '1. Asli',
      'desc': 'Citra RGB asli masukan kamera tanpa manipulasi.',
      'formula': 'Input RGB (224×224×3)',
    },
    {
      'title': 'Indeks Klorofil (ExG)',
      'short': '2. ExG',
      'desc': 'Excess Green menonjolkan jaringan klorofil dan meredam latar tanah/air.',
      'formula': 'ExG = (2G - R - B) / (R + G + B)',
    },
    {
      'title': 'Mask Daun (Otsu)',
      'short': '3. Mask Daun',
      'desc': 'Segmentasi biner ambang batas Otsu dan penutupan morfologi (closing r=6).',
      'formula': 'Otsu Binarization + Morph Close',
    },
    {
      'title': 'Peta Lesi (CIELab)',
      'short': '4. Peta Lesi',
      'desc': 'Deteksi bercak nekrosis cokelat (CIELab a* > 4.0) dan klorosis hawar.',
      'formula': 'CIELab a* > 4.0 ∪ Klorosis',
    },
  ];

  String _getStageImagePath(DiagnosisResult res, int stage) {
    if (stage == 1 && res.exgImagePath != null && File(res.exgImagePath!).existsSync()) {
      return res.exgImagePath!;
    }
    if (stage == 2 && res.leafMaskImagePath != null && File(res.leafMaskImagePath!).existsSync()) {
      return res.leafMaskImagePath!;
    }
    if (stage == 3 && res.overlayImagePath != null && File(res.overlayImagePath!).existsSync()) {
      return res.overlayImagePath!;
    }
    return res.imagePath;
  }

  Color _getDiseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('sehat') || d.contains('healthy')) {
      return AppTheme.primaryContainer;
    } else if (d.contains('blas') || d.contains('blast')) {
      return const Color(0xFFC2410C); // burnt orange
    } else if (d.contains('kresek') || d.contains('blight') || d.contains('hawar daun bakteri')) {
      return const Color(0xFFB91C1C); // red
    } else {
      return const Color(0xFFB45309); // amber
    }
  }

  String _getLatinName(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('blas') || d.contains('blast')) {
      return 'Pyricularia oryzae';
    } else if (d.contains('bercak') || d.contains('brown')) {
      return 'Bipolaris oryzae';
    } else if (d.contains('kresek') || d.contains('hawar daun bakteri') || (d.contains('blight') && d.contains('bacterial'))) {
      return 'Xanthomonas oryzae pv. oryzae';
    } else if (d.contains('sehat') || d.contains('healthy')) {
      return 'Tanaman Sehat Bebas Gejala';
    } else if (d.contains('bergaris') || d.contains('scald')) {
      return 'Microdochium oryzae';
    } else if (d.contains('pelepah') || d.contains('sheath')) {
      return 'Rhizoctonia solani';
    } else {
      return 'Patogen Daun Padi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final diseaseColor = _getDiseaseColor(res.predictedClass);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const PadiScanLogo(size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hasil Diagnosis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'ID #${res.id.substring(0, res.id.length > 8 ? 8 : res.id.length)} • ${res.plotName}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Laporan siap dibagikan')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peringatan Objek Bukan Daun
            if (!res.isLeaf)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Peringatan: Citra tidak terdeteksi sebagai daun padi asli. Hasil prediksi ini mungkin tidak akurat.',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 1. Tampilan Gambar dengan Switcher 4 Tahap Visi Komputer
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 270,
                    width: double.infinity,
                    color: Colors.black,
                    child: Image.file(
                      File(_getStageImagePath(res, _selectedStage)),
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Stage Switcher Chips Bar di bawah gambar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_stages.length, (idx) {
                          final isSelected = _selectedStage == idx;
                          final stage = _stages[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedStage = idx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryContainer
                                      : Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4ADE80)
                                        : Colors.white24,
                                    width: isSelected ? 1.5 : 0.8,
                                  ),
                                ),
                                child: Text(
                                  stage['short'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Keterangan Tahap Pengolahan Citra Digital Terpilih
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selectedStage + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _stages[_selectedStage]['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            Text(
                              _stages[_selectedStage]['formula'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stages[_selectedStage]['desc'] as String,
                          style: const TextStyle(fontSize: 11, color: AppTheme.secondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Kartu Nama Penyakit & Tingkat Keyakinan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.predictedClass,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: diseaseColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getLatinName(res.predictedClass),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: res.confidence),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: diseaseColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(value * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: diseaseColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Quality Gate Status Pill
                    Row(
                      children: [
                        Icon(
                          res.qualityPassed ? Icons.verified : Icons.warning_amber_rounded,
                          size: 18,
                          color: res.qualityPassed ? AppTheme.primaryContainer : AppTheme.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            res.qualityPassed
                                ? 'Quality Gate Lolos: Citra tajam & pencahayaan optimal'
                                : 'Peringatan: ${res.rejectReason ?? "Kualitas citra rendah"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: res.qualityPassed ? AppTheme.primaryContainer : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Kartu Tingkat Keparahan Lesi (0 - 4)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tingkat Keparahan Lesi',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(res.severityScore).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            res.severityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(res.severityScore),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5-Segment Bar dengan Animasi Pengisian
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: res.severityScore.toDouble()),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutBack,
                      builder: (context, animValue, _) {
                        return Row(
                          children: List.generate(5, (index) {
                            final isActive = index <= animValue.round() && animValue > 0.05;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 8,
                                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _getSeverityColor(res.severityScore)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0: Sehat', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                        Text('1: ≤5%', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                        Text('2: 5-15%', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                        Text('3: 15-30%', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                        Text('4: >30%', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rasio Luas Lesi:', style: TextStyle(fontSize: 13)),
                          Text(
                            '${(res.lesionRatio * 100).toStringAsFixed(2)}% luas daun',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Tombol Aksi
            if (!res.predictedClass.toLowerCase().contains('healthy') &&
                !res.predictedClass.toLowerCase().contains('sehat'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services_outlined, size: 20),
                  label: const Text('Lihat Rekomendasi Pengendalian'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecommendationScreen(result: res),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Pemindai'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int score) {
    switch (score) {
      case 0:
        return AppTheme.primaryContainer;
      case 1:
        return const Color(0xFFEAB308); // yellow
      case 2:
        return const Color(0xFFF97316); // orange
      case 3:
        return const Color(0xFFEA580C); // dark orange
      case 4:
        return const Color(0xFFDC2626); // red
      default:
        return AppTheme.secondary;
    }
  }
}
