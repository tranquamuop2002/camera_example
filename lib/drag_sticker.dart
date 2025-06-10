import 'package:flutter/material.dart';

class EditableSticker extends StatefulWidget {
  final String imagePath;
  final VoidCallback onDelete;

  const EditableSticker({
    required this.imagePath,
    required this.onDelete,
    super.key,
  });

  @override
  State<EditableSticker> createState() => _EditableStickerState();
}

class _EditableStickerState extends State<EditableSticker> {
  Offset position = Offset(100, 100);
  double scale = 1.0;
  double rotation = 0.0;

  Offset? initFocalPoint;
  double initScale = 1.0;
  double initRotation = 0.0;

  Offset? dragStart;

  bool isDragging = false;

  void _onDragStart(DragStartDetails details) {
    dragStart = details.globalPosition;
    isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (isDragging) {
      setState(() {
        position += details.delta;
      });
    }
  }

  void _onDragEnd(_) {
    isDragging = false;
  }

  void _onScaleStart(ScaleStartDetails details) {
    initFocalPoint = details.focalPoint;
    initScale = scale;
    initRotation = rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scale = initScale * details.scale;
      rotation = initRotation + details.rotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(scale)
          ..rotateZ(rotation),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            /// Drag gesture ở đây: toàn bộ sticker có thể drag (trừ các nút)
            GestureDetector(
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Container(
                padding: const EdgeInsets.all(24), // để tránh overlap với nút
                child: Image.asset(widget.imagePath, width: 100),
              ),
            ),

            /// Delete button
            Positioned(
              top: -20,
              left: -20,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),

            /// Scale/rotate button
            Positioned(
              bottom: -20,
              right: -20,
              child: GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.open_with, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
