import 'package:flutter/material.dart';
import 'package:easyvault/widgets/qr_code_button.dart';
import 'package:easyvault/widgets/media/upload_button.dart';

class CornerButtons extends StatelessWidget {
  final VoidCallback refreshGallery;
  const CornerButtons({
    super.key,
    required this.refreshGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: QrCodeButton(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MediaUploadButton(
              refreshGallery: refreshGallery,
            ),
          ),
        ],
      ),
    );
  }
}
