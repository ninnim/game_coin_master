import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SlotReelComponent extends PositionComponent {
  final List<String> symbols = ['🪙', '⚔️', '⛏️', '🛡️', '⚡', '⭐'];
  int _currentIndex = 0;
  bool _isSpinning = false;
  double _spinSpeed = 0;
  double _offset = 0;
  String? _targetSymbol;
  late TextComponent _symbolText;

  SlotReelComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    _symbolText = TextComponent(
      text: symbols[0],
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_symbolText);
  }

  void startSpin(String targetSymbol) {
    _targetSymbol = targetSymbol;
    _isSpinning = true;
    _spinSpeed = 15.0;
  }

  void stopAt(String symbol) {
    _targetSymbol = symbol;
    _currentIndex = symbols.indexOf(symbol).clamp(0, symbols.length - 1);
    _isSpinning = false;
    _spinSpeed = 0;
    _symbolText.text = symbols[_currentIndex];
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isSpinning) {
      _offset += _spinSpeed * dt;
      if (_offset >= 1.0) {
        _offset = 0;
        _currentIndex = (_currentIndex + 1) % symbols.length;
        _symbolText.text = symbols[_currentIndex];
      }
      _spinSpeed *= 0.99; // Decelerate
      if (_spinSpeed < 2.0 && _targetSymbol != null) {
        stopAt(_targetSymbol!);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw reel background
    final paint = Paint()
      ..color = const Color(0xFF1A1030)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = _isSpinning
          ? const Color(0x80FFD700)
          : const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    super.render(canvas);
  }
}
