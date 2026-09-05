import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Eski trafoların etiketlerinde QR/barkod bulunmadığı durumlar için:
/// etiketin fotoğrafı çekilip TAMAMEN CİHAZ ÜZERİNDE (Google ML Kit),
/// internet bağlantısı, sunucu isteği veya API anahtarı olmadan metne
/// dönüştürülür. Maliyeti sıfırdır ve uygulamanın "Faz 1 tamamen
/// offline" tasarımıyla uyumludur.
///
/// Çıktı olarak dönen ham metin, mevcut QR akışındaki regex tabanlı
/// alan ayrıştırıcıya (`_simulateQrScan` içindeki `patterns` haritası)
/// AYNI ŞEKİLDE verilir; bu servis kendi başına alan ayrıştırması
/// yapmaz, yalnızca fotoğraftaki metni okur.
class LabelOcrService {
  /// [imagePath] konumundaki etiket fotoğrafını cihaz üzerinde OCR ile
  /// okuyup, üzerinde bulunan tüm metni tek bir string olarak döndürür.
  ///
  /// Etikette hiç okunabilir metin yoksa boş string döner.
  static Future<String> recognizeText(String imagePath) async {
    final TextRecognizer recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await recognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
