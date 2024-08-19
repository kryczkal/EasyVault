import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:wed_pic_frontend/widgets/UploadDialog.dart';
import 'package:wed_pic_frontend/services/ApiCalls.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';
import 'package:wed_pic_frontend/utils/Common.dart';

class MediaUploadButton extends StatefulWidget {
  const MediaUploadButton({super.key});

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  Future<void> pickFiles() async {
    List<XFile>? selectedMedias = await Common.pickFiles();
    if (selectedMedias.isNotEmpty) {
      _showMediaPreview(selectedMedias);
    }
  }

  void _showMediaPreview(List<XFile> selectedMedias) {
    showDialog(
      context: context,
      builder: (context) {
        return MediaUploadDialog(selectedMedias: selectedMedias);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'media_upload_button',
      onPressed: pickFiles,
      backgroundColor: Colors.blueAccent,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }
}
