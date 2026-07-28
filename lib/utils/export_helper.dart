// lib/utils/export_helper.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';

class ExportHelper {
  static Future<void> exportKeExcel(AppProvider provider) async {
    // 1. Inisialisasi File Excel
    var excel = Excel.createExcel();

    // Hapus sheet default bawaan
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ==========================================
    // SHEET 1: REKAP KAS (Summary per bulan)
    // ==========================================
    Sheet sheetRekap = excel['REKAP KAS'];

    // Header Style
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#A6A6A6'),
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Judul Semester 4
    sheetRekap.merge(CellIndex.indexByString("B2"), CellIndex.indexByString("F2"));
    var cellJudul = sheetRekap.cell(CellIndex.indexByString("B2"));
    cellJudul.value = TextCellValue("LAPORAN KAS TIAP BULAN (SEMESTER 4)");
    cellJudul.cellStyle = headerStyle;

    // Header Tabel
    List<String> headersRekap = ["No", "Bulan", "Total", "Pengeluaran", "Sisa"];
    for (int i = 0; i < headersRekap.length; i++) {
      var cell = sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: 2));
      cell.value = TextCellValue(headersRekap[i]);
      cell.cellStyle = headerStyle;
    }

    // Mengambil rekap pemasukan & pengeluaran per bulan
    Map<String, double> pemasukanPerBulan = provider.getPemasukanPerBulan();

    // Karena pengeluaran di app belum dilompokkan per bulan, kita filter manual untuk laporan
    Map<String, double> pengeluaranPerBulan = {};
    for (var p in provider.pengeluarans) {
      String bln = '${p.tanggal.year}-${p.tanggal.month.toString().padLeft(2, '0')}';
      pengeluaranPerBulan[bln] = (pengeluaranPerBulan[bln] ?? 0) + p.jumlah;
    }

    // Kita buat list 6 bulan berjalan (Maret - Agustus 2026 misalnya)
    List<String> listBulan = ["2026-03", "2026-04", "2026-05", "2026-06", "2026-07", "2026-08"];
    List<String> namaBulan = ["MARET", "APRIL", "MEI", "JUNI", "JULI", "AGUSTUS"];

    double grandTotalMasuk = 0;
    double grandTotalKeluar = 0;

    for (int i = 0; i < listBulan.length; i++) {
      String keyBln = listBulan[i];
      double masuk = pemasukanPerBulan[keyBln] ?? 0;
      double keluar = pengeluaranPerBulan[keyBln] ?? 0;
      double sisa = masuk - keluar;

      grandTotalMasuk += masuk;
      grandTotalKeluar += keluar;

      int currentRow = 3 + i;
      sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = IntCellValue(i + 1);
      sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(namaBulan[i]);
      sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = IntCellValue(masuk.toInt());
      sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = IntCellValue(keluar.toInt());
      sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = IntCellValue(sisa.toInt());
    }

    // Baris Total Bawah
    int totalRowIndex = 3 + listBulan.length;
    sheetRekap.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIndex), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIndex));
    var cellTotal = sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIndex));
    cellTotal.value = TextCellValue("TOTAL");
    cellTotal.cellStyle = headerStyle;

    sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex)).value = IntCellValue(grandTotalMasuk.toInt());
    sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex)).value = IntCellValue(grandTotalKeluar.toInt());
    sheetRekap.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex)).value = IntCellValue((grandTotalMasuk - grandTotalKeluar).toInt());

    // ==========================================
    // SHEET 2: DATA KAS (Bulan Berjalan)
    // ==========================================
    final DateTime now = DateTime.now();
    final List<String> bulanIndo = ["JANUARI", "FEBRUARI", "MARET", "APRIL", "MEI", "JUNI", "JULI", "AGUSTUS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DESEMBER"];
    String bulanSekarang = bulanIndo[now.month - 1];

    Sheet sheetKas = excel['DATA KAS ($bulanSekarang)'];

    CellStyle judulBulanStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#5A9E9E'), // Warna Teal ala Google Sheets
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Judul Utama "MEI 2026"
    sheetKas.merge(CellIndex.indexByString("B2"), CellIndex.indexByString("G2"));
    var cellBulan = sheetKas.cell(CellIndex.indexByString("B2"));
    cellBulan.value = TextCellValue("$bulanSekarang ${now.year}");
    cellBulan.cellStyle = judulBulanStyle;

    // Tabel Header: NO | NAMA | BULAN (Minggu 1-4)
    sheetKas.merge(CellIndex.indexByString("B4"), CellIndex.indexByString("B5"));
    var hNo = sheetKas.cell(CellIndex.indexByString("B4"));
    hNo.value = TextCellValue("NO");
    hNo.cellStyle = headerStyle;

    sheetKas.merge(CellIndex.indexByString("C4"), CellIndex.indexByString("C5"));
    var hNama = sheetKas.cell(CellIndex.indexByString("C4"));
    hNama.value = TextCellValue("NAMA");
    hNama.cellStyle = headerStyle;

    sheetKas.merge(CellIndex.indexByString("D4"), CellIndex.indexByString("G4"));
    var hBulan = sheetKas.cell(CellIndex.indexByString("D4"));
    hBulan.value = TextCellValue("BULAN $bulanSekarang");
    hBulan.cellStyle = headerStyle;

    List<String> minggu = ["Minggu 1", "Minggu 2", "Minggu 3", "Minggu 4"];
    for(int i=0; i<4; i++){
      var cW = sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 3+i, rowIndex: 4));
      cW.value = TextCellValue(minggu[i]);
      cW.cellStyle = headerStyle;
    }

    // Warna status bayar
    CellStyle styleYellow = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FFFF00'));
    CellStyle styleGreen = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#00FF00'), horizontalAlign: HorizontalAlign.Center);

    // List Mahasiswa
    int startRow = 5;
    String idBulanIni = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    for (int i = 0; i < provider.siswas.length; i++) {
      var siswa = provider.siswas[i];
      int row = startRow + i;

      sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = IntCellValue(i + 1);
      sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(siswa.nama);

      // Kosongkan minggu 1, 2, 3 (kuning)
      sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).cellStyle = styleYellow;
      sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle = styleYellow;
      sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).cellStyle = styleYellow;

      // Cek apakah dia sudah bayar di bulan ini (Kita taruh di Minggu 4)
      bool sudahBayar = provider.pembayarans.any((p) => p.siswaId == siswa.id && p.bulan == idBulanIni);
      var cStatus = sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
      if (sudahBayar) {
        cStatus.value = IntCellValue(3000); // Sesuai gambar, diisi 3000
        cStatus.cellStyle = styleGreen;
      } else {
        cStatus.cellStyle = styleYellow;
      }
    }

    // Tabel PENGELUARAN di bagian bawah
    int peStartRow = startRow + provider.siswas.length + 3;
    sheetKas.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: peStartRow), CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: peStartRow));
    var hPe = sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: peStartRow));
    hPe.value = TextCellValue("PENGELUARAN");
    hPe.cellStyle = headerStyle;

    List<String> peHeaders = ["NO", "KETERANGAN", "HARI/TANGGAL", "NOMINAL"];
    for(int i=0; i<4; i++){
      var c = sheetKas.cell(CellIndex.indexByColumnRow(columnIndex: 1+i, rowIndex: peStartRow+1));
      c.value = TextCellValue(peHeaders[i]);
      c.cellStyle = headerStyle;
    }

    // ==========================================
    // FINISHING: Simpan & Bagikan
    // ==========================================
    final directory = await getTemporaryDirectory();
    final fileName = 'Rekap_Kas_04SISP007_$bulanSekarang.xlsx';
    final file = File('${directory.path}/$fileName');

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ini laporan buku kas kelas 04SISP007 terbaru ya teman-teman! 📊',
      );
    }
  }
}