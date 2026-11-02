import 'package:flutter/material.dart';
import '../models/diagnosis_result.dart';
import '../theme/app_theme.dart';

class RecommendationScreen extends StatelessWidget {
  final DiagnosisResult result;

  const RecommendationScreen({super.key, required this.result});

  Map<String, dynamic> _getRecommendations(String disease, int severity) {
    final d = disease.toLowerCase();
    if (d.contains('blas') || d.contains('blast')) {
      return {
        'urgency': 'Tindakan diperlukan dalam 24–48 jam untuk mencegah infeksi busuk leher malai (neck blast).',
        'chemical': 'Semprot fungisida berbahan aktif Trisiklazol (contoh: Beam 75 WP) dosis 1.5–2.0 g/L atau Difenokonazol (Score 250 EC) dosis 1.5 ml/L.',
        'cultural': 'Hentikan aplikasi pupuk Urea/Nitrogen berlebih. Tambahkan pupuk Kalium (KCL) dosis 50 kg/ha untuk memperkuat dinding sel daun.',
        'water': 'Terapkan pengairan berselang (intermittent). Keringkan petak sawah selama 3-4 hari untuk menurunkan kelembapan kanopi tanaman.',
      };
    } else if (d.contains('bercak') || d.contains('brown')) {
      return {
        'urgency': 'Bercak cokelat mengindikasikan ketidakseimbangan hara tanah atau kekurangan Kalium & Silika.',
        'chemical': 'Aplikasi fungisida berbahan aktif Mankozeb 80% (Dithane M-45) dosis 2.0 g/L atau Azoksistrobin + Difenokonazol dosis 1.0 ml/L.',
        'cultural': 'Beri pupuk berimbang N-P-K dan tambahkan pupuk silika organik. Perbaiki drainase lahan agar tanah tidak terlalu masam.',
        'water': 'Pertahankan genangan air dangkal (2–3 cm) untuk mencegah kekeringan mikro pada perakaran padi.',
      };
    } else if (d.contains('kresek') || d.contains('hawar daun bakteri') || (d.contains('blight') && d.contains('bacterial'))) {
      return {
        'urgency': 'Penyakit bakteri sistemik (Kresek). Jangan gunakan fungisida biasa karena tidak efektif terhadap bakteri.',
        'chemical': 'Gunakan bakterisida berbahan aktif Oksitetrasiklin atau Tembaga Hidroksida (Kocide 54 WDG) dosis 1.5 g/L. Semprot saat pagi hari.',
        'cultural': 'Kurangi dosis Urea hingga 30%. Buang dan bakar daun yang terserang parah dari pematang.',
        'water': 'Keringkan sawah dan hindari pengaliran air dari petak yang terinfeksi ke petak yang masih sehat.',
      };
    } else if (d.contains('sehat') || d.contains('healthy')) {
      return {
        'urgency': 'Kondisi tanaman sehat prima. Terus pantau kebersihan pematang secara berkala.',
        'chemical': 'Tidak diperlukan pestisida sintetis. Berikan pupuk hayati atau mikroba pengurai bila perlu.',
        'cultural': 'Pertahankan pemupukan berimbang N-P-K sesuai anjuran rekomendasi penyuluh pertanian setempat.',
        'water': 'Pertahankan pengairan teratur sesuai siklus umur tanaman.',
      };
    } else {
      return {
        'urgency': 'Lakukan pemantauan harian pada petak sawah yang bergejala.',
        'chemical': 'Gunakan fungisida protektif berbahan aktif Mankozeb atau Propineb sesuai dosis anjuran.',
        'cultural': 'Jaga kebersihan pematang sawah dari gulma inang patogen.',
        'water': 'Atur pengairan secara bergilir untuk menjaga sirkulasi udara di kanopi tanaman.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = _getRecommendations(result.predictedClass, result.severityScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Tindakan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Urgensi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.alarm, color: AppTheme.warning, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec['urgency'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card 1: Pengendalian Kimiawi
            _buildActionCard(
              icon: Icons.science_outlined,
              iconColor: const Color(0xFF2563EB),
              title: '1. Pengendalian Kimiawi / Kimia Tepat',
              tag: 'Aplikasi Segera',
              tagColor: const Color(0xFF2563EB),
              content: rec['chemical'] as String,
            ),

            const SizedBox(height: 12),

            // Card 2: Kultur Teknis & Nutrisi
            _buildActionCard(
              icon: Icons.eco_outlined,
              iconColor: AppTheme.primaryContainer,
              title: '2. Kultur Teknis & Pengaturan Pupuk',
              tag: 'Perbaikan Hara',
              tagColor: AppTheme.primaryContainer,
              content: rec['cultural'] as String,
            ),

            const SizedBox(height: 12),

            // Card 3: Manajemen Pengairan
            _buildActionCard(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF0891B2),
              title: '3. Tata Kelola Air Sawah',
              tag: 'Sanitasi Kanopi',
              tagColor: const Color(0xFF0891B2),
              content: rec['water'] as String,
            ),

            const SizedBox(height: 24),

            // Tombol Kontak PPL & Selesai
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_in_talk, size: 20),
                label: const Text('Hubungi Petugas PPL Indramayu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.onSurface,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menghubungi Balai Penyuluhan Pertanian (BPP) Kab. Indramayu...')),
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
                child: const Text('Tandai Telah Dilakukan'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status lahan diperbarui')),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String tag,
    required Color tagColor,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
