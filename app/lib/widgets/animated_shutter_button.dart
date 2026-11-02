import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedShutterButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isProcessing;

  const AnimatedShutterButton({
    super.key,
    required this.onTap,
    this.isProcessing = false,
  });

  @override
  State<AnimatedShutterButton> createState() => _AnimatedShutterButtonState();
}

class _AnimatedShutterButtonState extends State<AnimatedShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isProcessing ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cincin luar berdenyut halus
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Lingkaran pembatas putih tegas
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                    ),
                  ),

                  // Tombol inti hijau zamrud
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF00652C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF16A34A),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: widget.isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
