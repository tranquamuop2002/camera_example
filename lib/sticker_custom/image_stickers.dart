library image_stickers;

import 'dart:core';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../sticker/image_sticker_style.dart';

/// Enum to set behaviour of controls for stickers
enum StickerControlsBehaviour {
  /// Controls are always shown.
  alwaysShow,

  /// Show controls on tap on sticker. By default controls are hidden.
  showOnTap,

  /// Hide controls on tap on sticker. By default controls are shown.
  hideOnTap,

  /// Controls are always hidden.
  alwaysHide,
}

/// Class to describe a sticker
///
/// Set [editable] to true if you want to edit this sticker.
/// [x], [y], [size], [angle] will be updated after edit is finished.
class UISticker {
  ImageProvider imageProvider;
  double x;
  double y;
  double size;
  double angle;
  BlendMode blendMode;
  double opacity;
  String assetPath;

  bool editable = false;

  UISticker(
      {required this.imageProvider,
      required this.x,
      required this.y,
      this.size = 100,
      this.angle = 0.0,
      this.opacity = 1.0,
      this.blendMode = BlendMode.srcATop,
      this.editable = false, required this.assetPath});
}

/// A widget to draw [backgroundImage] and list of [UISticker]
///
/// Takes [ImageProvider] as a background image.
class ImageStickers extends StatefulWidget {
  final List<UISticker> stickerList;

  /// Minimal size sticker can be resized to by using edit controls.
  final double minStickerSize;

  /// Maximal size sticker can be resized to by using edit controls.
  final double maxStickerSize;

  /// Set style to change controls thumb appearance.
  final ImageStickersControlsStyle? stickerControlsStyle;

  final StickerControlsBehaviour stickerControlsBehaviour;

  final ImageStickersController? controller;

  const ImageStickers(
      {required this.stickerList,
      this.minStickerSize = 50.0,
      this.maxStickerSize = 200.0,
      this.stickerControlsStyle,
      this.stickerControlsBehaviour = StickerControlsBehaviour.alwaysShow,
      this.controller,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ImageStickersState();
  }
}

class _ImageStickersState extends State<ImageStickers> {
  final GlobalKey _key = GlobalKey();

  Map<UISticker, _DrawableSticker> stickerMap = {};

  late _EditableStickerController stickerController;

  @override
  void initState() {
    super.initState();
    _getImages(widget.stickerList);
    stickerController = _EditableStickerController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => getOffset());
  }

  void getOffset() {
    final RenderObject? renderBoxWidget =
        _key.currentContext?.findRenderObject();
    if (renderBoxWidget != null) {
      stickerController.parentOffset =
          (renderBoxWidget as RenderBox).localToGlobal(Offset.zero);
    }
  }

  /// I want to support BlendMode for images and I draw images in CustomPainter.
  /// So I resolve all the [ImageProvider] here and update state when image is
  /// resolved.
  void _getImages(List<UISticker> stickerList) async {
    var oldStickers = stickerMap;
    stickerMap = {};

    for (var sticker in stickerList) {
      var drawableSticker = oldStickers[sticker] ?? _DrawableSticker(sticker);
      oldStickers.remove(sticker);
      var stickerImageStream =
          sticker.imageProvider.resolve(ImageConfiguration.empty);
      if (stickerImageStream.key != drawableSticker.imageStream?.key) {
        if (drawableSticker.listener != null) {
          drawableSticker.imageStream
              ?.removeListener(drawableSticker.listener!);
        }
        drawableSticker.imageInfo?.dispose();

        drawableSticker.listener =
            ImageStreamListener((ImageInfo image, bool synchronousCall) {
          setState(() {
            drawableSticker.imageInfo = image;
          });
        });

        drawableSticker.imageStream = stickerImageStream;
        drawableSticker.imageStream!.addListener(drawableSticker.listener!);
      }
      stickerMap[sticker] = drawableSticker;
    }
    for (var element in oldStickers.values) {
      element.imageInfo?.dispose();
    }
  }

  /// We might need to resolve images again after widget update.
  @override
  void didUpdateWidget(ImageStickers oldWidget) {
    super.didUpdateWidget(oldWidget);
    _getImages(widget.stickerList);
  }

  @override
  void dispose() {
    for (var element in stickerMap.values) {
      element.imageInfo?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loadedStickers =
        stickerMap.values.where((element) => element.imageInfo != null);
    var editableStickers = loadedStickers
        .where((element) => element.editable)
        .map((sticker) => _EditableSticker(
              sticker: sticker,
              onStateChanged: (isDragged) {
                setState(() {});
              },
              maxStickerSize: widget.maxStickerSize,
              minStickerSize: widget.minStickerSize,
              stickerControlsStyle: widget.stickerControlsStyle,
              controller: stickerController,
              stickerControlsBehaviour: widget.stickerControlsBehaviour,
            ))
        .toList();

    Widget customPaint = CustomPaint(
      painter: _DropPainter(null, loadedStickers.toList()),
    );

    return Stack(
      key: _key,
      children: [
        LayoutBuilder(
          builder: (_, constraints) => SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.width / 1.0,
            child: customPaint,
          ),
        ),
        ...editableStickers
      ],
    );
  }
}

class _EditableStickerController extends ChangeNotifier {
  Offset? _parentOffset;

  set parentOffset(Offset? offset) {
    _parentOffset = offset;
    notifyListeners();
  }

  Offset? get parentOffset => _parentOffset;
}

class _EditableSticker extends StatefulWidget {
  final _DrawableSticker sticker;
  final Function(bool isDragged)? onStateChanged;
  final double minStickerSize;
  final double maxStickerSize;
  final _EditableStickerController? controller;

  final ImageStickersControlsStyle? stickerControlsStyle;
  final StickerControlsBehaviour stickerControlsBehaviour;

  const _EditableSticker(
      {required this.sticker,
      required this.minStickerSize,
      required this.maxStickerSize,
      required this.stickerControlsBehaviour,
      this.onStateChanged,
      this.stickerControlsStyle,
      this.controller,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditableStickerState();
  }
}

class _EditableStickerState extends State<_EditableSticker> {
  late ImageStickersControlsStyle controlsStyle;

  late bool showControls;

  @override
  void initState() {
    super.initState();
    controlsStyle = widget.stickerControlsStyle ?? ImageStickersControlsStyle();
    showControls = widget.stickerControlsBehaviour ==
            StickerControlsBehaviour.alwaysShow ||
        widget.stickerControlsBehaviour == StickerControlsBehaviour.hideOnTap;
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.sticker.size;
    double width =
        (widget.sticker.size / widget.sticker.imageInfo!.image.height) *
            widget.sticker.imageInfo!.image.width;

    Widget stickerDraggableChild = Transform.rotate(
        angle: widget.sticker.angle,
        child: SizedBox(
          width: width,
          height: height,
          child: Image(
            image: widget.sticker.imageProvider,
          ),
        ));
    Widget draggableEmptyWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(150), width: 1)),
    );
    return Positioned(
      left: widget.sticker.x - width / 2 - controlsStyle.size,
      top: widget.sticker.y - height / 2 - controlsStyle.size,
      child: _buildStickerControls(
          child: Draggable(
            child: draggableEmptyWidget,
            feedback: stickerDraggableChild,
            childWhenDragging: Container(),
            dragAnchorStrategy: (draggable, context, position) {
              final RenderBox renderObject =
                  context.findRenderObject()! as RenderBox;
              var local = renderObject.globalToLocal(position);

              var x = local.dx - width / 2;
              var y = local.dy - height / 2;

              var dx =
                  x * cos(widget.sticker.angle) - y * sin(widget.sticker.angle);
              var dy =
                  x * sin(widget.sticker.angle) + y * cos(widget.sticker.angle);

              dx = dx + width / 2;
              dy = dy + height / 2;

              return Offset(dx, dy);
            },
            onDragEnd: (dragDetails) {
              setState(() {
                widget.sticker.dragged = false;
                var parentDx = widget.controller?.parentOffset?.dx ?? 0;
                var parentDy = widget.controller?.parentOffset?.dy ?? 0;
                widget.sticker.x = dragDetails.offset.dx + width / 2 - parentDx;
                widget.sticker.y =
                    dragDetails.offset.dy + height / 2 - parentDy;

                widget.onStateChanged?.call(false);
              });
            },
            onDragStarted: () {
              setState(() {
                widget.sticker.dragged = true;
                //todo update in parent in onChanged?
                widget.onStateChanged?.call(true);
              });
            },
          ),
          width: width,
          height: height),
    );
  }

  Widget _buildStickerControls(
      {required Widget child, required double height, required double width}) {
    return Transform.rotate(
        angle: widget.sticker.angle,
        child: SizedBox(
          width: width + controlsStyle.size * 2,
          height: height + controlsStyle.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                  onTap: () {
                    if (widget.stickerControlsBehaviour ==
                            StickerControlsBehaviour.showOnTap ||
                        widget.stickerControlsBehaviour ==
                            StickerControlsBehaviour.hideOnTap) {
                      setState(() {
                        showControls = !showControls;
                      });
                    }
                  },
                  child: child),
              Visibility(
                  visible: areControlsVisible(),
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Stack(
                      children: [
                        GestureDetector(
                          child: _buildControlsThumb(),
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: onControlPanUpdate,
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ));
  }

  bool areControlsVisible() {
    return showControls && !widget.sticker.dragged;
  }

  Widget _buildControlsThumb() => Container(
        width: controlsStyle.size,
        height: controlsStyle.size,
        decoration: BoxDecoration(
            color: controlsStyle.color,
            borderRadius: controlsStyle.borderRadius ??
                BorderRadius.circular(controlsStyle.size / 2)),
        child: controlsStyle.child ?? Container(),
      );

  void onControlPanUpdate(DragUpdateDetails details) {
    Offset centerOfGestureDetector = Offset(widget.sticker.x, widget.sticker.y);
    final touchPositionFromCenter =
        details.globalPosition - centerOfGestureDetector;
    setState(() {
      var size = (math.max(touchPositionFromCenter.dx.abs(),
                  touchPositionFromCenter.dy.abs()) -
              controlsStyle.size) *
          2;
      size = size.clamp(widget.minStickerSize, widget.maxStickerSize);
      widget.sticker.size = size;
      widget.sticker.angle =
          touchPositionFromCenter.direction - (45 * math.pi / 180);
    });
  }
}

class _DropPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final List<_DrawableSticker> stickers;

  _DropPainter(this.backgroundImage, this.stickers);

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      final paint = Paint();
      canvas.drawImage(backgroundImage!, Offset.zero, paint);
    }

    for (var sticker in stickers) {
      final image = sticker.imageInfo?.image;
      if (image != null) {
        final paint = Paint()
          ..blendMode = sticker.blendMode
          ..color = Color.fromRGBO(255, 255, 255, sticker.opacity);
        final double height = sticker.size;
        final double width = (sticker.size / image.height) * image.width;
        canvas.save();
        canvas.translate(sticker.x, sticker.y);
        canvas.rotate(sticker.angle);
        canvas.translate(-width / 2, -height / 2);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(0, 0, width, height),
            paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// A proxy for UISticker to store ImageStream and ImageInfo
/// after ImageProvider resolve
class _DrawableSticker {
  final UISticker _sticker;
  bool dragged = false;
  ImageStream? imageStream;
  ImageInfo? imageInfo;
  ImageStreamListener? listener;

  _DrawableSticker(this._sticker);

  double get x => _sticker.x;

  set x(double x) {
    _sticker.x = x;
  }

  double get y => _sticker.y;

  set y(double y) {
    _sticker.y = y;
  }

  double get opacity => _sticker.opacity;

  set opacity(double opacity) {
    _sticker.opacity = opacity;
  }

  double get size => _sticker.size;

  set size(double size) {
    _sticker.size = size;
  }

  double get angle => _sticker.angle;

  set angle(double angle) {
    _sticker.angle = angle;
  }

  bool get editable => _sticker.editable;

  BlendMode get blendMode => _sticker.blendMode;

  ImageProvider get imageProvider => _sticker.imageProvider;
}

class ImageStickersController extends ChangeNotifier {
  Size? _size;
  CustomPainter? _customPainter;

  Future<ui.Image> getImage() {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    if (_size == null || _customPainter == null) {
      throw StateError("Controller is not attached to a widget");
    }
    _customPainter!.paint(canvas, _size!);
    return recorder
        .endRecording()
        .toImage(_size!.width.toInt(), _size!.height.toInt());
  }
}
