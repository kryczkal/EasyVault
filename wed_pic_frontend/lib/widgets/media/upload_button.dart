import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/widgets/dialogs/upload_dialog.dart';
import 'package:wed_pic_frontend/utils/common.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MediaUploadButton extends StatefulWidget {
  final VoidCallback refreshGallery;
  const MediaUploadButton({super.key, required this.refreshGallery});

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  bool _isLoading = false;

  Future<void> pickFiles() async {
    setState(() {
      _isLoading = true;
    });

    List<XFile>? selectedMedias = await Common.pickFiles();

    setState(() {
      _isLoading = false;
    });

    if (selectedMedias.isNotEmpty) {
      _showMediaPreview(selectedMedias);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.uploadNoMediaSelectedText),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMediaPreview(List<XFile> selectedMedias) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return MediaUploadDialog(selectedMedias: selectedMedias);
      },
    );

    if (!mounted) return;

    late String message;
    if (result != null && result) {
      widget.refreshGallery();
      message = AppLocalizations.of(context)!.uploadSuccessText;
    } else {
      message = AppLocalizations.of(context)!.uploadCancelOrErrorText;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FloatingActionButton(
          heroTag: 'media_upload_button',
          onPressed: _isLoading ? null : pickFiles,
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
        ),
      ],
    );
  }
}
