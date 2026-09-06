import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';

class VoiceReadButton extends StatefulWidget {
  final String text;

  const VoiceReadButton({super.key, required this.text});

  @override
  State<VoiceReadButton> createState() => _VoiceReadButtonState();
}

class _VoiceReadButtonState extends State<VoiceReadButton>
    with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    } else {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
        _animationController.repeat(reverse: true);
      }
      final currentLocale = context.locale.languageCode;
      final ttsLang = currentLocale == 'hi' ? 'hi-IN' : (currentLocale == 'kn' ? 'kn-IN' : 'en-IN');
      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.speak(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = 1.0 + (_animationController.value * 0.2);
        return Transform.scale(
          scale: _isPlaying ? scale : 1.0,
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
              color: _isPlaying ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
            ),
            onPressed: _toggleSpeak,
            tooltip: _isPlaying ? 'Stop reading' : 'Read aloud',
          ),
        );
      },
    );
  }
}
