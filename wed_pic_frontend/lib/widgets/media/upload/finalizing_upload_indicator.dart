import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FinalizingUploadIndicator extends StatelessWidget {
  const FinalizingUploadIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.uploadFileFinalizingText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
