import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════
//  Coin Master-style UI widgets — pills, rails, badges, etc.
// ══════════════════════════════════════════════════════════════

/// Top-HUD pill (coin count, gem count, etc.) with left icon, value text,
/// and an optional "+" button on the right.
class CMCounterPill extends StatelessWidget {
  final Widget leadingIcon;
  final String value;
  final VoidCallback? onPlus;
  final Color background;
  final Color borderColor;
  final double maxWidth;

  const CMCounterPill({
    super.key,
    required this.leadingIcon,
    required this.value,
    this.onPlus,
    this.background = const Color(0xFF8E24AA),
    this.borderColor = const Color(0xFFFFD700),
    this.maxWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadingIcon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                shadows: [
                  Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                ],
              ),
            ),
          ),
          if (onPlus != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onPlus,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: const Center(
                  child: Text('+',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular icon button for the left/right rails — can show a timer
/// underneath, a badge number in the top-right corner, or nothing.
class CMRailIcon extends StatelessWidget {
  final String emoji;
  final String? timer;
  final String? badge;
  final Color accent;
  final VoidCallback? onTap;
  final bool small;

  const CMRailIcon({
    super.key,
    required this.emoji,
    this.timer,
    this.badge,
    this.accent = const Color(0xFFFFD700),
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 44.0 : 50.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
                    BoxShadow(color: Color(0x33FFFFFF), blurRadius: 1, offset: Offset(0, -1)),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: small ? 20 : 24)),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 3),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (timer != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xCC1A0A3E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timer!,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress bar with icon on left, animated fill, label centered, icon on right.
class CMProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final String leftIcon;
  final String? rightLabel;
  final List<Color> fillGradient;
  final Color background;
  final String? centerLabel;

  const CMProgressBar({
    super.key,
    required this.current,
    required this.max,
    required this.leftIcon,
    this.rightLabel,
    this.fillGradient = const [Color(0xFFFF8A65), Color(0xFFFF5252)],
    this.background = const Color(0xFF4A148C),
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final label = centerLabel ??
        '${NumberFormat('#,###').format(current)} / ${NumberFormat('#,###').format(max)}';
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF1A0A3E), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(leftIcon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: p,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: fillGradient),
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (rightLabel != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFF9A825)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rightLabel!,
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coin Master logo/branding card with player name, photo, WIN multiplier.
class CMLogoCard extends StatelessWidget {
  final String playerName;
  final String? coinAmount;
  final String? winMultiplier;
  final VoidCallback? onTap;

  const CMLogoCard({
    super.key,
    required this.playerName,
    this.coinAmount,
    this.winMultiplier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF5D4037), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x44FFD700), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Coin Master" text
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF59D), Color(0xFFFF6F00)],
              ).createShader(rect),
              child: const Text(
                'SPIN EMPIRE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(color: Color(0xDD5D4037), offset: Offset(2, 2), blurRadius: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Player row: avatar + name + coins
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        shadows: [
                          Shadow(color: Color(0xFF5D4037), offset: Offset(1, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    if (coinAmount != null)
                      Text(
                        coinAmount!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Color(0xFF5D4037), offset: Offset(1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (winMultiplier != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: Text(
                  'WIN $winMultiplier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "POWER BOOST IS ON" banner with multiplier pill.
class CMPowerBoostBanner extends StatelessWidget {
  final int multiplier;
  const CMPowerBoostBanner({super.key, this.multiplier = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A3E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: const Text(
            'POWER BOOST IS ON',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFF9A825)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x88FFD700), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'x$multiplier',
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 3),
              const Text('⚡', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom-corner badge icon (shop cauldron, clan shield) with badge number.
class CMCornerBadge extends StatelessWidget {
  final String emoji;
  final int? badge;
  final VoidCallback? onTap;
  final Color accent;

  const CMCornerBadge({
    super.key,
    required this.emoji,
    this.badge,
    this.onTap,
    this.accent = const Color(0xFFFFD700),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 4),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 22),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pet character avatar (fox/cat) in a circle.
class CMPetCharacter extends StatelessWidget {
  final String emoji;
  final String? levelBadge;
  final VoidCallback? onTap;

  const CMPetCharacter({
    super.key,
    this.emoji = '🦊',
    this.levelBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF59D), Color(0xFFFF8F00)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
          if (levelBadge != null)
            Positioned(
              bottom: -4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  ),
                  child: Text(
                    levelBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "BONUS" decorative wheel (non-interactive placeholder).
class CMBonusWheel extends StatelessWidget {
  final VoidCallback? onTap;
  const CMBonusWheel({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFD50000)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD700), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
            BoxShadow(color: Color(0x66FFD700), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: const Center(
          child: Text(
            'BONUS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
