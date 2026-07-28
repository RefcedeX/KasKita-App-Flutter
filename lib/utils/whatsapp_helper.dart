// lib/utils/whatsapp_helper.dart

import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {

  // ─── 1. MESIN TAGIHAN BULANAN REGULER (Yang error tadi) ───
  static Future<void> kirimTagihan(String nama, String? noHp) async {
    if (noHp == null || noHp.isEmpty || noHp.length < 10) {
      throw Exception('Nomor HP tidak valid');
    }

    String formattedPhone = noHp.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    String pesan = "Halo $nama! 👋\n\n"
        "Mengingatkan nih, uang kas kelas untuk *bulan ini* belum lunas.\n"
        "Yuk segera dilunasi agar kas kelas kita aman! Bisa bayar cash atau transfer via QRIS ya.\n\n"
        "Terima kasih! 🙏😊";

    final Uri waUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(pesan)}");

    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }

  // ─── 2. MESIN TAGIHAN MINGGUAN KHUSUS (Fitur Baru) ───
  static Future<void> kirimTagihanMingguan(String nama, String? noHp) async {
    if (noHp == null || noHp.isEmpty || noHp.length < 10) {
      throw Exception('Nomor HP tidak valid');
    }

    String formattedPhone = noHp.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    String pesan = "Halo $nama! 👋\n\n"
        "Mengingatkan nih, uang kas kelas untuk *minggu ini* belum lunas.\n\n"
        "📌 *Info Kas Kelas:*\n"
        "- Jadwal wajib bayar: *Setiap Selasa*\n"
        "- Batas akhir tagihan: *Jumat*\n"
        "- _(Catatan: Hari Kamis kita libur ya!)_\n\n"
        "Yuk segera dilunasi agar kas kelas kita aman! Bisa bayar cash saat di kampus atau transfer via DANA (QRIS).\n\n"
        "Terima kasih! 🙏😊";

    final Uri waUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(pesan)}");

    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }
}