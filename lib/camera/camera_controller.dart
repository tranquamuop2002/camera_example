import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:get/get.dart';

import '../common_callback.dart';

var isSettingCameraBack = true;

class CameraViewController extends GetxController {
  late CameraController cameraController;
  late CameraDescription cameraDescription;
  late List<CameraDescription> cameras;
  final isInitCamera = false.obs;
  final isTakingPhoto = false.obs;
  VoidCallback? cameraCallback;

  onInitial(
      {required List<CameraDescription> cameras,
      required VoidCallback cameraCallback,
      required bool isSettingCameraBack}) {
    this.cameras = cameras;
    cameraDescription = isSettingCameraBack ? cameras[0] : cameras[1];
    this.cameraCallback = cameraCallback;
  }

  _initCamera() {
    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    if (cameraCallback != null) {
      cameraController.removeListener(cameraCallback!);
      cameraController.addListener(cameraCallback!);
    }
  }

  switchCamera() {
    if (cameras.length > 1) {
      if (cameraDescription == cameras[0]) {
        cameraDescription = cameras[1];
        isSettingCameraBack = false;
      } else {
        cameraDescription = cameras[0];
        isSettingCameraBack = true;
      }
      cameraController.setDescription(cameraDescription);
    }
  }

  pauseCamera() {
    cameraController.dispose();
  }

  resumeCamera() async {
    isInitCamera.value = true;
    try {
      _initCamera();
      await cameraController.initialize();
    } catch (e) {
      e.printInfo();
    }
    isInitCamera.value = false;
  }

  captureCamera(StringCallBack callback) async {
    isTakingPhoto.value = true;
    try {
      if (cameraController.value.isTakingPicture) {
        return null;
      }
      final XFile image = await cameraController.takePicture();
      var result = await FlutterImageCompress.compressWithFile(
        image.path,
        rotate: 0,
        autoCorrectionAngle: true,
      );
      File file = File(image.path);
      if (result != null) {
        await file.writeAsBytes(result);
      }
      callback(image.path);
      isTakingPhoto.value = false;
    } catch (e) {
      print("error camera: ${e.toString()}");
      isTakingPhoto.value = false;
    }
  }

  onDispose() {
    cameraController.dispose();
  }
}
