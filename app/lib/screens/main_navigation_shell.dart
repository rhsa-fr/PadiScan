import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';
import 'education_screen.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final ClassifierService classifierService;

  const MainNavigationShell({
    super.key,
    this.cameras,
    required this.classifierService,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ScannerScreen(
        cameras: widget.cameras,
        classifierService: widget.classifierService,
      ),
      const HistoryScreen(),
      const EducationScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.surfaceContainerHigh,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner, color: AppTheme.primaryContainer),
            label: 'Pindai Daun',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primaryContainer),
            label: 'Riwayat Lahan',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppTheme.primaryContainer),
            label: 'Pusat Edukasi',
          ),
        ],
      ),
    );
  }
}
