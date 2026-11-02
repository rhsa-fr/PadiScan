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
  bool _showMask = false;

  Color _getDiseaseColor(String disease) {
    if (disease.toLowerCase().contains('healthy')) {
      return AppTheme.primaryContainer;
    } else if (disease.toLowerCase().contains('blast')) {
      return const Color(0xFFC2410C); // burnt orange
    } else if (disease.toLowerCase().contains('blight')) {
      return const Color(0xFFB91C1C); // red
    } else {
      return const Color(0xFFB45309); // amber
    }
  }

  String _getLatinName(String disease) {
    switch (disease) {
      case 'Leaf Blast':
        return 'Pyricularia oryzae';
      case 'Brown Spot':
        return 'Bipolaris oryzae';
      case 'Bacterial Leaf Blight':
        return 'Xanthomonas oryzae pv. oryzae';
      case 'Healthy':
        return 'Tanaman Sehat Bebas Gejala';
      case 'Leaf Scald':
        return 'Microdochium oryzae';
      case 'Sheath Blight':
        return 'Rhizoctonia solani';
      default:
        return 'Patogen Daun Padi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final diseaseColor = _getDiseaseColor(res.predictedClass);
    final hasOverlay = res.overlayImagePath != null && File(res.overlayImagePath!).existsSync();

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
            // 1. Tampilan Gambar dengan Toggle Mask Lesi
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 260,
                    width: double.infinity,
                    color: Colors.black,
                    child: _showMask && hasOverlay
                        ? Image.file(File(res.overlayImagePath!), fit: BoxFit.contain)
                        : Image.file(File(res.imagePath), fit: BoxFit.contain),
                  ),
                  if (hasOverlay)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleBtn('Foto Asli', !_showMask, () => setState(() => _showMask = false)),
                            _buildToggleBtn('Mask Lesi', _showMask, () => setState(() => _showMask = true)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
            if (!res.predictedClass.toLowerCase().contains('healthy'))
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

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white70,
          ),
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
