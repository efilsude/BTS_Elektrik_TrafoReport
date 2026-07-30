import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class PhotoPickerWidget extends StatefulWidget {
  final String label;
  final String description;
  final String? imagePath;
  final bool isRequired;
  final ValueChanged<String?> onPhotoSelected;

  const PhotoPickerWidget({
    super.key,
    required this.label,
    required this.description,
    required this.imagePath,
    required this.onPhotoSelected,
    this.isRequired = false,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final PermissionStatus cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotoğraf çekmek için Kamera izni gereklidir.', style: GoogleFonts.inter()),
                backgroundColor: AppTheme.errorColor,
                action: SnackBarAction(
                  label: 'Ayarlar',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        widget.onPhotoSelected(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSelectionModal() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
                  title: Text('Kamera ile Çek', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                  title: Text('Galeriden Seç', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewFullScreenImage() {
    if (widget.imagePath == null) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppBar(
                title: Text(widget.label, style: GoogleFonts.outfit(fontSize: 16)),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Flexible(
                child: File(widget.imagePath!).existsSync()
                    ? Image.file(File(widget.imagePath!))
                    : const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Görsel dosyası bulunamadı.'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.imagePath != null && widget.imagePath!.isNotEmpty;
    final bool fileExists = hasImage && File(widget.imagePath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isRequired && !hasImage
              ? Colors.red.shade300
              : (hasImage ? AppTheme.successColor : Colors.grey.shade300),
          width: widget.isRequired && !hasImage ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  hasImage ? Icons.check_circle : Icons.photo_camera_outlined,
                  color: hasImage ? AppTheme.successColor : (widget.isRequired ? Colors.red : AppTheme.textLight),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label + (widget.isRequired ? ' *' : ''),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (hasImage)
                  Text(
                    'Eklendi',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
            ),
            const SizedBox(height: 12),

            if (hasImage)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black12,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    fileExists
                        ? Image.file(
                            File(widget.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text('Fotoğraf Yüklü (Path)'),
                            ),
                          ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _viewFullScreenImage,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              onPressed: _viewFullScreenImage,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.red.shade700,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                              onPressed: () => widget.onPhotoSelected(null),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _showSelectionModal,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(
                  'Fotoğraf Ekle (Kamera / Galeri)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: widget.isRequired ? Colors.red.shade400 : AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
