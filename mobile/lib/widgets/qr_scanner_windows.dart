// Windows-only QR scanner widget using camera_windows + zxing_lib.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/common.dart';

import '../theme/app_theme.dart';

/// Shows the Windows-specific QR / barcode scanner dialog.
/// Uses [camera_windows] for live webcam scanning decoded with [zxing_lib].
/// Falls back to image file pick + manual entry if no camera is detected.
Future<String?> showWindowsQrScanner(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => const _WindowsQrScannerDialog(),
  );
}

class _WindowsQrScannerDialog extends StatefulWidget {
  const _WindowsQrScannerDialog();

  @override
  State<_WindowsQrScannerDialog> createState() =>
      _WindowsQrScannerDialogState();
}

class _WindowsQrScannerDialogState extends State<_WindowsQrScannerDialog> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _scanning = false;
  String? _error;
  Timer? _frameTimer;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _error =
              'Kamera bulunamadı.\nLütfen dosyadan seçin veya seri numarasını girin.');
        }
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
        _startFrameScanning();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Kamera başlatılamadı: $e\nLütfen dosyadan seçin veya seri numarasını girin.');
      }
    }
  }

  void _startFrameScanning() {
    // Capture a frame every 700ms and attempt QR decode.
    _frameTimer = Timer.periodic(const Duration(milliseconds: 700), (_) async {
      if (_scanning ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }
      _scanning = true;
      try {
        final XFile shot = await _cameraController!.takePicture();
        final Uint8List bytes = await File(shot.path).readAsBytes();
        // Delete temp file immediately
        try {
          await File(shot.path).delete();
        } catch (_) {}
        final String? result = await _decodeQrFromJpegBytes(bytes);
        if (result != null && result.isNotEmpty && mounted) {
          _frameTimer?.cancel();
          Navigator.of(context).pop(result);
        }
      } catch (_) {
        // Silently ignore individual frame errors; keep scanning.
      } finally {
        _scanning = false;
      }
    });
  }

  /// Decodes a QR/barcode from JPEG bytes using the pure-Dart [image] package
  /// for pixel extraction and [zxing_lib] for barcode recognition.
  Future<String?> _decodeQrFromJpegBytes(Uint8List jpegBytes) async {
    try {
      // Decode JPEG → img.Image (RGBA pixels)
      final img.Image? decoded = img.decodeImage(jpegBytes);
      if (decoded == null) return null;

      // Downsample to max 640×480 to keep decode fast
      final img.Image resized = (decoded.width > 640 || decoded.height > 480)
          ? img.copyResize(decoded, width: 640, height: 480)
          : decoded;

      final int w = resized.width;
      final int h = resized.height;

      // Build ARGB Int32List for RGBLuminanceSource
      final Int32List pixels = Int32List(w * h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          final int r = pixel.r.toInt();
          final int g = pixel.g.toInt();
          final int b = pixel.b.toInt();
          pixels[y * w + x] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }

      final RGBLuminanceSource source = RGBLuminanceSource(w, h, pixels);
      final BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      final MultiFormatReader reader = MultiFormatReader();
      final Result result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      return null;
    }
  }

  /// Lets the user pick an image file and attempts QR decode from it.
  Future<void> _pickImageAndDecode() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;

      final Uint8List bytes =
          await File(result.files.single.path!).readAsBytes();
      final String? code = await _decodeQrFromJpegBytes(bytes);

      if (code != null && code.isNotEmpty && mounted) {
        Navigator.of(context).pop(code);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Seçilen görselde QR veya Barkod bulunamadı.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showManualInputDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            'Manuel Seri No / QR Girişi',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _manualController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Örn: SN-99887766',
              labelText: 'Seri No / Kod',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final String text = _manualController.text.trim();
                Navigator.of(ctx).pop();
                if (text.isNotEmpty && mounted) {
                  Navigator.of(context).pop(text);
                }
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          children: <Widget>[
            // ── Header ─────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryColor,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'QR / Barkod Tara — Webcam',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Camera View / Error / Loading ───────────────────
            Expanded(
              child: _buildCameraArea(),
            ),

            // ── Bottom Actions ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImageAndDecode,
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: Text(
                        'Dosyadan Seç',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        'Manuel Gir',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                style:
                    GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Kamera başlatılıyor...'),
          ],
        ),
      );
    }

    return Stack(
      children: <Widget>[
        // Live webcam preview
        CameraPreview(_cameraController!),

        // QR targeting frame overlay
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Hint text
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Webcam\'i QR koda yöneltin — otomatik algılanır',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
