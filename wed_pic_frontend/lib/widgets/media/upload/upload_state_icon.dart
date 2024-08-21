import 'package:flutter/material.dart';

class UploadStateIcon extends StatelessWidget {
  const UploadStateIcon({
    super.key,
    required bool? uploadFinalStatus,
  }) : _uploadFinalStatus = uploadFinalStatus;

  final bool? _uploadFinalStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          _uploadFinalStatus! ? Icons.check_circle : Icons.error,
          color: _uploadFinalStatus ? Colors.green : Colors.red,
          size: 36,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
