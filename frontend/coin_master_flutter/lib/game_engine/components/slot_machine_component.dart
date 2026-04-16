import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'slot_reel_component.dart';

class SlotMachineComponent extends PositionComponent {
  late List<SlotReelComponent> _reels;
  bool _isSpinning = false;

  static const double reelWidth = 80;
  static const double reelHeight = 90;
  static const double reelSpacing = 10;

  SlotMachineComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(
          reelWidth * 3 + reelSpacing * 2 + 32,
          reelHeight + 40,
        ),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    _reels = List.generate(3, (i) {
      final reel = SlotReelComponent(
        position: Vector2(
          16 + i * (reelWidth + reelSpacing),
          20,
        ),
        size: Vector2(reelWidth, reelHeight),
      );
      return reel;
    });
    for (final reel in _reels) {
      add(reel);
    }
  }

  void spin(List<String> targets) {
    if (_isSpinning) return;
    _isSpinning = true;
    for (int i = 0; i < _reels.length; i++) {
      final target = i < targets.length ? targets[i] : 'coin_small';
      _reels[i].startSpin(_mapSlotToEmoji(target));
    }
    Future.delayed(const Duration(milliseconds: 2000), () {
      _isSpinning = false;
      for (int i = 0; i < _reels.length; i++) {
        final target = i < targets.length ? targets[i] : 'coin_small';
        _reels[i].stopAt(_mapSlotToEmoji(target));
      }
    });
  }

  String _mapSlotToEmoji(String slot) {
    switch (slot) {
      case 'attack': return '⚔️';
      case 'raid': return '⛏️';
      case 'shield': return '🛡️';
      case 'energy': return '⚡';
      case 'jackpot': return '⭐';
      default: return '🪙';
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw machine background
    final paint = Paint()
      ..color = const Color(0xB31A1030)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(16),
      ),
      paint,
    );

    // Draw gold border
    final borderPaint = Paint()
      ..color = const Color(0x4DFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(16),
      ),
      borderPaint,
    );

    super.render(canvas);
  }
}
