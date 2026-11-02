import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PadiScanLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const PadiScanLogo({
    super.key,
    this.size = 36,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PadiScanLogoPainter(),
      ),
    );
  }
}

class _PadiScanLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Helai Daun Padi Utama (Gradasi Hijau Zamrud ke Lime)
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00652C), Color(0xFF16A34A), Color(0xFF86EFAC)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(w * 0.20, h * 0.85);
    // Lengkungan luar daun
    leafPath.cubicTo(w * 0.15, h * 0.45, w * 0.45, h * 0.15, w * 0.85, h * 0.12);
    // Lengkungan dalam daun balik ke pangkal
    leafPath.cubicTo(w * 0.65, h * 0.45, w * 0.55, h * 0.70, w * 0.20, h * 0.85);
    leafPath.close();

    canvas.drawPath(leafPath, leafPaint);

    // 2. Tulang Daun Minimalis
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = max(1.5, w * 0.04)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final veinPath = Path();
    veinPath.moveTo(w * 0.26, h * 0.78);
    veinPath.quadraticBezierTo(w * 0.48, h * 0.50, w * 0.78, h * 0.20);
    canvas.drawPath(veinPath, veinPaint);

    // 3. Titik Nodus AI Digital (Modern Tech Node)
    final nodePaint = Paint()
      ..color = const Color(0xFFFACC15) // Kuning emas bulir padi
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.85, h * 0.12), w * 0.09, nodePaint);

    // Lingkaran cincin pulse di nodus AI
    final ringPaint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.4)
      ..strokeWidth = max(1.0, w * 0.03)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), w * 0.15, ringPaint);

    // 4. Cincin Reticle Pemindai Minimalis di sekeliling daun
    final reticlePaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.7)
      ..strokeWidth = max(1.2, w * 0.035)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Busur kiri-bawah
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.45),
      pi * 0.75,
      pi * 0.45,
      false,
      reticlePaint,
    );
    // Busur kanan-atas
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.45),
      pi * 1.75,
      pi * 0.40,
      false,
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
