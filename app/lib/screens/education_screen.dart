import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/padiscan_logo.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Penyakit Daun',
    'Panduan Pupuk',
    'Info Cuaca',
    'Hama Padi',
  ];

  final List<Map<String, String>> _diseases = [
    {
      'name': 'Leaf Blast (Blas Daun)',
      'latin': 'Pyricularia oryzae',
      'desc': 'Bercak berbentuk belah ketupat runcing di kedua ujung dengan pusat kelabu/putih dan tepi cokelat tua.',
      'threat': 'Tinggi saat musim hujan',
      'tag': 'Jamur',
    },
    {
      'name': 'Brown Spot (Bercak Cokelat)',
      'latin': 'Bipolaris oryzae',
      'desc': 'Bercak bulat hingga oval berwarna cokelat tua merata, sering disebabkan ketidakseimbangan hara Kalium atau tanah masam.',
      'threat': 'Sedang (fase vegetatif)',
      'tag': 'Jamur/Nutrisi',
    },
    {
      'name': 'Bacterial Leaf Blight (Kresek/BLB)',
      'latin': 'Xanthomonas oryzae',
      'desc': 'Garis lesi kuning keputihan di sepanjang tepi helai daun yang mengering bergelombang.',
      'threat': 'Sangat menular via air',
      'tag': 'Bakteri',
    },
    {
      'name': 'Leaf Scald (Hawar Pelepah/Daun)',
      'latin': 'Microdochium oryzae',
      'desc': 'Lesi besar berpola cincin konsentris abu-abu kecokelatan di ujung daun.',
      'threat': 'Sedang',
      'tag': 'Jamur',
    },
  ];

  final List<Map<String, String>> _articles = [
    {
      'title': 'Dosis Tepat Pemupukan Berimbang N-P-K untuk Cegah Daun Rebah dan Blas',
      'time': '4 menit baca',
      'category': 'Panduan Pupuk',
    },
    {
      'title': 'Mengenal Perbedaan Gejala Bercak Cokelat Akibat Jamur vs Kekurangan Hara Kalium',
      'time': '3 menit baca',
      'category': 'Penyakit Daun',
    },
    {
      'title': 'Sistem Pengairan Berselang (AWD) untuk Menekan Kelembapan dan Serangan Bakteri',
      'time': '5 menit baca',
      'category': 'Manajemen Lahan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            PadiScanLogo(size: 24),
            SizedBox(width: 8),
            Text('Pusat Edukasi Padi'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari penyakit, obat, atau gejala...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.secondary),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.secondary),
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Kategori Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final active = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: active,
                      selectedColor: AppTheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : AppTheme.onSurface,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Featured Article Banner
            Card(
              color: const Color(0xFF14532D), // dark emerald
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ARTIKEL UTAMA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF052E16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Antisipasi Ledakan Penyakit Blas di Musim Penghujan: Waktu Terbaik Penyemprotan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '5 menit baca • Ditinjau Balai Proteksi Tanaman Pertanian',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Katalog Penyakit Padi
            const Text(
              'Katalog Penyakit Daun Padi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _diseases.length,
              itemBuilder: (context, idx) {
                final d = _diseases[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                d['name']!,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d['tag']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          d['latin']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['desc']!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Risiko: ${d['threat']}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Feed Artikel Lapangan
            const Text(
              'Panduan Lapangan Terkini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ..._articles.map((art) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    art['title']!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${art['category']} • ${art['time']}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membuka ${art['title']}')),
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
