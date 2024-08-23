// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/services/api_settings.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';
import 'package:wed_pic_frontend/utils/common.dart';
import 'package:wed_pic_frontend/widgets/dialogs/download_all_media_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MediaGalleryTopBar extends StatefulWidget {
  final bool isGridView;
  final VoidCallback onViewToggle;
  final VoidCallback refreshGallery;
  final Future<List<Media>> mediaItems;

  const MediaGalleryTopBar({
    super.key,
    required this.isGridView,
    required this.onViewToggle,
    required this.refreshGallery,
    required this.mediaItems,
  });

  @override
  State<MediaGalleryTopBar> createState() => _MediaGalleryTopBarState();
}

class _MediaGalleryTopBarState extends State<MediaGalleryTopBar> {
  Future<void> _downloadAllMedia(BuildContext context) async {
    final mediaItems = await widget.mediaItems;
    final totalSize = Common.calcMediaSize(mediaItems);

    if (!mounted) return;
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DownloadAllMediaDialog(
            mediaItems: mediaItems, totalSize: totalSize);
      },
    );

    if (result != null && result && mounted) {
      final sessionId =
          Provider.of<SessionManager>(context, listen: false).sessionId;

      if (sessionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.uploadInvalidSessionIdText),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      Common.launchUrlWrapper(
        ApiSettings.endpoints.parseDownloadAllFiles(sessionId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.refreshGallery,
              ),
              IconButton(
                icon: Icon(widget.isGridView ? Icons.list : Icons.grid_view),
                onPressed: widget.onViewToggle,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  await _downloadAllMedia(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
