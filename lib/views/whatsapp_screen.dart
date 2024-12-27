// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:status_saver/views/video_player_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'full_screen_media_page.dart';
import '../utilities/colors.dart';
import 'dart:io';

class WhatsAppScreen extends StatefulWidget {
  final VideoPlayerController videoController;
  const WhatsAppScreen({super.key, required this.videoController});

  @override
  _WhatsAppScreenState createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen>
    with SingleTickerProviderStateMixin {
  String _selectedWhatsApp = 'WhatsApp';
  List<FileSystemEntity> _statuses = [];
  bool _permissionGranted = false;
  bool _loading = true;
  TabController? _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestPermissions();
    widget.videoController;
  }

  Future<void> _requestPermissions() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 30) {
      // Android 11 or higher
      if (await Permission.manageExternalStorage.isGranted) {
        setState(() {
          _permissionGranted = true;
        });
        await _loadStatuses(androidInfo.version.sdkInt);
      } else {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          setState(() {
            _permissionGranted = true;
          });
          await _loadStatuses(androidInfo.version.sdkInt);
        } else if (status.isDenied) {
          _handlePermissionDenied();
        } else if (status.isPermanentlyDenied) {
          _showPermanentDeniedDialog();
        }
      }
    } else {
      // Android 10 or lower
      if (await Permission.storage.isGranted) {
        setState(() {
          _permissionGranted = true;
        });
        await _loadStatuses(androidInfo.version.sdkInt);
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          setState(() {
            _permissionGranted = true;
          });
          await _loadStatuses(androidInfo.version.sdkInt);
        } else if (status.isDenied) {
          _handlePermissionDenied();
        } else if (status.isPermanentlyDenied) {
          _showPermanentDeniedDialog();
        }
      }
    }
  }

  void _handlePermissionDenied() {
    setState(() {
      _permissionGranted = false;
      _loading = false;
    });
    _showPermissionDialog();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Permission Required',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const Text(
            'This app needs storage permissions to function properly. Please allow the required permissions.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              label: const Text(
                'Grant Permission',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: greenWithOpacity,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _requestPermissions();
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermanentDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Permission Denied',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const Text(
            'Storage permission is permanently denied. Please enable it manually in app settings to use this feature.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: greenWithOpacity,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadStatuses(int sdkInt) async {
    try {
      final statuses = await getWhatsAppStatuses(sdkInt);
      setState(() {
        _statuses = statuses;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Error',
            message: 'Failed to load statuses',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          backgroundColor: customGreen,
          elevation: 0,
        ),
      );
    }
  }

  Future<List<FileSystemEntity>> getWhatsAppStatuses(int sdkInt) async {
    List<FileSystemEntity> statuses = [];
    try {
      String directoryPath;
      if (_selectedWhatsApp == 'WhatsApp') {
        directoryPath = sdkInt >= 30
            ? '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses'
            : '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
      } else if (_selectedWhatsApp == 'WA Business') {
        directoryPath = sdkInt >= 30
            ? '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses'
            : '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';
      } else {
        throw Exception('Invalid app selection');
      }
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        statuses = directory.listSync(recursive: false, followLinks: false);
        statuses = statuses
            .where((file) => !FileSystemEntity.isDirectorySync(file.path))
            .toList();
      } else {
        throw Exception('Directory not found');
      }
    } on FileSystemException catch (e) {
      debugPrint('FileSystemException: ${e.message}');
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }

    return statuses;
  }

  List<FileSystemEntity> _getImages() {
    return _statuses.where((status) {
      final extension = status.path.split('.').last.toLowerCase();
      return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
    }).toList();
  }

  List<FileSystemEntity> _getVideos() {
    return _statuses.where((status) {
      final extension = status.path.split('.').last.toLowerCase();
      return extension == 'mp4' || extension == 'mkv' || extension == 'avi';
    }).toList();
  }

  Widget _buildStatusItem(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const itemSize = 100.0;
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      // Image
      return Container(
        decoration: const BoxDecoration(color: Colors.black),
        width: itemSize,
        height: itemSize,
        child: Image.file(file, fit: BoxFit.cover),
      );
    } else {
      return Container(); // Unsupported file type
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(mediaQuery.size.height * 0.15),
          child: AppBar(
            backgroundColor: greenWithOpacity,
            title: const Text(
              'Downloader',
              style: TextStyle(
                fontFamily: 'custom',
                color: Colors.white,
              ),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.3),
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
                margin: const EdgeInsets.only(right: 12),
                child: DropdownButton<String>(
                  value: _selectedWhatsApp,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  iconSize: 25,
                  elevation: 1,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  isDense: true,
                  dropdownColor: greenWithOpacity,
                  onChanged: (String? newValue) async {
                    setState(() {
                      _selectedWhatsApp = newValue!;
                      _loading = true;
                    });
                    await _loadStatuses(
                        (await DeviceInfoPlugin().androidInfo).version.sdkInt);
                  },
                  items: <String>['WhatsApp', 'WA Business']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2.0), // Adjust padding as needed
                        child: Text(value),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            bottom: TabBar(
              labelColor: Colors.white,
              controller: _tabController,
              indicatorColor: greenWithOpacity,
              tabs: const [
                Tab(
                  icon: Icon(
                    Icons.image,
                    size: 20,
                  ),
                  text: 'Images',
                ),
                Tab(
                  icon: Icon(
                    Icons.videocam,
                    size: 20,
                  ),
                  text: 'Videos',
                ),
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(
                child: SpinKitCircle(
                  color: customGreen,
                  size: 50.0,
                ),
              )
            : _permissionGranted
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      // Images Tab
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: _getImages().length,
                        itemBuilder: (context, index) {
                          final file = File(_getImages()[index].path);
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    FullScreenMediaPage(file: file),
                              ),
                            ),
                            child: _buildStatusItem(file),
                          );
                        },
                      ),
                      // Videos Tab
                      VideoTab(
                        videos: _getVideos(),
                        onTap: (file) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullScreenMediaPage(file: file),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Permission required to access statuses.',
                          style: TextStyle(fontSize: 16, color: customGreen),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          label: const Text('Grant Permission',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenWithOpacity,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await _requestPermissions();
                          },
                        ),
                      ],
                    ),
                  ));
  }
}

class VideoTab extends StatefulWidget {
  final List<FileSystemEntity> videos;
  final Function(File) onTap;

  const VideoTab({
    Key? key,
    required this.videos,
    required this.onTap,
  }) : super(key: key);

  @override
  _VideoTabState createState() => _VideoTabState();
}

class _VideoTabState extends State<VideoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final file = File(widget.videos[index].path);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FullScreenMediaPage(file: file), // Correct variable
              ),
            );
          },
          child: _buildStatusItem(file),
        );
      },
    );
  }

  Widget _buildStatusItem(File file) {
    return Container(
      height: 100,
      width: 100,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: VideoPlayerWidget(file: file, playVideo: false),
          ),
          Center(
            child: IconButton(
              icon: const Icon(Icons.play_circle_outlined,
                  color: Colors.white, size: 30),
              onPressed: () {
                widget.onTap(file);
              },
            ),
          )
        ],
      ),
    );
  }
}
