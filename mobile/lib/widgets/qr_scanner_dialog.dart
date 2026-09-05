import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/label_ocr_service.dart';
import '../theme/app_theme.dart';

// Conditionally import Windows-only scanner widget
import 'qr_scanner_windows.dart'
    if (dart.library.html) 'qr_scanner_stub.dart'
    as windows_scanner;

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  static Future<String?> scan(BuildContext context) async {
    // Windows desktop: show the dedicated Windows camera/zxing scanner
    if (!kIsWeb && Platform.isWindows) {
      return windows_scanner.showWindowsQrScanner(context);
    }
    // Mobile (Android/iOS/etc.): use existing MobileScanner dialog
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const QrScannerDialog(),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  bool _isOcrProcessing = false;
  final TextEditingController _manualController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final Barcode barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _isProcessing = true;
        Navigator.of(context).pop(barcode.rawValue);
        break;
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final String? code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty && mounted) {
            Navigator.of(context).pop(code);
            return;
          }
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel analiz edilirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Eski trafolarda etikette QR/barkod BULUNMADIĞI durumlar için: etiketin
  /// fotoğrafı çekilir ve TAMAMEN CİHAZ ÜZERİNDE (Google ML Kit, internet/
  /// API anahtarı/sunucu isteği OLMADAN, maliyetsiz) metne dönüştürülür.
  /// Okunan ham metin, QR akışıyla aynı şekilde geri döndürülür ki bu
  /// diyaloğu çağıran ekran (`_simulateQrScan`) zaten var olan regex
  /// tabanlı alan ayrıştırma mantığını hiç değiştirmeden aynen kullanabilsin.
  /// Kamera/QR tarama akışına dokunulmaz; bu tamamen ayrı, opsiyonel bir
  /// buton/yoldur.
  Future<void> _scanLabelPhotoWithOcr() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) return;

      setState(() => _isOcrProcessing = true);

      final String recognizedText = await LabelOcrService.recognizeText(image.path);

      if (recognizedText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Etikette okunabilir metin bulunamadı. Lütfen etiketin '
                'tamamının net ve iyi ışıklandırılmış göründüğü bir '
                'fotoğraf çekip tekrar deneyin.',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // QR akışındaki regex parse dalını tetiklemesi için okunan ham
        // metin, QR koddan gelen bir metinmiş gibi geri döndürülür.
        Navigator.of(context).pop(recognizedText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etiket fotoğrafı okunurken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOcrProcessing = false);
      }
    }
  }

  void _showManualInputDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Manuel Seri No / QR Girişi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 400,
        height: 530,
        color: AppTheme.surfaceColor,
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.primaryColor,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'QR / Barkod Tara',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: () => _controller.toggleTorch(),
                    tooltip: 'Flaş',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Camera Scanner View
            Expanded(
              child: Stack(
                children: <Widget>[
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  // Scanner Overlay Frame
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
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Kamerayı etiketteki QR koda hizalayın',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  if (_isOcrProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.55),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 12),
                            Text(
                              'Etiket fotoğrafı cihaz üzerinde okunuyor...',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Actions: Gallery Pick & Manual Entry
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isOcrProcessing ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text('Galeriden Seç', style: GoogleFonts.inter(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isOcrProcessing ? null : _showManualInputDialog,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text('Manuel Gir', style: GoogleFonts.inter(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Eski trafolarda QR/barkod yoksa: etiketin fotoğrafını
                  // çekip cihaz üzerinde (ücretsiz, offline) OCR ile
                  // okutmak için ayrı, opsiyonel buton.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isOcrProcessing ? null : _scanLabelPhotoWithOcr,
                      icon: const Icon(Icons.document_scanner_outlined, size: 18),
                      label: Text(
                        'QR Yok mu? Etiketi Fotoğrafla (Metin Oku)',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
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
}
