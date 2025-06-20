import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:saver_gallery/saver_gallery.dart';

import 'camera_controller.dart';
import '../sticker_custom/image_stickers.dart';

import 'dart:ui' as ui;

final List<String> framePaths = [
  'assets/icons/1_large.png',
  'assets/icons/2_large.png',
  'assets/icons/3_large.png',
  'assets/icons/4_large.png',
  'assets/icons/5_large.png',
  'assets/icons/6_large.png',
];

final List<String> stickerPaths = [
  'assets/icons/1.png',
  'assets/icons/2.png',
  'assets/icons/3.png',
  'assets/icons/4.png',
  'assets/icons/5.png',
  'assets/icons/6.png',
  'assets/icons/7.png',
  'assets/icons/8.png',
  'assets/icons/9.png',
  'assets/icons/10.png',
];

class CameraApp extends StatefulWidget {
  const CameraApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  final _controller = CameraViewController();
  int _selectedFrameIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final _capturedImagePath = ''.obs;
  final GlobalKey _stackKey = GlobalKey();
  bool isDrag = false;
  List<UISticker> stickers = [];

  @override
  void initState() {
    _controller.onInitial(
      cameras: widget.cameras,
      isSettingCameraBack: isSettingCameraBack,
      cameraCallback: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _controller.resumeCamera();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: _buildCameraScreen(),
    );
  }

  Widget _buildCameraScreen() {
    if (!_controller.cameraController.value.isInitialized ||
        _controller.cameraController.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              IgnorePointer(
                child: SizedBox(
                  key: _stackKey,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _controller
                          .cameraController
                          .value
                          .previewSize!
                          .height,
                      height:
                          _controller.cameraController.value.previewSize!.width,
                      child: CameraPreview(_controller.cameraController),
                    ),
                  ),
                ),
              ),
              ...stickers.map((sticker) {
                double height = sticker.size;
                double width =
                    (sticker.size / MediaQuery.of(context).size.width) *
                    MediaQuery.of(context).size.width;

                Widget draggableWidget = Container(
                  width: sticker.size,
                  height: sticker.size,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withAlpha(150),
                      width: 1,
                    ),
                  ),
                  child: SizedBox(
                    width: sticker.size,
                    height: sticker.size,
                    child: Image(image: sticker.imageProvider),
                  ),
                );

                return Positioned(
                  left: sticker.x - width / 2,
                  top: sticker.y - height / 2,
                  child: _buildStickerControls(
                    width: width,
                    height: height,
                    sticker: sticker,
                    child: Draggable(
                      feedback: draggableWidget,
                      childWhenDragging: Container(),

                      onDragEnd: (details) {
                        //isDrag = false;
                        RenderBox box =
                            _stackKey.currentContext!.findRenderObject()
                                as RenderBox;
                        Offset localOffset = box.globalToLocal(details.offset);

                        setState(() {
                          sticker.x = localOffset.dx + width / 2 - 15;
                          sticker.y = localOffset.dy + height / 2 - 15;
                        });
                      },
                      onDragStarted: () {
                        setState(() {
                          //isDrag = true;
                        });
                      },
                      child: draggableWidget,
                    ),
                  ),
                );
              }),
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    framePaths[_selectedFrameIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => Visibility(
              visible: _capturedImagePath.isEmpty,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _pickImageFromGallery();
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    iconSize: 32,
                  ),
                  Obx(
                    () => _controller.isTakingPhoto.isTrue
                        ? Container(
                            width: 86,
                            height: 86,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 54,
                              height: 54,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.camera_alt_rounded),
                            iconSize: 32,
                            onPressed: () {
                              _controller.captureCamera((path) {
                                if (!mounted) {
                                  return;
                                }
                                _capturedImagePath.value = path;
                              });
                              _controller.cameraController.pausePreview();
                            },
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.switch_camera),
                    iconSize: 32,
                    onPressed: () {
                      _controller.cameraController.resumePreview();
                      _controller.switchCamera();
                    },
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => Visibility(
              visible: _capturedImagePath.isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _capturedImagePath.value = '';
                        _controller.cameraController.resumePreview();
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Chụp lại'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Dialog(
                              backgroundColor: Colors.transparent,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        );

                        try {
                          await logExecutionTime(
                            'Processing image',
                            () => _processImage(
                              _capturedImagePath.value,
                              framePaths[_selectedFrameIndex],
                              context,
                            ),
                          );
                        } finally {
                          _controller.cameraController.resumePreview();
                          _capturedImagePath.value = '';
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildListFilter(),
          _buildStickerSelector(),
        ],
      ),
    );
  }

  Widget _buildStickerControls({
    required Widget child,
    required double height,
    required double width,
    required UISticker sticker,
  }) {
    void onControlPanUpdate(DragUpdateDetails details) {
      Offset centerOfGestureDetector = Offset(sticker.x, sticker.y);
      final touchPositionFromCenter =
          details.globalPosition - centerOfGestureDetector;
      setState(() {
        var size =
            (math.max(
                  touchPositionFromCenter.dx.abs(),
                  touchPositionFromCenter.dy.abs(),
                ) +
                30) *
            2;
        size = size.clamp(50, 200);
        sticker.size = size;
        print(
          'touchPositionFromCenter.direction: ${touchPositionFromCenter.direction}',
        );
        sticker.angle =
            touchPositionFromCenter.direction - (45 * math.pi / 180);
      });
    }

    return Transform.rotate(
      angle: sticker.angle,
      child: SizedBox(
        width: width + 30,
        height: height + 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            Visibility(
              visible: true,
              child: Container(
                alignment: Alignment.bottomRight,
                child: Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: onControlPanUpdate,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(
                          Icons.crop_free,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stickerPaths.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                stickers.add(
                  UISticker(
                    imageProvider: AssetImage(stickerPaths[index]),
                    x: 100,
                    y: 100,
                    editable: true,
                    size: 100,
                    assetPath: stickerPaths[index],
                  ),
                );
              });
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              child: Image.asset(stickerPaths[index], width: 60, height: 60),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListFilter() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: framePaths.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFrameIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFrameIndex == index
                      ? Colors.blue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Image.asset(framePaths[index], width: 60, height: 60),
            ),
          );
        },
      ),
    );
  }

  Future<T> logExecutionTime<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await action();
    stopwatch.stop();
    debugPrint('$label executed in ${stopwatch.elapsedMilliseconds} ms');
    return result;
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final String path = pickedFile.path;
      _capturedImagePath.value = path;
      await _processImage(path, framePaths[_selectedFrameIndex], context);
    }
  }

  Future<void> _processImage(
    String imagePath,
    String framePath,
    BuildContext context,
  ) async {
    try {
      final frameBytes = await rootBundle.load(framePath);

      final outputBytes = await drawImageWithFrameAndStickers(
        baseImageBytes: await File(imagePath).readAsBytes(),
        frameBytes: frameBytes.buffer.asUint8List(),
        stickers: stickers,
      );

      final newPath = imagePath.replaceFirst('.jpg', '_framed.jpg');
      await File(newPath).writeAsBytes(outputBytes);

      await SaverGallery.saveImage(
        outputBytes,
        quality: 100,
        fileName: "framed_image_${DateTime.now().millisecondsSinceEpoch}",
        skipIfExists: false,
        androidRelativePath: "DCIM",
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to process image: $e')));
      }
    }
  }

  Future<Uint8List> drawImageWithFrameAndStickers({
    required Uint8List baseImageBytes,
    required Uint8List frameBytes,
    required List<UISticker> stickers,
  }) async {
    // Decode ảnh gốc
    final baseCodec = await ui.instantiateImageCodec(baseImageBytes);
    final baseFrame = await baseCodec.getNextFrame();
    final ui.Image baseImage = baseFrame.image;

    // Decode frame
    final frameCodec = await ui.instantiateImageCodec(frameBytes);
    final frameFrame = await frameCodec.getNextFrame();
    final ui.Image frameImage = frameFrame.image;

    // Chuẩn bị canvas 1080x1080
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // ==== 1. CROP ẢNH GỐC VỀ VUÔNG ====
    final double srcWidth = baseImage.width.toDouble();
    final double srcHeight = baseImage.height.toDouble();
    final double aspectRatio = srcWidth / srcHeight;

    Rect srcRect;
    if (aspectRatio > 1) {
      // Ảnh ngang -> crop 2 bên
      final cropWidth = srcHeight;
      final dx = (srcWidth - cropWidth) / 2;
      srcRect = Rect.fromLTWH(dx, 0, cropWidth, srcHeight);
    } else {
      // Ảnh dọc -> crop trên dưới
      final cropHeight = srcWidth;
      final dy = (srcHeight - cropHeight) / 2;
      srcRect = Rect.fromLTWH(0, dy, srcWidth, cropHeight);
    }

    const dstRect = Rect.fromLTWH(0, 0, 1080, 1080);

    canvas.drawImageRect(baseImage, srcRect, dstRect, paint);

    // ==== 2. VẼ FRAME ====
    canvas.drawImageRect(
      frameImage,
      Rect.fromLTWH(
        0,
        0,
        frameImage.width.toDouble(),
        frameImage.height.toDouble(),
      ),
      dstRect,
      paint,
    );

    // ==== 3. VẼ STICKER ====
    // ==== 3. VẼ STICKER ====
    for (final sticker in stickers) {
      final ByteData data = await rootBundle.load(sticker.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec stickerCodec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await stickerCodec.getNextFrame();
      final ui.Image stickerImage = frameInfo.image;
      canvas.save();

      // Calculate scale factor from preview to output (1080x1080)
      final double previewWidth = MediaQuery.of(context).size.width;
      final double scale = 1080 / previewWidth;

      // Scale sticker position and size to output image
      final double stickerSize = sticker.size * scale;
      final double width = stickerSize;
      final double height = stickerSize;

      // Adjust position: sticker.x and sticker.y are center in preview,
      // so scale and use as center in output
      final double stickerCenterX = sticker.x * scale;
      final double stickerCenterY = sticker.y * scale;

      print('scale: ${scale}');
      print('sticker x: ${sticker.x}');
      print('sticker y: ${sticker.y}');

      Paint stickerPaint = Paint()
        ..blendMode = sticker.blendMode
        ..color = Colors.white.withOpacity(sticker.opacity);

      // Draw sticker with rotation and scaling
      canvas.translate(stickerCenterX, stickerCenterY);
      canvas.rotate(sticker.angle);
      canvas.translate(-stickerCenterX, -stickerCenterY);

      Rect src = Rect.fromLTWH(
        0,
        0,
        stickerImage.width.toDouble(),
        stickerImage.height.toDouble(),
      );
      Rect dst = Rect.fromCenter(
        center: Offset(stickerCenterX, stickerCenterY),
        width: width,
        height: height,
      );

      canvas.drawImageRect(stickerImage, src, dst, stickerPaint);
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(1080, 1080);

    final byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final buffer = byteData!.buffer;

    final imgImage = img.Image.fromBytes(
      width: 1080,
      height: 1080,
      bytes: buffer,
      order: img.ChannelOrder.rgba,
    );

    final jpegBytes = img.encodeJpg(imgImage, quality: 100);
    return Uint8List.fromList(jpegBytes);
  }
}
