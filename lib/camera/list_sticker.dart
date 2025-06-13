import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sticker_custom/image_stickers.dart';

class ListSticker extends StatefulWidget {
  const ListSticker({
    super.key,
    required this.stackKey,
    required this.stickers,
  });

  final GlobalKey stackKey;
  final List<UISticker> stickers;

  @override
  State<ListSticker> createState() => _ListStickerState();
}

class _ListStickerState extends State<ListSticker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.stickers.map((sticker) {
          double height = sticker.size;
          double width =
              (sticker.size / MediaQuery.of(context).size.width) *
              MediaQuery.of(context).size.width;

          Widget draggableWidget = Transform.rotate(
            angle: sticker.angle,
            child: Container(
              width: sticker.size,
              height: sticker.size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(150), width: 1),
              ),
              child: SizedBox(
                width: sticker.size,
                height: sticker.size,
                child: Image(image: sticker.imageProvider),
              ),
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
                      widget.stackKey.currentContext!.findRenderObject()
                          as RenderBox;
                  Offset localOffset = box.globalToLocal(details.offset);

                  setState(() {
                    sticker.x = localOffset.dx;
                    sticker.y = localOffset.dy;
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
      ],
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
}
