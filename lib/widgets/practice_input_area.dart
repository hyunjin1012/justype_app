import 'package:flutter/material.dart';

class PracticeInputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function() onCheck;
  final String feedback;
  final String labelText;

  const PracticeInputArea({
    super.key,
    required this.controller,
    required this.onCheck,
    required this.feedback,
    this.labelText = 'Type what you see/hear',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: labelText,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: onCheck,
                      child: const Text('Check'),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: _buildFeedbackText(feedback),
                ),
              ),
              const Positioned(
                right: 0,
                child: SizedBox(width: 80),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackText(String feedback) {
    return Text(
      feedback,
      style: TextStyle(
        color: feedback == "Correct!" ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
