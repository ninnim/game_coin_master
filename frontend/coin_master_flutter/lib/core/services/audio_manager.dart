import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Generates and plays game sound effects using in-memory WAV tones.
/// No external audio files needed — all sounds are synthesised at init.
class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  final List<AudioPlayer> _pool = List.generate(6, (_) => AudioPlayer());
  int _poolIdx = 0;
  bool soundEnabled = true;

  // Pre-generated WAV buffers
  late final Uint8List _spinStart;
  late final Uint8List _reelStop;
  late final Uint8List _coinWin;
  late final Uint8List _jackpot;
  late final Uint8List _attackSfx;
  late final Uint8List _raidSfx;
  late final Uint8List _shieldSfx;
  late final Uint8List _energySfx;
  late final Uint8List _buttonTap;
  late final Uint8List _buildUpgrade;
  late final Uint8List _villageComplete;

  bool _ready = false;

  /// Call once at app startup (fast — pure math, no I/O).
  void init() {
    if (_ready) return;
    _spinStart = _sweep(350, 700, 0.30, volume: 0.35);
    _reelStop = _tone(180, 0.07, volume: 0.45);
    _coinWin = _chime([523, 659, 784], 0.11, volume: 0.45);
    _jackpot = _chime([523, 659, 784, 1047, 1319], 0.16, volume: 0.55);
    _attackSfx = _sweep(520, 200, 0.18, volume: 0.45);
    _raidSfx = _sweep(260, 480, 0.22, volume: 0.45);
    _shieldSfx = _chime([659, 784, 988], 0.13, volume: 0.4);
    _energySfx = _sweep(420, 950, 0.14, volume: 0.4);
    _buttonTap = _tone(900, 0.04, volume: 0.2);
    _buildUpgrade = _chime([440, 554, 659], 0.10, volume: 0.45);
    _villageComplete = _chime([523, 659, 784, 1047, 784, 1047, 1319], 0.14, volume: 0.55);
    _ready = true;
  }

  // ── Public API ──

  Future<void> playSpinStart() => _play(_spinStart);
  Future<void> playReelStop() => _play(_reelStop);
  Future<void> playCoinWin() => _play(_coinWin);
  Future<void> playJackpot() => _play(_jackpot);
  Future<void> playAttack() => _play(_attackSfx);
  Future<void> playRaid() => _play(_raidSfx);
  Future<void> playShield() => _play(_shieldSfx);
  Future<void> playEnergy() => _play(_energySfx);
  Future<void> playButtonTap() => _play(_buttonTap);
  Future<void> playBuildUpgrade() => _play(_buildUpgrade);
  Future<void> playVillageComplete() => _play(_villageComplete);

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
  }

  // ── Playback ──

  Future<void> _play(Uint8List wav) async {
    if (!soundEnabled || !_ready) return;
    try {
      final player = _pool[_poolIdx];
      _poolIdx = (_poolIdx + 1) % _pool.length;
      await player.stop();
      await player.play(BytesSource(wav));
    } catch (_) {}
  }

  // ══════════════════════ WAV SYNTHESIS ══════════════════════

  /// Single frequency tone with linear fade-out.
  Uint8List _tone(double freq, double duration, {double volume = 0.5}) {
    const sr = 22050;
    final n = (sr * duration).toInt();
    final bytes = ByteData(44 + n * 2);
    _writeHeader(bytes, n, sr);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = 1.0 - (i / n);
      final s = (sin(2 * pi * freq * t) * 32767 * volume * env)
          .toInt()
          .clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  /// Frequency sweep (f1 → f2) with gradual fade.
  Uint8List _sweep(double f1, double f2, double duration,
      {double volume = 0.5}) {
    const sr = 22050;
    final n = (sr * duration).toInt();
    final bytes = ByteData(44 + n * 2);
    _writeHeader(bytes, n, sr);
    double phase = 0;
    for (int i = 0; i < n; i++) {
      final p = i / n;
      final freq = f1 + (f2 - f1) * p;
      final env = 1.0 - p * 0.5;
      phase += 2 * pi * freq / sr;
      final s = (sin(phase) * 32767 * volume * env)
          .toInt()
          .clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  /// Multi-note arpeggio chime.
  Uint8List _chime(List<double> freqs, double noteDur, {double volume = 0.5}) {
    const sr = 22050;
    final samplesPerNote = (sr * noteDur).toInt();
    final total = samplesPerNote * freqs.length;
    final bytes = ByteData(44 + total * 2);
    _writeHeader(bytes, total, sr);
    for (int ni = 0; ni < freqs.length; ni++) {
      final freq = freqs[ni];
      final off = ni * samplesPerNote;
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / sr;
        final env = 1.0 - (i / samplesPerNote) * 0.4;
        final s = (sin(2 * pi * freq * t) * 32767 * volume * env)
            .toInt()
            .clamp(-32768, 32767);
        bytes.setInt16(44 + (off + i) * 2, s, Endian.little);
      }
    }
    return bytes.buffer.asUint8List();
  }

  /// Writes a standard 16-bit mono PCM RIFF/WAVE header.
  void _writeHeader(ByteData b, int numSamples, int sampleRate) {
    final dataSize = numSamples * 2;
    // RIFF
    b.setUint8(0, 0x52);
    b.setUint8(1, 0x49);
    b.setUint8(2, 0x46);
    b.setUint8(3, 0x46);
    b.setUint32(4, 36 + dataSize, Endian.little);
    // WAVE
    b.setUint8(8, 0x57);
    b.setUint8(9, 0x41);
    b.setUint8(10, 0x56);
    b.setUint8(11, 0x45);
    // fmt
    b.setUint8(12, 0x66);
    b.setUint8(13, 0x6D);
    b.setUint8(14, 0x74);
    b.setUint8(15, 0x20);
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    b.setUint16(32, 2, Endian.little); // block align
    b.setUint16(34, 16, Endian.little); // bits per sample
    // data
    b.setUint8(36, 0x64);
    b.setUint8(37, 0x61);
    b.setUint8(38, 0x74);
    b.setUint8(39, 0x61);
    b.setUint32(40, dataSize, Endian.little);
  }
}
