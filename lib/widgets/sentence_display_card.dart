import 'package:flutter/material.dart';
import 'app_surface.dart';

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
    return AppSurface(
      padding: const EdgeInsets.all(18.0),
      child: Text(
        sentence,
        style: textStyle ?? Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
