// lib/models/pengeluaran.dart

enum KategoriPengeluaran {
  alatTulis,
  konsumsi,
  dekorasi,
  kegiatan,
  lainnya,
}

extension KategoriPengeluaranExtension on KategoriPengeluaran {
  String get label {
    switch (this) {
      case KategoriPengeluaran.alatTulis:
        return 'Alat Tulis';
      case KategoriPengeluaran.konsumsi:
        return 'Konsumsi';
      case KategoriPengeluaran.dekorasi:
        return 'Dekorasi';
      case KategoriPengeluaran.kegiatan:
        return 'Kegiatan';
      case KategoriPengeluaran.lainnya:
        return 'Lainnya';
    }
  }

  String get value => name;
}

class Pengeluaran {
  final String id;
  final String keterangan;
  final double jumlah;
  final DateTime tanggal;
  final KategoriPengeluaran kategori;

  Pengeluaran({
    required this.id,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
    required this.kategori,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'keterangan': keterangan,
        'jumlah': jumlah,
        'tanggal': tanggal.toIso8601String(),
        'kategori': kategori.value,
      };

  factory Pengeluaran.fromJson(Map<String, dynamic> json) => Pengeluaran(
        id: json['id'],
        keterangan: json['keterangan'],
        jumlah: (json['jumlah'] as num).toDouble(),
        tanggal: DateTime.parse(json['tanggal']),
        kategori: KategoriPengeluaran.values.firstWhere(
          (e) => e.value == json['kategori'],
          orElse: () => KategoriPengeluaran.lainnya,
        ),
      );

  Pengeluaran copyWith({
    String? id,
    String? keterangan,
    double? jumlah,
    DateTime? tanggal,
    KategoriPengeluaran? kategori,
  }) {
    return Pengeluaran(
      id: id ?? this.id,
      keterangan: keterangan ?? this.keterangan,
      jumlah: jumlah ?? this.jumlah,
      tanggal: tanggal ?? this.tanggal,
      kategori: kategori ?? this.kategori,
    );
  }
}
