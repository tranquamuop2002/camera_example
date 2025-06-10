import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'dart:ui' as ui;

import 'sticker/image_sticker.dart';

class TestImageSticker extends StatefulWidget {
  const TestImageSticker({Key? key}) : super(key: key);

  @override
  State<TestImageSticker> createState() => _TestImageStickerState();
}

class _TestImageStickerState extends State<TestImageSticker> {
  List<UISticker> stickers = [];

  late ImageStickersController controller;

  Uint8List? resultImage;

  @override
  void initState() {
    super.initState();
    stickers.add(createSticker(0));
    controller = ImageStickersController();
  }

  UISticker createSticker(int index) {
    return UISticker(
        imageProvider: const AssetImage("assets/icons/1.png"),
        x: 100 + 100.0 * index,
        y: 360,
        editable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          stickers.add(createSticker(stickers.length));
                        });
                      },
                      child: const Text("Add sticker")),
                  TextButton(
                      onPressed: () async {
                        var image = await controller.getImage();
                        var byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);
                        setState(() {
                          resultImage = byteData!.buffer.asUint8List();
                        });
                        if (resultImage != null) {
                          await SaverGallery.saveImage(
                            resultImage!,
                            quality: 100,
                            fileName: "framed_image_${DateTime.now().millisecondsSinceEpoch}",
                            skipIfExists: false,
                            androidRelativePath: "DCIM",
                          );
                        }
                      },
                      child: const Text("Save Image")),
                ],
              ),
              Expanded(
                  flex: 7,
                  child: ImageStickers(
                    backgroundImage: const AssetImage("assets/icons/hehe.png"),
                    stickerList: stickers,
                    controller: controller,
                    stickerControlsBehaviour: StickerControlsBehaviour.alwaysShow,
                  )),
              Expanded(
                  flex: 3,
                  child: resultImage == null
                      ? Container()
                      : Image(
                    image: MemoryImage(resultImage!),
                  ))
            ],
          )), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}