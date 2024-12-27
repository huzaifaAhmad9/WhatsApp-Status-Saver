import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:status_saver/utilities/colors.dart';
import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import 'dart:io';

class FullScreenMediaPage extends StatelessWidget {
  final File file;

  const FullScreenMediaPage({required this.file});

  @override
  Widget build(BuildContext context) {
    final isVideo = file.path.split('.').last.toLowerCase() == 'mp4';
    return Scaffold(
        appBar: AppBar(
          backgroundColor: greenWithOpacity,
          titleSpacing: 0.0,
          title: const Text(
            'Preview',
            style: TextStyle(fontFamily: 'custom', color: Colors.white),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              onPressed: () {
                _saveToGallery(context, file);
              },
            ),
            const SizedBox(
              width: 10,
            )
          ],
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(
            child: isVideo
                ? VideoPlayerWidget(file: file, playVideo: true)
                : Image.file(file),
          ),
        ));
  }

  Future<void> _saveToGallery(BuildContext context, File file) async {
    final result = await ImageGallerySaver.saveFile(file.path);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Success',
            message: 'Download successful',
            contentType: ContentType.success,
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Error',
            message: 'Failed to save',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }
  }
}
