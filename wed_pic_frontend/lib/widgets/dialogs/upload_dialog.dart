import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/utils/responsiveness.dart';
import 'package:wed_pic_frontend/widgets/media/upload/file_upload_grid_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MediaUploadDialog extends StatefulWidget {
  final List<XFile> selectedMedias;

  const MediaUploadDialog({
    super.key,
    required this.selectedMedias,
  });

  @override
  MediaUploadDialogState createState() => MediaUploadDialogState();
}

class MediaUploadDialogState extends State<MediaUploadDialog> {
  final Map<String, bool> _uploadResults = {};
  final Map<String, GlobalKey<FileUploadGridItemState>> _fileUploadKeys = {};
  bool _uploadStarted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (var media in widget.selectedMedias) {
      _fileUploadKeys[media.name] = GlobalKey<FileUploadGridItemState>();
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _preloadGridItems(),
    );
  }

  int callCount = 0;
  void _preloadGridItems() async {
    callCount++;
    int scrollSteps = 5 * callCount;

    double scrollIncrement =
        _scrollController.position.maxScrollExtent / scrollSteps;

    for (int i = 0; i <= scrollSteps; i++) {
      double scrollPosition = scrollIncrement * i;
      _scrollController.jumpTo(scrollPosition);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _onUploadComplete(String mediaName, bool success) {
    setState(() {
      _uploadResults[mediaName] = success;
    });

    if (_uploadResults.length == widget.selectedMedias.length) {
      final allSuccess = _uploadResults.values.every((element) => element);
      if (allSuccess) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _retryFailedUploads() {
    setState(() {
      _uploadStarted = false;
      _uploadResults.clear();
    });

    for (var media in widget.selectedMedias) {
      final success = _uploadResults[media.name];
      if (success == false) {
        final itemKey = _fileUploadKeys[media.name];
        itemKey?.currentState?.retryUpload();
        setState(() {});
      }
    }

    _startUploads();
  }

  void _startUploads() {
    if (_uploadStarted) {
      return;
    }
    _uploadStarted = true;
    for (var media in widget.selectedMedias) {
      final itemKey = _fileUploadKeys[media.name];
      if (itemKey != null) {
        itemKey.currentState?.startUpload();
      }
    }
    setState(() {});
  }

  void _cancelUploads() {
    for (var itemKey in _fileUploadKeys.values) {
      itemKey.currentState?.cancelUpload();
    }
  }

  @override
  void dispose() {
    _cancelUploads();
    super.dispose();
  }

  bool get _canStartUploads {
    for (var media in widget.selectedMedias) {
      final itemKey = _fileUploadKeys[media.name];
      if (itemKey == null || itemKey.currentState == null) {
        Future.delayed(Duration(milliseconds: 500 + 500 * callCount), () {
          _preloadGridItems();
          if (mounted) {
            setState(() {});
          }
        });
        return false;
      }
    }
    return true;
  }

  String get _buttonText {
    if (_uploadStarted) {
      if (_uploadResults.length == widget.selectedMedias.length &&
          _uploadResults.containsValue(false)) {
        return AppLocalizations.of(context)!.uploadDialogRetry;
      }
      return AppLocalizations.of(context)!.uploadDialogUploading;
    }
    return AppLocalizations.of(context)!.uploadDialogUpload;
  }

  VoidCallback? get _buttonAction {
    if (_uploadStarted) {
      if (_uploadResults.length == widget.selectedMedias.length &&
          _uploadResults.containsValue(false)) {
        return _retryFailedUploads;
      }
      return null;
    }
    return _canStartUploads ? _startUploads : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.uploadDialogSelectedFiles,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView(
          controller: _scrollController,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsiveness.getCrossAxisCount(
                MediaQuery.of(context).size.width, 300),
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          children: widget.selectedMedias.map((media) {
            final itemKey = _fileUploadKeys[media.name];
            return FileUploadGridItem(
              key: itemKey,
              media: media,
              onUploadComplete: (success) =>
                  _onUploadComplete(media.name, success),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            AppLocalizations.of(context)!.uploadDialogCancel,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _buttonAction,
          child: Text(
            _buttonText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
