import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/services/api_calls.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';
import 'package:wed_pic_frontend/utils/responsiveness.dart';

class MediaUploadDialog extends StatefulWidget {
  final List<XFile> selectedMedias;

  const MediaUploadDialog({
    super.key,
    required this.selectedMedias,
  });

  @override
  MediaUploadDialogState createState() => MediaUploadDialogState();
}

// TODO: Each file grid item should be moved to a separate component
// TODO: The upload logic should be moved to a separate class and the
// UI should be separated from the logic
class MediaUploadDialogState extends State<MediaUploadDialog>
    with TickerProviderStateMixin {
  Map<String, bool?> _uploadStatus = {};
  Map<String, double> _uploadProgress = {};
  Map<String, AnimationController> _animationControllers = {};
  Map<String, Animation<double>> _animations = {};
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeUploadTracking();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeUploadTracking() {
    setState(() {
      _uploadStatus = {
        for (var media in widget.selectedMedias) media.name: null
      };
      _uploadProgress = {
        for (var media in widget.selectedMedias) media.name: 0.0
      };

      _animationControllers = {
        for (var media in widget.selectedMedias)
          media.name: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 500),
          )
      };

      _animations = {
        for (var media in widget.selectedMedias)
          media.name: Tween<double>(begin: 0.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _animationControllers[media.name]!,
              curve: Curves.easeInOut,
            ),
          )..addListener(() {
              setState(() {});
            })
      };
    });
  }

  void _updateProgress(String mediaName, double newProgress) {
    final controller = _animationControllers[mediaName]!;

    controller.reset();

    _animations[mediaName] = Tween<double>(
      begin: _uploadProgress[mediaName],
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    _uploadProgress[mediaName] = newProgress;
    controller.forward();
  }

  Future<void> _uploadFiles() async {
    final sessionId =
        Provider.of<SessionManager>(context, listen: false).sessionId;

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ID is not available')),
      );
      return;
    }

    for (var media in widget.selectedMedias) {
      try {
        await ApiCalls.uploadMediaInChunks(
          sessionId,
          media,
          (double progress) {
            _updateProgress(media.name, progress);
            logger.i('Upload progress for ${media.name}: $progress');
          },
        );
        setState(() {
          _uploadStatus[media.name] = true;
          logger.i('Upload success for ${media.name}');
        });
      } catch (e) {
        setState(() {
          _uploadStatus[media.name] = false;
          logger.e('Upload failed for ${media.name}: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Selected Files',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsiveness.getCrossAxisCount(
                MediaQuery.of(context).size.width, 200),
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: widget.selectedMedias.length,
          itemBuilder: (context, index) {
            final media = widget.selectedMedias[index];
            final uploadSuccess = _uploadStatus[media.name];

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image,
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        media.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (uploadSuccess != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      uploadSuccess ? Icons.check_circle : Icons.error,
                      color: uploadSuccess ? Colors.green : Colors.red,
                      size: 36,
                    ),
                  ),
                Positioned(
                  bottom: 2,
                  left: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _animations[media.name]?.value,
                      backgroundColor: Colors.grey[300],
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
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
          onPressed: () async {
            await _uploadFiles();
          },
          child: const Text(
            'Send',
            style: TextStyle(
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
