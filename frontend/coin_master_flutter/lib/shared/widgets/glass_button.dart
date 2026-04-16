import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;

  const GlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.purple;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [color.withAlpha(230), color])
                : null,
            color: widget.isPrimary ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: widget.isPrimary ? null : Border.all(color: color, width: 2),
            boxShadow: widget.isPrimary
                ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          child: widget.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.isPrimary ? AppColors.textWhite : color, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15,
                          color: widget.isPrimary ? AppColors.textWhite : color,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}
