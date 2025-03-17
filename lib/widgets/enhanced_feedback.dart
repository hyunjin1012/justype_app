import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class EnhancedFeedback extends StatefulWidget {
  final String userInput;
  final String correctSentence;
  final bool isCorrect;

  const EnhancedFeedback({
    super.key,
    required this.userInput,
    required this.correctSentence,
    required this.isCorrect,
  });

  @override
  State<EnhancedFeedback> createState() => _EnhancedFeedbackState();
}

class _EnhancedFeedbackState extends State<EnhancedFeedback> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (widget.isCorrect) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti animation for correct answers
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),

        // Feedback content
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: widget.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: widget.isCorrect ? Colors.green : Colors.red,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feedback header
              Row(
                children: [
                  Icon(
                    widget.isCorrect ? Icons.check_circle : Icons.error,
                    color: widget.isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isCorrect ? 'Correct!' : 'Not quite right',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isCorrect ? Colors.green : Colors.red,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Only show difference analysis for incorrect answers
              if (!widget.isCorrect) ...[
                const Text(
                  'Here\'s what was different:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDifferenceHighlight(
                    widget.userInput, widget.correctSentence),
              ],

              // Show encouragement for correct answers
              if (widget.isCorrect) ...[
                const Text(
                  'Great job! Keep practicing to improve your skills.',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifferenceHighlight(String userInput, String correctSentence) {
    // Simple difference highlighting - in a real app, you'd use a more sophisticated algorithm
    final List<String> userWords = userInput.split(' ');
    final List<String> correctWords = correctSentence.split(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your input
        const Text(
          'Your input:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: _highlightDifferences(userWords, correctWords, true),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Correct sentence
        const Text(
          'Correct sentence:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: _highlightDifferences(correctWords, userWords, false),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _highlightDifferences(
    List<String> primaryWords,
    List<String> comparisonWords,
    bool isUserInput,
  ) {
    List<TextSpan> spans = [];

    for (int i = 0; i < primaryWords.length; i++) {
      bool isDifferent = i >= comparisonWords.length ||
          primaryWords[i].toLowerCase() != comparisonWords[i].toLowerCase();

      spans.add(
        TextSpan(
          text: '${primaryWords[i]} ',
          style: TextStyle(
            color: isDifferent
                ? (isUserInput ? Colors.red : Colors.green)
                : Colors.black,
            fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
            decoration: isDifferent ? TextDecoration.underline : null,
          ),
        ),
      );
    }

    // If the correct sentence has more words than user input
    if (!isUserInput && comparisonWords.length < primaryWords.length) {
      spans.add(
        const TextSpan(
          text: ' (You missed some words)',
          style: TextStyle(
            color: Colors.orange,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return spans;
  }
}
