import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class VillageBackgroundComponent extends PositionComponent with HasGameReference<FlameGame> {
  final String skyColor;
  late Color _skyColor;

  VillageBackgroundComponent({required this.skyColor})
    : super(position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    try {
      _skyColor = Color(
        int.parse(skyColor.replaceFirst('#', 'FF'), radix: 16),
      );
    } catch (_) {
      _skyColor = const Color(0xFF1565C0);
    }
    size = game.size;
  }

  @override
  void render(Canvas canvas) {
    // Draw sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyColor.withOpacity(0.8), const Color(0xFF0A0A1A)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y * 0.6));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.6), skyPaint);

    // Draw ground
    final groundPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.55, size.x, size.y * 0.45),
      groundPaint,
    );
  }
}
