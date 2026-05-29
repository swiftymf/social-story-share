import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_story_share/social_story_share.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _plugin = SocialStoryShare();
  final _fbAppIdController = TextEditingController();

  bool? _instagramInstalled;
  bool? _facebookInstalled;
  bool _isSharing = false;
  String? _lastMessage;

  @override
  void dispose() {
    _fbAppIdController.dispose();
    super.dispose();
  }

  Future<void> _checkInstagramInstalled() async {
    final installed = await _plugin.isInstagramInstalled();
    if (!mounted) return;
    setState(() {
      _instagramInstalled = installed;
      _lastMessage = installed ? 'Instagram is installed.' : 'Not found.';
    });
  }

  Future<void> _checkFacebookInstalled() async {
    final installed = await _plugin.isFacebookInstalled();
    if (!mounted) return;
    setState(() {
      _facebookInstalled = installed;
      _lastMessage = installed ? 'Facebook is installed.' : 'Not found.';
    });
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final imagePath = await _renderDemoImage();
      final fbAppId = _fbAppIdController.text.trim();
      final ok = await _plugin.shareToInstagramStory(
        imagePath: imagePath,
        facebookAppId: fbAppId.isEmpty ? null : fbAppId,
      );
      if (!mounted) return;
      setState(() {
        _lastMessage = ok ? 'Share dispatched.' : 'Share returned false.';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _lastMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareToFacebook() async {
    setState(() => _isSharing = true);
    try {
      final fbAppId = _fbAppIdController.text.trim();
      if (fbAppId.isEmpty) {
        setState(
          () => _lastMessage =
              'Facebook requires a registered Facebook App ID. Enter one '
              'above before sharing.',
        );
        return;
      }
      final imagePath = await _renderDemoImage();
      final ok = await _plugin.shareToFacebookStory(
        imagePath: imagePath,
        facebookAppId: fbAppId,
      );
      if (!mounted) return;
      setState(() {
        _lastMessage = ok
            ? 'Share dispatched to Facebook Stories.'
            : 'Share returned false.';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _lastMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// Generates a simple 1080x1920 gradient image as a demo background. Real
  /// apps would render their own branded share card here.
  Future<String> _renderDemoImage() async {
    const width = 1080.0;
    const height = 1920.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, width, height),
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6A11CB), Color(0xFFFF6B6B)],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'social_story_share\n\nDemo background image',
        style: TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 160);
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/social_story_share_demo_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('social_story_share demo')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _fbAppIdController,
                  decoration: const InputDecoration(
                    labelText: 'Facebook App ID',
                    helperText:
                        'Numeric ID from developers.facebook.com. Optional for '
                        'Instagram (falls back to the bundle identifier); '
                        'required for Facebook Stories — Facebook validates it '
                        'against Meta and has no usable fallback.',
                    helperMaxLines: 3,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: _checkInstagramInstalled,
                  child: const Text('Check if Instagram is installed'),
                ),
                if (_instagramInstalled != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _instagramInstalled!
                        ? 'Instagram installed: yes'
                        : 'Instagram installed: no',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _checkFacebookInstalled,
                  child: const Text('Check if Facebook is installed'),
                ),
                if (_facebookInstalled != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _facebookInstalled!
                        ? 'Facebook installed: yes'
                        : 'Facebook installed: no',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSharing ? null : _share,
                  child: _isSharing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Share demo image to Instagram Story'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSharing ? null : _shareToFacebook,
                  child: _isSharing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Share demo image to Facebook Story'),
                ),
                if (_lastMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_lastMessage!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
