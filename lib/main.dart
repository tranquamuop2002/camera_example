import 'package:camera/camera.dart';
import 'package:camera_preview/test_image_sticker.dart';
import 'package:flutter/material.dart';

import 'camera/camera_screen.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();

  // Necessary initialization for package:media_kit.

  runApp(MyApp(cameras: _cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeView(cameras: cameras),
    );
  }
}

class HomeView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeView({super.key, required this.cameras});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraApp(
                      cameras: widget.cameras,
                    ),
                  ),
                );
              },
              child: const Text(
                'Camera Example',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestImageSticker(),
                  ),
                );
              },
              child: const Text(
                'Image Sticker Example',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
