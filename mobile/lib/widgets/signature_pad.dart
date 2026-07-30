import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SignaturePad extends StatefulWidget {
  final Function(String base64Png) onSave;

  const SignaturePad({super.key, required this.onSave});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;

  bool get _hasPoints => _strokes.any((List<Offset> stroke) => stroke.length >= 2);

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _handleSave() async {
    if (!_hasPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen önce imzanızı çizin.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      const Size canvasSize = Size(600, 300);

      // White background for PNG signature
      final Paint bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), bgPaint);

      // Signature stroke paint
      final Paint strokePaint = Paint()
        ..color = const Color(0xFF0F172A) // AppTheme.primaryColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      // Scale factors if drawn on smaller/larger view
      final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final double scaleX = box != null && box.size.width > 0 ? canvasSize.width / box.size.width : 1.0;
      final double scaleY = box != null && box.size.height > 0 ? canvasSize.height / box.size.height : 1.0;

      for (final List<Offset> stroke in _strokes) {
        if (stroke.length < 2) continue;
        final Path path = Path();
        path.moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
        }
        canvas.drawPath(path, strokePaint);
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);


      if (byteData != null) {
        final String base64String = base64Encode(byteData.buffer.asUint8List());
        widget.onSave(base64String);
      } else {
        throw Exception('İmza görseli oluşturulamadı.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İmza kaydedilirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drawing area
          Expanded(
            child: Container(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final Offset localPos = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _currentStroke = <Offset>[localPos];
                      _strokes.add(_currentStroke!);
                    });
                  }
                },
                onPanUpdate: (DragUpdateDetails details) {
                  final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box != null && _currentStroke != null) {
                    final Offset localPos = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _currentStroke!.add(localPos);
                    });
                  }
                },
                onPanEnd: (DragEndDetails details) {
                  _currentStroke = null;
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: CustomPaint(
                    painter: SignaturePainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _hasPoints ? _clear : null,
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.errorColor),
                  label: Text('Temizle', style: GoogleFonts.inter(color: AppTheme.errorColor)),
                ),
                ElevatedButton.icon(
                  onPressed: _hasPoints ? _handleSave : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('İmzayı Kaydet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final List<Offset> stroke in strokes) {
      if (stroke.length < 2) continue;
      final Path path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
