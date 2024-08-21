import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/services/api_calls.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/gallery.dart';
import 'package:wed_pic_frontend/services/api_client_interface.dart';

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
    mediaItems = ApiCalls.fetchMedia(widget.sessionId);
  }

  void fetchMedia() {
    setState(() {
      mediaItems = ApiCalls.fetchMedia(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _sessionManager?.clearSessionId(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaGallery(mediaItems: mediaItems, refreshGallery: fetchMedia),
    );
  }
}
