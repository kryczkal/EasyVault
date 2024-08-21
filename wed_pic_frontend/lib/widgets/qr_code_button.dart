import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/services/api_settings.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';
import 'package:wed_pic_frontend/widgets/dialogs/qr_dialog.dart';

class QrCodeButton extends StatefulWidget {
  const QrCodeButton({super.key});

  @override
  State<QrCodeButton> createState() => _QrCodeButtonState();
}

class _QrCodeButtonState extends State<QrCodeButton> {
  String _getQrCode() {
    String sessionId =
        Provider.of<SessionManager>(context, listen: false).sessionId!;
    return ApiSettings.urls.parseQrCode(sessionId);
  }

  void _showQrCodeDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return QrDialog(qrData: _getQrCode());
        });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'qr_code_button',
      onPressed: () => _showQrCodeDialog(context),
      child: const Icon(
        Icons.qr_code,
        color: Colors.white,
      ),
    );
  }
}
