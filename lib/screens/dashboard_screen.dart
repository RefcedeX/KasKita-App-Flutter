// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/siswa.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatter.dart';
import '../utils/whatsapp_helper.dart'; // Import helper WhatsApp
import 'settings_screen.dart'; // Import halaman pengaturan

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, provider),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSearchBar(context),
                    const SizedBox(height: 16),
                    _buildSaldoCard(provider),
                    const SizedBox(height: 16),
                    _buildStatsRow(provider),
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, 'Aktivitas Terbaru'),
                    const SizedBox(height: 8),
                    _buildRecentActivity(provider),
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, 'Status Pembayaran Bulan Ini'),
                    const SizedBox(height: 8),
                    _buildPaymentStatus(provider),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider) {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      centerTitle: false,
      backgroundColor: AppTheme.primary,
      title: const Text(
        'Dashboard',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        centerTitle: false,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryDark, AppTheme.primary],
            ),
          ),
          child: const Stack(
            children: [
              Positioned(
                right: 16,
                bottom: 10,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
          onPressed: () => provider.toggleTheme(),
        ),
        // ─── TOMBOL FITUR BARU: PANEL PENAGIHAN MINGGUAN ───
        IconButton(
          icon: const Icon(Icons.campaign, color: Colors.white),
          tooltip: 'Tagih Kas Mingguan',
          onPressed: () => _showTagihanMingguan(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ─── FUNGSI PANEL PENAGIHAN OTOMATIS (BARU) ───
  void _showTagihanMingguan(BuildContext context) {
    final provider = context.read<AppProvider>();

    // 1. Algoritma mencari waktu dalam minggu ini (Senin - Minggu)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Senin
    final startOfThisWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfThisWeek = startOfThisWeek.add(const Duration(days: 6, hours: 23, minutes: 59)); // Minggu

    // 2. Filter siswa yang belum bayar di minggu ini
    List<Siswa> siswaBelumBayar = [];
    for (var s in provider.siswas) {
      bool sudahBayarMingguIni = provider.pembayarans.any((p) {
        return p.siswaId == s.id &&
            p.tanggal.isAfter(startOfThisWeek.subtract(const Duration(seconds: 1))) &&
            p.tanggal.isBefore(endOfThisWeek.add(const Duration(seconds: 1)));
      });

      if (!sudahBayarMingguIni) {
        siswaBelumBayar.add(s);
      }
    }

    // 3. Tampilkan UI BottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, color: AppTheme.danger, size: 28),
                SizedBox(width: 8),
                Text('Tagihan Kas Minggu Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              siswaBelumBayar.isEmpty
                  ? 'Luar biasa! Semua siswa sudah lunas minggu ini 🎉'
                  : 'Ada ${siswaBelumBayar.length} siswa yang belum bayar kas minggu ini',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: siswaBelumBayar.isEmpty
                  ? Center(child: Icon(Icons.check_circle_outline, size: 80, color: AppTheme.success.withValues(alpha: 0.5)))
                  : ListView.builder(
                itemCount: siswaBelumBayar.length,
                itemBuilder: (context, index) {
                  final siswa = siswaBelumBayar[index];
                  // Mengecek apakah nomor HP valid
                  final isNoHpValid = siswa.noHp.isNotEmpty && siswa.noHp.length >= 10;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppTheme.danger),
                    ),
                    title: Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isNoHpValid ? siswa.noHp : 'Nomor HP tidak valid', style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNoHpValid ? const Color(0xFF25D366) : Colors.grey, // Warna hijau WA
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('WA'),
                      onPressed: isNoHpValid ? () async {
                        try {
                          // Panggil Helper WhatsApp (Pastikan method kirimTagihanMingguan ada di whatsapp_helper.dart)
                          await WhatsAppHelper.kirimTagihanMingguan(siswa.nama, siswa.noHp);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      } : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      onChanged: (v) {
        setState(() {
          _searchQuery = v.toLowerCase();
        });
      },
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'Cari aktivitas atau nama siswa...',
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildSaldoCard(AppProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text('Saldo Kas Kelas', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatter.currency(provider.saldoKas),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('↑ Pemasukan', Formatter.currency(provider.totalPemasukan), Colors.greenAccent),
              const SizedBox(width: 24),
              _buildMiniStat('↓ Pengeluaran', Formatter.currency(provider.totalPengeluaran), Colors.redAccent[100]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsRow(AppProvider provider) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.people_alt_outlined,
          label: 'Total Siswa',
          value: '${provider.siswas.length}',
          color: AppTheme.primary,
          bgColor: AppTheme.primaryLight,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.check_circle_outline,
          label: 'Sudah Bayar',
          value: '${provider.jumlahSiswaSudahBayar}',
          color: AppTheme.success,
          bgColor: const Color(0xFFE8F5E9),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.pending_outlined,
          label: 'Belum Bayar',
          value: '${provider.jumlahSiswaBelumBayar}',
          color: AppTheme.danger,
          bgColor: const Color(0xFFFFEBEE),
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleMedium?.color ?? AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildRecentActivity(AppProvider provider) {
    final allActivity = [
      ...provider.pembayarans.map((p) => {
        'type': 'pembayaran',
        'tanggal': p.tanggal,
        'label': 'Pembayaran: ${p.siswaName}',
        'jumlah': p.jumlah,
        'icon': Icons.arrow_downward,
        'color': AppTheme.success,
      }),
      ...provider.pengeluarans.map((p) => {
        'type': 'pengeluaran',
        'tanggal': p.tanggal,
        'label': 'Pengeluaran: ${p.keterangan}',
        'jumlah': p.jumlah,
        'icon': Icons.arrow_upward,
        'color': AppTheme.danger,
      }),
    ];

    allActivity.sort((a, b) => (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime));

    final filteredActivity = allActivity.where((item) {
      final label = (item['label'] as String).toLowerCase();
      return label.contains(_searchQuery);
    }).toList();

    final recent = filteredActivity.take(5).toList();

    if (recent.isEmpty) {
      return _buildEmptyState('Tidak ada aktivitas yang cocok');
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final item = recent[index];
          final color = item['color'] as Color;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 20,
              child: Icon(item['icon'] as IconData, color: color, size: 18),
            ),
            title: Text(item['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text(
              Formatter.date(item['tanggal'] as DateTime),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color ?? AppTheme.textSecondary),
            ),
            trailing: Text(
              (item['type'] == 'pembayaran' ? '+' : '-') + Formatter.currency(item['jumlah'] as double),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentStatus(AppProvider provider) {
    if (provider.siswas.isEmpty) {
      return _buildEmptyState('Belum ada data siswa');
    }

    final filteredSiswas = provider.siswas.where((s) {
      return s.nama.toLowerCase().contains(_searchQuery) || s.nis.contains(_searchQuery);
    }).toList();

    if (filteredSiswas.isEmpty) {
      return _buildEmptyState('Nama atau NIM tidak ditemukan');
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredSiswas.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final siswa = filteredSiswas[index];
          final sudahBayar = provider.sudahBayarBulanIni(siswa.id);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                siswa.nama[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(siswa.nama, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text(siswa.nis, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color ?? AppTheme.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sudahBayar ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sudahBayar ? 'Lunas' : 'Belum',
                    style: TextStyle(
                      color: sudahBayar ? AppTheme.success : AppTheme.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // --- TOMBOL WHATSAPP SINGLE (Hanya Muncul Jika Belum Bayar) ---
                if (!sudahBayar) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      try {
                        // Memanggil fungsi WA (Fungsi bulanan reguler)
                        await WhatsAppHelper.kirimTagihan(siswa.nama, siswa.noHp);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppTheme.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.2), // Warna hijau WA
                      child: const Icon(Icons.send, size: 14, color: Color(0xFF25D366)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(child: Text(message, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
    );
  }
}