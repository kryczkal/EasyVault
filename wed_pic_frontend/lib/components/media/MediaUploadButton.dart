import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:wed_pic_frontend/services/ApiCalls.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';

class MediaUploadButton extends StatefulWidget {
  const MediaUploadButton({super.key});

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedMedias = [];
  Map<String, bool?> _uploadStatus =
      {}; // Track upload status: null = pending, true = success, false = failure
  Map<String, double> _uploadProgress =
      {}; // Track upload progress for each file
  var logger = Logger();

  Future<void> pickFiles() async {
    final List<XFile> medias = await _picker.pickMultipleMedia();
    if (medias.isNotEmpty) {
      setState(() {
        _selectedMedias = medias;
        _uploadStatus = {
          for (var media in medias) media.name: null
        }; // Reset upload statuses
        _uploadProgress = {
          for (var media in medias) media.name: 0.0
        }; // Initialize progress for each file
      });
      _showMediaPreview();
    }
  }

  Future<void> _uploadFiles() async {
    final sessionId =
        Provider.of<SessionManager>(context, listen: false).sessionId;

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session ID is not available')),
      );
      return;
    }

    for (var media in _selectedMedias) {
      try {
        await ApiCalls().uploadMediaInChunks(
          sessionId,
          media,
          (double progress) {
            setState(() {
              _uploadProgress[media.name] = progress;
              logger.i('Upload progress for ${media.name}: $progress');
            });
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

  void _showMediaPreview() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int _getCrossAxisCount(double width) {
              if (width < 600) return 2;
              if (width < 900) return 3;
              return 4;
            }

            return AlertDialog(
              title: Text(
                'Selected Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        _getCrossAxisCount(MediaQuery.of(context).size.width),
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _selectedMedias.length,
                  itemBuilder: (context, index) {
                    final media = _selectedMedias[index];
                    final uploadSuccess = _uploadStatus[media.name];
                    final progress = _uploadProgress[media.name] ?? 0.0;

                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
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
                              Icon(
                                Icons.image,
                                color: Colors.blueAccent,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                media.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
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
                              size: 18,
                            ),
                          ),
                        Positioned(
                          bottom: 2,
                          left: 8,
                          right: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueAccent),
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await _uploadFiles();
                    setState(() {});
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        onPressed: pickFiles,
        backgroundColor: Colors.blueAccent,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
