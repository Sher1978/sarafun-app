
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.6), // Semi-transparent card
              borderRadius: radius,
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
