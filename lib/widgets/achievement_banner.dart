import 'package:flutter/material.dart';

class AchievementBanner extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final Color backgroundColor;
  final Color textColor;

  const AchievementBanner({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 32,
            ),
          ),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () {
              // Logic to dismiss the banner
              // You can use a callback or state management to remove the banner
            },
          ),
        ],
      ),
    );
  }
}
