// lib/utils/ocr_helper.dart

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrHelper {
  static Future<String?> scanStruk() async {
    // 1. Buka Kamera
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return null; // Batal memfoto

    // 2. Siapkan AI Google ML Kit
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    // 3. AI Mulai Membaca Teks di Gambar
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close(); // Matikan AI untuk menghemat RAM

    // 4. Algoritma Pencari Total Belanja (Heuristic)
    // Logikanya: Pada sebuah struk, angka nominal "Total" biasanya adalah angka yang paling besar.
    double maxAmount = 0.0;

    // Regex untuk mencari pola angka (contoh: 15.000 atau 15000)
    final RegExp regex = RegExp(r'\b\d{2,}(?:\.\d{3})*\b');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.replaceAll('Rp', '').replaceAll(' ', '');
        final matches = regex.allMatches(text);

        for (final match in matches) {
          // Bersihkan titik agar bisa dihitung komputer
          String cleanNumber = match.group(0)!.replaceAll('.', '');

          try {
            double value = double.parse(cleanNumber);
            // Cari angka terbesar di struk (Abaikan angka kecil seperti jumlah barang atau diskon)
            if (value > maxAmount && value < 10000000) { // Batas masuk akal: 10 juta
              maxAmount = value;
            }
          } catch (e) {
            // Abaikan jika bukan angka
          }
        }
      }
    }

    if (maxAmount > 0) {
      return maxAmount.toStringAsFixed(0); // Kembalikan hasil tanpa koma
    }

    return null; // Jika gagal menemukan angka
  }
}