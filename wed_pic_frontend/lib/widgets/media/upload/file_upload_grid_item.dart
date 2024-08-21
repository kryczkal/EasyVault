import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/services/api_calls.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';
import 'package:wed_pic_frontend/widgets/custom_error.dart';
import 'package:wed_pic_frontend/widgets/media/upload/file_box.dart';
import 'package:wed_pic_frontend/widgets/media/upload/finalizing_upload_indicator.dart';
import 'package:wed_pic_frontend/widgets/media/upload/loading_progress_bar_with_text.dart';
import 'package:wed_pic_frontend/widgets/media/upload/upload_state_icon.dart';

class FileUploadGridItem extends StatefulWidget {
  final XFile media;
  final Function(bool) onUploadComplete;

  const FileUploadGridItem({
    super.key,
    required this.media,
    required this.onUploadComplete,
  });

  @override
  FileUploadGridItemState createState() => FileUploadGridItemState();

  void startUpload(BuildContext context) {
    final state = context.findAncestorStateOfType<FileUploadGridItemState>();
    state?.startUpload();
  }

  void cancelUpload(BuildContext context) {
    final state = context.findAncestorStateOfType<FileUploadGridItemState>();
    state?.cancelUpload();
  }
}

class FileUploadGridItemState extends State<FileUploadGridItem>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _uploadProgress = 0.0;
  bool? _uploadFinalStatus;
  var logger = Logger();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isUploading = false;
  bool _isCanceled = false;

  void _updateProgress(double newProgress) {
    _animationController.reset();
    _animation = Tween<double>(
      begin: _uploadProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _uploadProgress = newProgress;
    _animationController.forward();
  }

  Future<void> startUpload() async {
    if (_isUploading) return;

    _isUploading = true;
    _isCanceled = false;
    await uploadFile();
  }

  void cancelUpload() {
    if (!_isUploading) return;

    setState(() {
      _isCanceled = true;
      _uploadProgress = 0.0;
      _isUploading = false;
      _uploadFinalStatus = false;
      widget.onUploadComplete(false);
    });
    logger.i('Upload canceled for ${widget.media.name}');
  }

  Future<void> uploadFile() async {
    final sessionId =
        Provider.of<SessionManager>(context, listen: false).sessionId;

    if (sessionId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session ID is not available')),
        );
      }
      return;
    }

    try {
      await ApiCalls.uploadMediaInChunks(
        sessionId,
        widget.media,
        (double progress) {
          if (_isCanceled) return;

          _updateProgress(progress);
          logger.i('Upload progress for ${widget.media.name}: $progress');
        },
      );

      if (_isCanceled) return;

      if (mounted) {
        setState(() {
          _uploadFinalStatus = true;
          widget.onUploadComplete(true);
          logger.i('Upload success for ${widget.media.name}');
        });
      }
    } catch (e) {
      if (_isCanceled) return;

      if (mounted) {
        setState(() {
          _uploadFinalStatus = false;
          widget.onUploadComplete(false);
          logger.e('Upload failed for ${widget.media.name}: $e');
        });
      }
    } finally {
      _isUploading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GridTile(
      footer: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: _buildFooter(),
      ),
      child: Container(
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
        child: FileBox(widget: widget),
      ),
    );
  }

  Widget _buildFooter() {
    if (_uploadProgress == 1 && _uploadFinalStatus == null) {
      return const FinalizingUploadIndicator();
    } else if (_uploadProgress > 0 &&
        _uploadProgress < 1 &&
        _uploadFinalStatus == null) {
      return LoadingProgressBarWithText(animation: _animation);
    } else if (_uploadFinalStatus != null) {
      return UploadStateIcon(uploadFinalStatus: _uploadFinalStatus);
    } else {
      return const SizedBox.shrink();
    }
  }
}
