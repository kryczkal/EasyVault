import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';
import 'package:logger/logger.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:wed_pic_frontend/components/media/MediaGallery.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';
import 'package:wed_pic_frontend/services/IApiClient.dart';

class SessionPage extends StatefulWidget {
  static const String route = '/session/:sessionId';
  final IApiClient client;
  final String sessionId;

  const SessionPage({super.key, required this.client, required this.sessionId});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late Future<List<Media>> mediaItems;
  SessionManager? _sessionManager;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionManager = Provider.of<SessionManager>(context, listen: false);
      _sessionManager?.setSessionId(widget.sessionId);
    });

    var requestUrl =
        '${ApiSettings.fetchMediaEndpoint}?bucket_id=${widget.sessionId}';

    try {
      mediaItems = widget.client.getRequest(requestUrl).then((data) {
        try {
          List<Media> mediaItems = [];
          for (var item in data) {
            mediaItems.add(Media.fromJson(item));
          }
          return mediaItems;
        } on Exception catch (e) {
          Logger().e('Failed to load media items: $e');
          return [];
        }
      });
    } on Exception catch (e) {
      Logger().e('Failed to load media items: $e');
      mediaItems = Future.value([]);
    }
  }

  @override
  void dispose() {
    _sessionManager?.clearSessionId(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaGallery(mediaItems: mediaItems),
    );
  }
}
