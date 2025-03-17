import 'package:flutter/material.dart';

class SentenceDisplayCard extends StatelessWidget {
  final String sentence;
  final TextStyle? textStyle;

  const SentenceDisplayCard({
    super.key,
    required this.sentence,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          sentence,
          style: textStyle ?? Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
