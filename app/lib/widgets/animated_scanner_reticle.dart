import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedScannerReticle extends StatefulWidget {
  final double size;
  final bool isScanning;

  const AnimatedScannerReticle({
    super.key,
    this.size = 260,
    this.isScanning = true,
  });

  @override
  State<AnimatedScannerReticle> createState() => _AnimatedScannerReticleState();
}

class _AnimatedScannerReticleState extends State<AnimatedScannerReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // 1. Kotak Border Utama dengan Sudut Berpendar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.12 * _pulseAnimation.value),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // 2. Empat Siku Sudut L-Brackets Minimalis
              ..._buildCornerBrackets(),

              // 3. Garis Laser Pemindai Animasi (Scan Line)
              if (widget.isScanning)
                Positioned(
                  top: widget.size * _scanAnimation.value,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF86EFAC),
                          Color(0xFF22C55E),
                          Color(0xFF86EFAC),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Badge Status AI di Pojok Kiri Atas
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AI DETEKSI AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerBrackets() {
    const double length = 22;
    const double thickness = 3.5;
    const Color cornerColor = Color(0xFF86EFAC);

    return [
      // Kiri Atas
      Positioned(
        top: -1,
        left: -1,
        child: _buildCorner(length, thickness, cornerColor, isTop: true, isLeft: true),
      ),
      // Kanan Atas
      Positioned(
        top: -1,
        right: -1,
        child: _buildCorner(length, thickness, cornerColor, isTop: true, isLeft: false),
      ),
      // Kiri Bawah
      Positioned(
        bottom: -1,
        left: -1,
        child: _buildCorner(length, thickness, cornerColor, isTop: false, isLeft: true),
      ),
      // Kanan Bawah
      Positioned(
        bottom: -1,
        right: -1,
        child: _buildCorner(length, thickness, cornerColor, isTop: false, isLeft: false),
      ),
    ];
  }

  Widget _buildCorner(
    double length,
    double thickness,
    Color color, {
    required bool isTop,
    required bool isLeft,
  }) {
    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          // Garis horizontal
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(thickness),
              ),
            ),
          ),
          // Garis vertikal
          Positioned(
            top: 0,
            bottom: 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(
              width: thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(thickness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
