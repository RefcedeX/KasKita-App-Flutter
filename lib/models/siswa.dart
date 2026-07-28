// lib/models/siswa.dart

class Siswa {
  final String id;
  final String nama;
  final String nis;
  final String kelas;
  final String noHp;

  Siswa({
    required this.id,
    required this.nama,
    required this.nis,
    required this.kelas,
    this.noHp = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'nis': nis,
        'kelas': kelas,
        'noHp': noHp,
      };

  factory Siswa.fromJson(Map<String, dynamic> json) => Siswa(
        id: json['id'],
        nama: json['nama'],
        nis: json['nis'],
        kelas: json['kelas'],
        noHp: json['noHp'] ?? '',
      );

  Siswa copyWith({
    String? id,
    String? nama,
    String? nis,
    String? kelas,
    String? noHp,
  }) {
    return Siswa(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nis: nis ?? this.nis,
      kelas: kelas ?? this.kelas,
      noHp: noHp ?? this.noHp,
    );
  }
}
