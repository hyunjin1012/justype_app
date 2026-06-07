import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechInputArea extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCheck;
  final String feedback;
  final String labelText;
  final bool isCheckButtonEnabled;

  const SpeechInputArea({
    super.key,
    required this.controller,
    required this.onCheck,
    required this.feedback,
    this.labelText = 'Speak what you see/hear to score points',
    this.isCheckButtonEnabled = true,
  });

  @override
  SpeechInputAreaState createState() => SpeechInputAreaState();
}

class SpeechInputAreaState extends State<SpeechInputArea> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    _isInitialized = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    if (!_isInitialized) {
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    try {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            widget.controller.text = result.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: widget.labelText,
            ),
            minLines: 2,
            maxLines: 4,
            readOnly: false,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startListening,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Stop' : 'Record'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isListening
                        ? Theme.of(context).colorScheme.errorContainer
                        : null,
                    foregroundColor: _isListening
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.isCheckButtonEnabled
                      ? () {
                          widget.onCheck();
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Check'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
