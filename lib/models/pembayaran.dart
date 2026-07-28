// lib/models/pembayaran.dart

class Pembayaran {
  final String id;
  final String siswaId;
  final String siswaName;
  final double jumlah;
  final DateTime tanggal;
  final String keterangan;
  final String bulan; // Format: YYYY-MM

  Pembayaran({
    required this.id,
    required this.siswaId,
    required this.siswaName,
    required this.jumlah,
    required this.tanggal,
    required this.keterangan,
    required this.bulan,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'siswaId': siswaId,
        'siswaName': siswaName,
        'jumlah': jumlah,
        'tanggal': tanggal.toIso8601String(),
        'keterangan': keterangan,
        'bulan': bulan,
      };

  factory Pembayaran.fromJson(Map<String, dynamic> json) => Pembayaran(
        id: json['id'],
        siswaId: json['siswaId'],
        siswaName: json['siswaName'],
        jumlah: (json['jumlah'] as num).toDouble(),
        tanggal: DateTime.parse(json['tanggal']),
        keterangan: json['keterangan'],
        bulan: json['bulan'],
      );

  Pembayaran copyWith({
    String? id,
    String? siswaId,
    String? siswaName,
    double? jumlah,
    DateTime? tanggal,
    String? keterangan,
    String? bulan,
  }) {
    return Pembayaran(
      id: id ?? this.id,
      siswaId: siswaId ?? this.siswaId,
      siswaName: siswaName ?? this.siswaName,
      jumlah: jumlah ?? this.jumlah,
      tanggal: tanggal ?? this.tanggal,
      keterangan: keterangan ?? this.keterangan,
      bulan: bulan ?? this.bulan,
    );
  }
}
