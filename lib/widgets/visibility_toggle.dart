import 'package:flutter/material.dart';

class VisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final Function() onToggle;

  const VisibilityToggle({
    super.key,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onToggle,
      icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
      label: Text(isVisible ? 'Hide Text' : 'Show Text'),
    );
  }
}
