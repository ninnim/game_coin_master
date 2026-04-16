import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.gold;
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp:
          widget.onTap != null
              ? (_) {
                _ctrl.reverse();
                widget.onTap?.call();
              }
              : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isPrimary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 1.5),
            boxShadow:
                widget.isPrimary
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child:
              widget.isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color:
                          widget.isPrimary ? AppColors.background : color,
                      strokeWidth: 2,
                    ),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color:
                              widget.isPrimary
                                  ? AppColors.background
                                  : color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color:
                              widget.isPrimary ? AppColors.background : color,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
