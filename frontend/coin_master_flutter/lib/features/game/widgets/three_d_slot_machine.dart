import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Realistic 3D slot machine rendered via Three.js in a WebView.
///
/// Flutter's Matrix4 transforms give only 2.5D perspective. For true
/// Coin Master-style 3D (cylindrical reels, PBR gold materials, dynamic
/// lighting, shadow casting), we use WebGL via Three.js embedded in a
/// WebView and bridge spin/stop events back to Flutter.
///
/// Use [startSpin] and [stopReels] via the state's [GlobalKey].
class ThreeDSlotMachine extends StatefulWidget {
  final void Function(int reelIndex)? onReelStopped;
  final VoidCallback? onReady;

  const ThreeDSlotMachine({
    super.key,
    this.onReelStopped,
    this.onReady,
  });

  @override
  State<ThreeDSlotMachine> createState() => ThreeDSlotMachineState();
}

class ThreeDSlotMachineState extends State<ThreeDSlotMachine> {
  late final WebViewController _controller;
  bool _pageLoaded = false;
  bool _sceneReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0518))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onJsMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _pageLoaded = true);
        },
      ))
      ..loadFlutterAsset('assets/3d/slot_machine.html');
  }

  void _onJsMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      switch (data['type']) {
        case 'ready':
          if (!_sceneReady) {
            _sceneReady = true;
            widget.onReady?.call();
          }
          break;
        case 'reel_stopped':
          final reel = (data['reel'] as num?)?.toInt() ?? 0;
          widget.onReelStopped?.call(reel);
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('3D bridge parse error: $e');
    }
  }

  /// Starts the continuous reel spin animation.
  void startSpin() {
    if (!_sceneReady) return;
    _controller.runJavaScript('startSpin();');
  }

  /// Decelerates the three reels to land on [s1], [s2], [s3] (symbol indices 0-5).
  void stopReels(int s1, int s2, int s3) {
    if (!_sceneReady) return;
    _controller.runJavaScript('stopReels($s1, $s2, $s3);');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (!_pageLoaded || !_sceneReady)
          Container(
            color: const Color(0xFF0A0518),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 12),
                  Text(
                    'Loading 3D scene...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
