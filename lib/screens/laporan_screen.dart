// lib/screens/laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/export_helper.dart'; // Import helper export yang baru
import '../providers/app_provider.dart';
import '../utils/app_utils.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // KUNCI PERBAIKAN: Consumer diletakkan di paling luar membungkus Scaffold
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: const Text('Laporan Keuangan'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf), // Ikon untuk Export
                onPressed: () async {
                  // Menampilkan indikator loading agar terlihat pro
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menyiapkan file Excel...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // Memanggil mesin pencetak dengan variabel provider yang sekarang sudah dikenali
                  await ExportHelper.exportKeExcel(provider);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRingkasanSection(provider),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  'Pembayaran per Siswa',
                ),
                const SizedBox(height: 10),
                _buildPembayaranPerSiswa(
                  provider,
                  context,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  'Pengeluaran per Kategori',
                ),
                const SizedBox(height: 10),
                _buildPengeluaranKategori(
                  provider,
                  context,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  'Riwayat Pembayaran Bulan Ini',
                ),
                const SizedBox(height: 10),
                _buildRiwayatPembayaran(
                  provider,
                  context,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  'Riwayat Pengeluaran',
                ),
                const SizedBox(height: 10),
                _buildRiwayatPengeluaran(
                  provider,
                  context,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
      BuildContext context,
      String title,
      ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }

  Widget _buildRingkasanSection(
      AppProvider provider,
      ) {
    final saldo = provider.saldoKas;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: saldo >= 0
                  ? [
                AppTheme.primary,
                AppTheme.primaryDark,
              ]
                  : [
                AppTheme.danger,
                Colors.red.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (saldo >= 0 ? AppTheme.primary : AppTheme.danger)
                    .withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Kas Kelas',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Formatter.currency(saldo),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildMiniCard(
              icon: Icons.arrow_downward_rounded,
              label: 'Pemasukan',
              value: Formatter.currency(
                provider.totalPemasukan,
              ),
              color: AppTheme.success,
              bgColor: const Color(0xFFE8F5E9),
            ),
            const SizedBox(width: 12),
            _buildMiniCard(
              icon: Icons.arrow_upward_rounded,
              label: 'Pengeluaran',
              value: Formatter.currency(
                provider.totalPengeluaran,
              ),
              color: AppTheme.danger,
              bgColor: const Color(0xFFFFEBEE),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildPembayaranPerSiswa(
      AppProvider provider,
      BuildContext context,
      ) {
    if (provider.siswas.isEmpty) {
      return _emptyCard(
        'Belum ada data siswa',
        context,
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nama',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...provider.siswas.map((siswa) {
            final totalBayar = provider.pembayarans
                .where(
                  (p) => p.siswaId == siswa.id,
            )
                .fold(
              0.0,
                  (sum, item) => sum + item.jumlah,
            );

            final sudahBayar = provider.sudahBayarBulanIni(
              siswa.id,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          siswa.nama,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatter.currency(
                            totalBayar,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Icon(
                          sudahBayar ? Icons.check_circle : Icons.cancel,
                          size: 20,
                          color: sudahBayar
                              ? AppTheme.success
                              : AppTheme.danger.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPengeluaranKategori(
      AppProvider provider,
      BuildContext context,
      ) {
    final byKategori = provider.getPengeluaranByKategori();

    if (byKategori.isEmpty) {
      return _emptyCard(
        'Belum ada pengeluaran',
        context,
      );
    }

    final total = byKategori.values.fold(
      0.0,
          (a, b) => a + b,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: byKategori.entries.map(
                (entry) {
              final percent = total > 0 ? entry.value / total : 0.0;

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Formatter.currency(
                            entry.value,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildRiwayatPembayaran(
      AppProvider provider,
      BuildContext context,
      ) {
    final now = DateTime.now();

    final bulanIni = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final list = provider.pembayarans
        .where(
          (p) => p.bulan == bulanIni,
    )
        .toList()
      ..sort(
            (a, b) => b.tanggal.compareTo(a.tanggal),
      );

    if (list.isEmpty) {
      return _emptyCard(
        'Belum ada pembayaran bulan ini',
        context,
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 56,
        ),
        itemBuilder: (_, index) {
          final p = list[index];

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.add,
                color: AppTheme.success,
                size: 16,
              ),
            ),
            title: Text(
              p.siswaName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              Formatter.date(p.tanggal),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              Formatter.currency(p.jumlah),
              style: const TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiwayatPengeluaran(
      AppProvider provider,
      BuildContext context,
      ) {
    final list = provider.pengeluarans.toList()
      ..sort(
            (a, b) => b.tanggal.compareTo(a.tanggal),
      );

    if (list.isEmpty) {
      return _emptyCard(
        'Belum ada pengeluaran',
        context,
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 56,
        ),
        itemBuilder: (_, index) {
          final p = list[index];

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(
                Icons.remove,
                color: AppTheme.danger,
                size: 16,
              ),
            ),
            title: Text(
              p.keterangan,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${p.kategori.name} • ${Formatter.date(p.tanggal)}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '-${Formatter.currency(p.jumlah)}',
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyCard(
      String message,
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}