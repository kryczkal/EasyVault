import 'package:flutter/material.dart';

class LoadingProgressBarWithText extends StatelessWidget {
  const LoadingProgressBarWithText({
    super.key,
    required Animation<double> animation,
  }) : _animation = animation;

  final Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${(_animation.value * 100).toStringAsFixed(0)}%',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: Colors.grey[300],
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
