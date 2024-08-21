import 'package:flutter/material.dart';

class FinalizingUploadIndicator extends StatelessWidget {
  const FinalizingUploadIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Finalizing upload...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
