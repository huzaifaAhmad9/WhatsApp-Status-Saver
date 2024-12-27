// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:video_player/video_player.dart'
    show VideoPlayerController, VideoPlayer;
import 'package:flutter_spinkit/flutter_spinkit.dart' show SpinKitFadingCircle;
import 'package:flutter/material.dart';
import 'dart:io' show File;

class VideoPlayerWidget extends StatefulWidget {
  final File file;
  final bool playVideo;

  const VideoPlayerWidget(
      {super.key, required this.file, this.playVideo = false});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = false;
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            if (widget.playVideo) {
              _controller.play();
              _playing = true;
            }
          });
        }
      }).catchError((error) {
        debugPrint('Error initializing video player: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_initialized) {
      return Center(
        child: SpinKitFadingCircle(
          color: Colors.grey.withOpacity(.3),
          size: screenHeight * 0.06,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_playing) {
            _controller.pause();
            _playing = false;
            _showPauseIcon = true;
          } else {
            _controller.play();
            _playing = true;
            _showPauseIcon = false;
          }
        });
        if (!_playing) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() {
              _showPauseIcon = false;
            });
          });
        }
      },
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (_showPauseIcon)
            const Center(
              child: Icon(
                Icons.pause,
                color: Colors.white,
                size: 70.0,
              ),
            ),
        ],
      ),
    );
  }
}
