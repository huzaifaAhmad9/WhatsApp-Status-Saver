// ignore_for_file: deprecated_member_use

import 'package:video_player/video_player.dart' show VideoPlayerController;
import 'package:flutter_spinkit/flutter_spinkit.dart' show SpinKitCircle;
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:status_saver/views/whatsapp_screen.dart';
import 'package:status_saver/utilities/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _textController;
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;
  late final Animation<Offset> _textAnimation;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/sample.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();

    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _textAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textController.forward();

    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WhatsAppScreen(videoController: _videoController),
        ),
      );
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoAnimation,
                child: Container(
                  height: screenHeight * 0.25,
                  width: screenWidth * 0.5,
                  child: const Center(
                    child: Image(
                      image: AssetImage('assets/images/logo.png'),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: screenHeight * 0.08,
              ),
              SlideTransition(
                position: _textAnimation,
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Save Your Statuses\non Just Single Click',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'logo_style',
                      color: customGreen,
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.19),
              SpinKitCircle(
                size: screenHeight * 0.06,
                color: customGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
