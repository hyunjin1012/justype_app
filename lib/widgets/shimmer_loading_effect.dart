import 'package:flutter/material.dart';

class ShimmerLoadingEffect extends StatefulWidget {
  final Widget child;

  const ShimmerLoadingEffect({super.key, required this.child});

  @override
  State<ShimmerLoadingEffect> createState() => _ShimmerLoadingEffectState();
}

class _ShimmerLoadingEffectState extends State<ShimmerLoadingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              transform: GradientRotation(_animation.value),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
