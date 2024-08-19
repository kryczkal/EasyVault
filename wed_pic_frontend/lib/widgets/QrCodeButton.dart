import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wed_pic_frontend/GeneralSettings.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';
import 'package:wed_pic_frontend/widgets/dialogs/QrDialog.dart';

class QrCodeButton extends StatefulWidget {
  const QrCodeButton({super.key});

  @override
  State<QrCodeButton> createState() => _QrCodeButtonState();
}

class _QrCodeButtonState extends State<QrCodeButton> {
  String _getQrCode() {
    String session_id =
        Provider.of<SessionManager>(context, listen: false).sessionId!;
    return ApiSettings.urls.parseQrCode(session_id);
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
      backgroundColor: Colors.blueAccent,
      child: const Icon(
        Icons.qr_code,
        color: Colors.white,
      ),
    );
  }
}
