import 'package:flutter/material.dart';

class PracticeInputArea extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCheck;
  final String feedback;
  final String labelText;
  final bool isCheckButtonEnabled;

  const PracticeInputArea({
    super.key,
    required this.controller,
    required this.onCheck,
    required this.feedback,
    this.labelText = 'Type what you see/hear to score points',
    this.isCheckButtonEnabled = true,
  });

  @override
  PracticeInputAreaState createState() => PracticeInputAreaState();
}

class PracticeInputAreaState extends State<PracticeInputArea> {
  bool _isChecked = false; // Track if the answer has been checked

  // Reset the state when a new sentence is fetched
  void reset() {
    print("Resetting PracticeInputArea state.");
    setState(() {
      _isChecked = false; // Reset the button state
      widget.controller.clear(); // Clear the input field
    });
    print("Button state after reset: $_isChecked"); // Debugging line
  }

  @override
  Widget build(BuildContext context) {
    print(
        "Building PracticeInputArea, button state: $_isChecked"); // Debugging line
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
            controller: widget.controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.labelText,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.isCheckButtonEnabled
                ? () {
                    widget.onCheck(); // Call the onCheck function
                  }
                : null,
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }
}
