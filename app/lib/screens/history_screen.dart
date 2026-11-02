import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diagnosis_result.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/padiscan_logo.dart';
import 'diagnosis_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
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

  Color _getBadgeColor(String disease) {
    if (disease.toLowerCase().contains('healthy')) {
      return AppTheme.primaryContainer;
    } else if (disease.toLowerCase().contains('blast')) {
      return const Color(0xFFC2410C);
    } else if (disease.toLowerCase().contains('blight')) {
      return const Color(0xFFB91C1C);
    } else {
      return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _history.length;
    final infectedCount = _history.where((i) => !i.predictedClass.toLowerCase().contains('healthy')).length;
    final healthyCount = totalScans - infectedCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            PadiScanLogo(size: 24),
            SizedBox(width: 8),
            Text('Riwayat & Lahan'),
          ],
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Hapus Semua Riwayat',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Semua Riwayat?'),
                    content: const Text('Semua catatan scan dan gambar lokal akan dihapus permanen.'),
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
                  _loadHistory();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan Statistik Lahan
                    Row(
                      children: [
                        _buildStatCard('Total Scan', totalScans.toString(), AppTheme.secondary),
                        const SizedBox(width: 8),
                        _buildStatCard('Terinfeksi', infectedCount.toString(), const Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        _buildStatCard('Sehat', healthyCount.toString(), AppTheme.primaryContainer),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final selected = _activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: selected,
                              selectedColor: AppTheme.surfaceContainerHigh,
                              checkmarkColor: AppTheme.primaryContainer,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? AppTheme.primaryContainer : AppTheme.onSurface,
                              ),
                              onSelected: (_) => setState(() => _activeFilter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Daftar Riwayat Scan
                    if (_filteredHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.history_edu, size: 56, color: AppTheme.secondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat pemindaian',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gunakan kamera untuk memindai daun padi di sawah.',
                              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
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
                          final badgeColor = _getBadgeColor(item.predictedClass);
                          final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp);
                          final file = File(item.imagePath);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
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
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.black12,
                                        child: file.existsSync()
                                            ? Image.file(file, fit: BoxFit.cover)
                                            : const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Detail
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
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${(item.confidence * 100).toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.severityLabel} • Rasio: ${(item.lesionRatio * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 12, color: AppTheme.secondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeStr,
                                                style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppTheme.secondary, size: 20),
                                  ],
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

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
