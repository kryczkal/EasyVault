import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDialog extends StatelessWidget {
  final String qrData;
  const QrDialog({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan this QR Code', textAlign: TextAlign.center),
      content: SizedBox(
        width: 200.0,
        height: 200.0,
        child: Center(
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
