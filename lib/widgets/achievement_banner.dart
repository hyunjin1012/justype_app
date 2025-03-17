import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class AchievementBanner extends StatefulWidget {
  final String title;
  final String description;
  final String icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onDismiss;

  const AchievementBanner({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
    this.onDismiss,
  });

  @override
  State<AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<AchievementBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  final bool _lottieLoadError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Simpler animation setup to avoid range issues
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _rotateAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ).drive(Tween<double>(begin: -0.05, end: 0.0));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * math.pi,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.backgroundColor,
                    Color.lerp(widget.backgroundColor, Colors.white, 0.2)!,
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    width: 48,
                    height: 48,
                    child: _buildIconWidget(),
                  ),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: Icon(Icons.close, color: widget.textColor),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconWidget() {
    // Always use the fallback icon since we're having issues with Lottie
    return const Icon(
      Icons.emoji_events,
      color: Colors.amber,
      size: 32,
    );
  }
}
