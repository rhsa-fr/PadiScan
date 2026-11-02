import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diagnosis_result.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/padiscan_logo.dart';
import 'diagnosis_screen.dart';
import 'recommendation_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToScanner;

  const HistoryScreen({
    super.key,
    this.onNavigateToScanner,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DiagnosisResult> _history = [];
  bool _isLoading = true;
  String _activeFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Perlu Tindakan',
    'Leaf Blast',
    'Brown Spot',
    'Bacterial Leaf Blight',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Mendengarkan perubahan data riwayat secara real-time
    HistoryService.historyNotifier.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    HistoryService.historyNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  List<DiagnosisResult> get _filteredHistory {
    if (_activeFilter == 'Semua') return _history;
    if (_activeFilter == 'Perlu Tindakan') {
      return _history.where((item) => !item.predictedClass.toLowerCase().contains('healthy')).toList();
    }
    return _history.where((item) => item.predictedClass == _activeFilter).toList();
  }

  int _countForFilter(String filter) {
    if (filter == 'Semua') return _history.length;
    if (filter == 'Perlu Tindakan') {
      return _history.where((item) => !item.predictedClass.toLowerCase().contains('healthy')).length;
    }
    return _history.where((item) => item.predictedClass == filter).length;
  }

  String _getLatinTaxonomy(String disease) {
    final lower = disease.toLowerCase();
    if (lower.contains('blast')) return 'Pyricularia oryzae';
    if (lower.contains('brown')) return 'Bipolaris oryzae';
    if (lower.contains('blight') && lower.contains('bacterial')) return 'Xanthomonas oryzae pv. oryzae';
    if (lower.contains('scald')) return 'Microdochium oryzae';
    if (lower.contains('sheath')) return 'Rhizoctonia solani';
    if (lower.contains('healthy')) return 'Oryza sativa (Tanaman Sehat)';
    return 'Tanaman Padi Indramayu';
  }

  Color _getSeverityColor(int score) {
    switch (score) {
      case 0:
        return const Color(0xFF15803D); // Hijau Prima
      case 1:
        return const Color(0xFFEAB308); // Kuning Ringan
      case 2:
        return const Color(0xFFF97316); // Oranye Sedang
      case 3:
        return const Color(0xFFEA580C); // Jingga Berat
      case 4:
      default:
        return const Color(0xFFDC2626); // Merah Sangat Berat
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _history.length;
    final infectedCount = _history.where((i) => !i.predictedClass.toLowerCase().contains('healthy')).length;
    final healthyCount = totalScans - infectedCount;
    final infectedPct = totalScans > 0 ? (infectedCount / totalScans * 100).toStringAsFixed(1) : '0';
    final healthyPct = totalScans > 0 ? (healthyCount / totalScans * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const PadiScanLogo(size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Riwayat & Monitoring',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Sentra Padi Indramayu • Jawa Barat',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.secondary),
              tooltip: 'Hapus Semua Riwayat',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Semua Riwayat?'),
                    content: const Text('Semua catatan scan dan gambar lokal di wilayah Indramayu akan dihapus permanen.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await HistoryService.clearAll();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer))
          : RefreshIndicator(
              color: AppTheme.primaryContainer,
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KPI Telemetry Summary Card (Stitch Design Style)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2B1D), Color(0xFF051B10)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'RINGKASAN LAHAN TERPANTAU',
                                    style: TextStyle(
                                      color: Color(0xFF86EFAC),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.bolt, size: 12, color: Color(0xFFFACC15)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Akurasi 88.8%',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3 Metric Stat Pillars
                          Row(
                            children: [
                              // Total Scan
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Total Scan',
                                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$totalScans',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Sampel Daun',
                                        style: TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Terinfeksi
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Terinfeksi',
                                        style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$infectedCount',
                                        style: const TextStyle(
                                          color: Color(0xFFF87171),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$infectedPct%',
                                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Daun Sehat
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Daun Sehat',
                                        style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$healthyCount',
                                        style: const TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$healthyPct%',
                                        style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Location Telemetry Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on, size: 14, color: Color(0xFF86EFAC)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Kec. Jatibarang & Balongan, Indramayu',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.offline_pin, size: 13, color: Color(0xFF4ADE80)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Tersimpan Offline',
                                    style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Horizontal Filter Carousel
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: _filters.map((filter) {
                          final selected = _activeFilter == filter;
                          final count = _countForFilter(filter);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => setState(() => _activeFilter = filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: selected ? AppTheme.primaryContainer : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (filter == 'Perlu Tindakan') ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        filter,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                          color: selected ? Colors.white : AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.white.withValues(alpha: 0.25)
                                              : AppTheme.secondary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: selected ? Colors.white : AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _activeFilter == 'Semua' ? 'Daftar Hasil Pemindaian' : 'Kategori: $_activeFilter',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_filteredHistory.length} data',
                          style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 3. Diagnosis Card List
                    if (_filteredHistory.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                size: 36,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Catatan Pemindaian',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Setiap kali Anda memindai daun padi di pemindai kamera, data diagnosis dan tingkat keparahan otomatis tersimpan langsung di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Mulai Pindai Daun Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryContainer,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: widget.onNavigateToScanner,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index];
                          final isInfected = !item.predictedClass.toLowerCase().contains('healthy');
                          final severityColor = _getSeverityColor(item.severityScore);
                          final latinTaxonomy = _getLatinTaxonomy(item.predictedClass);
                          final timeStr = DateFormat('HH:mm • dd MMM yyyy').format(item.timestamp);
                          final file = File(item.imagePath);

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (_) async {
                              await HistoryService.deleteResult(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Data riwayat berhasil dihapus'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DiagnosisScreen(result: item),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        // Baris Atas: Thumbnail + Detail Penyakit
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Image Thumbnail with AI Badge
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    width: 76,
                                                    height: 76,
                                                    color: const Color(0xFF0F172A),
                                                    child: file.existsSync()
                                                        ? Image.file(file, fit: BoxFit.cover)
                                                        : const Center(
                                                            child: Icon(Icons.broken_image, color: Colors.white38),
                                                          ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  left: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.75),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${(item.confidence * 100).toStringAsFixed(0)}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),

                                            // Deskripsi & Keparahan
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.predictedClass,
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppTheme.onSurface,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      // Severity Badge Pill
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: severityColor.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: severityColor.withValues(alpha: 0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item.severityLabel,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w800,
                                                            color: severityColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    latinTaxonomy,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                      color: AppTheme.secondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.grid_view, size: 12, color: AppTheme.secondary),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          item.plotName,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme.onSurfaceVariant,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        // Baris Bawah: Footer & Action Strip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceContainerLow,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.schedule, size: 13, color: AppTheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.secondary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (isInfected)
                                                InkWell(
                                                  borderRadius: BorderRadius.circular(8),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => RecommendationScreen(result: item),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Icon(Icons.priority_high, size: 12, color: Color(0xFFDC2626)),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Tindakan',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFFDC2626),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0FDF4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                                  ),
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.verified, size: 12, color: Color(0xFF16A34A)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Sehat',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF16A34A),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
