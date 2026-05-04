import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// WhatsApp-style image editor with drawing, text overlay, and full color picker.
/// Used after image picking, before sending.
class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Drawing state
  final List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.white;
  double _selectedStrokeWidth = 4.0;

  // Text overlay state
  final List<TextOverlay> _textOverlays = [];
  bool _isTextMode = false;
  final TextEditingController _textController = TextEditingController();

  // Tool state
  bool _isDrawingMode = true;
  bool _showColorPicker = false;
  bool _isEraser = false;

  // Undo stack
  final List<_UndoAction> _undoStack = [];

  static const List<Color> _colorPalette = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    if (action.type == _UndoType.drawing) {
      // Remove last stroke
      int strokeStart = action.strokeStartIndex;
      _points.removeRange(strokeStart, _points.length);
    } else if (action.type == _UndoType.text) {
      if (_textOverlays.isNotEmpty) {
        _textOverlays.removeLast();
      }
    }
    setState(() {});
  }

  void _addTextOverlay() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _textOverlays.add(TextOverlay(
        text: text,
        offset: Offset(
          MediaQuery.of(context).size.width / 2 - 60,
          MediaQuery.of(context).size.height / 2 - 20,
        ),
        color: _selectedColor,
        fontSize: 24.0,
      ));
      _undoStack.add(_UndoAction(type: _UndoType.text));
      _textController.clear();
      _isTextMode = false;
      _isDrawingMode = true;
    });
  }

  Future<void> _saveAndReturn() async {
    try {
      // Wait for frame to render
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      final dir = await getTemporaryDirectory();
      final outputPath = p.join(dir.path, 'edited_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) Navigator.of(context).pop(outputPath);
    } catch (e) {
      if (mounted) Navigator.of(context).pop(widget.imagePath);
    }
  }

  /// Show WhatsApp-style full color picker dialog with HSL wheel + opacity slider
  void _showFullColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text('Pick Color', style: GoogleFonts.poppins(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HSL Color Picker Wheel
                ColorPicker(
                  color: tempColor,
                  onColorChanged: (color) {
                    tempColor = color;
                  },
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  heading: Text('Select color', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  subheading: Text('Shade', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  pickColorEnabled: true,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hslWheel,
                  labelStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                  _isEraser = false;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: tempColor),
              child: const Text('Select', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Image',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 28),
            onPressed: _saveAndReturn,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Stack(
                children: [
                  // Base image
                  Center(
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Drawing layer
                  GestureDetector(
                    onPanStart: _isDrawingMode
                        ? (details) {
                            setState(() {
                              _undoStack.add(_UndoAction(
                                type: _UndoType.drawing,
                                strokeStartIndex: _points.length,
                              ));
                              _points.add(DrawingPoint(
                                offset: details.localPosition,
                                color: _isEraser ? Colors.transparent : _selectedColor,
                                strokeWidth: _isEraser ? 30.0 : _selectedStrokeWidth,
                                isEraser: _isEraser,
                              ));
                            });
                          }
                        : null,
                    onPanUpdate: _isDrawingMode
                        ? (details) {
                            setState(() {
                              _points.add(DrawingPoint(
                                offset: details.localPosition,
                                color: _isEraser ? Colors.transparent : _selectedColor,
                                strokeWidth: _isEraser ? 30.0 : _selectedStrokeWidth,
                                isEraser: _isEraser,
                              ));
                            });
                          }
                        : null,
                    onPanEnd: _isDrawingMode
                        ? (details) {
                            setState(() {
                              _points.add(DrawingPoint(
                                offset: Offset.zero,
                                color: _selectedColor,
                                strokeWidth: 0,
                                isEnd: true,
                              ));
                            });
                          }
                        : null,
                    child: CustomPaint(
                      painter: DrawingPainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                  // Text overlays
                  ..._textOverlays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final overlay = entry.value;
                    return Positioned(
                      left: overlay.offset.dx,
                      top: overlay.offset.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _textOverlays[index] = TextOverlay(
                              text: overlay.text,
                              offset: overlay.offset + details.delta,
                              color: overlay.color,
                              fontSize: overlay.fontSize,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white38, width: 1),
                          ),
                          child: Text(
                            overlay.text,
                            style: TextStyle(
                              color: overlay.color,
                              fontSize: overlay.fontSize,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Text input bar
          if (_isTextMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black87,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Type text...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _selectedColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _selectedColor, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _addTextOverlay(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: Colors.greenAccent, size: 32),
                    onPressed: _addTextOverlay,
                  ),
                ],
              ),
            ),

          // Color picker
          if (_showColorPicker)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick color palette
                  Row(
                    children: [
                      Text('Quick', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _colorPalette.map((color) {
                              final isSelected = color == _selectedColor && !_isEraser;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                    _isEraser = false;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.greenAccent : Colors.white24,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Custom color button (opens full HSL wheel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showFullColorPicker,
                      icon: Icon(Icons.color_lens_rounded, color: _selectedColor),
                      label: Text(
                        'Custom Color',
                        style: GoogleFonts.poppins(color: _selectedColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _selectedColor.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Stroke width slider
                  Row(
                    children: [
                      Text('Size', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: _selectedStrokeWidth,
                          min: 1,
                          max: 20,
                          activeColor: _selectedColor,
                          onChanged: (v) => setState(() => _selectedStrokeWidth = v),
                        ),
                      ),
                      Text(_selectedStrokeWidth.round().toString(),
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1A1A2E),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Draw tool
                  _ToolButton(
                    icon: Icons.brush_rounded,
                    label: 'Draw',
                    isActive: _isDrawingMode && !_isEraser,
                    color: _isDrawingMode && !_isEraser ? _selectedColor : Colors.white70,
                    onTap: () => setState(() {
                      _isDrawingMode = true;
                      _isEraser = false;
                      _isTextMode = false;
                    }),
                  ),
                  // Color picker toggle
                  _ToolButton(
                    icon: Icons.palette_rounded,
                    label: 'Color',
                    isActive: _showColorPicker,
                    color: _selectedColor,
                    onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                  ),
                  // Eraser
                  _ToolButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Eraser',
                    isActive: _isEraser,
                    color: _isEraser ? Colors.redAccent : Colors.white70,
                    onTap: () => setState(() {
                      _isDrawingMode = true;
                      _isEraser = true;
                      _isTextMode = false;
                    }),
                  ),
                  // Text tool
                  _ToolButton(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    isActive: _isTextMode,
                    color: _isTextMode ? _selectedColor : Colors.white70,
                    onTap: () => setState(() {
                      _isDrawingMode = false;
                      _isTextMode = true;
                      _isEraser = false;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? color : Colors.white54,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data classes ───

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final bool isEnd;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.isEnd = false,
  });
}

class TextOverlay {
  String text;
  Offset offset;
  Color color;
  double fontSize;

  TextOverlay({
    required this.text,
    required this.offset,
    required this.color,
    required this.fontSize,
  });
}

enum _UndoType { drawing, text }

class _UndoAction {
  final _UndoType type;
  final int strokeStartIndex;

  _UndoAction({required this.type, this.strokeStartIndex = 0});
}

// ─── Custom painter for drawing ───

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current.isEnd || next.isEnd) continue;

      final paint = Paint()
        ..color = current.isEraser ? Colors.transparent : current.color
        ..strokeWidth = current.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = current.isEraser ? BlendMode.clear : BlendMode.srcOver;

      canvas.drawLine(current.offset, next.offset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
