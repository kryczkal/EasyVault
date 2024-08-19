import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wed_pic_frontend/GeneralSettings.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';

class QrCodeButton extends StatefulWidget {
  const QrCodeButton({super.key});

  @override
  State<QrCodeButton> createState() => _QrCodeButtonState();
}

class _QrCodeButtonState extends State<QrCodeButton> {
  String _getQrCode() {
    String session_id =
        Provider.of<SessionManager>(context, listen: false).sessionId!;
    // TODO: Move this to settings
    String url = GeneralSettings.siteUrl + '#/session/' + session_id;
    return url;
  }

  // TODO: Move this to a separate class
  void _showQrCodeDialog(BuildContext context) {
    String qrCodeUrl = _getQrCode();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan this QR Code', textAlign: TextAlign.center),
          content: SizedBox(
            width: 200.0,
            height: 200.0,
            child: Center(
              child: QrImageView(
                data: qrCodeUrl,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'qr_code_button',
      onPressed: () => _showQrCodeDialog(context),
      backgroundColor: Colors.blueAccent,
      child: const Icon(
        Icons.qr_code,
        color: Colors.white,
      ),
    );
  }
}
