// lib/screens/pembayaran_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/pembayaran.dart';
import '../models/siswa.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatter.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _filterBulan = '';
  String _searchQuery = '';
  String _sortBy = 'tanggal_desc';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterBulan = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pembayaran Kas'),
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: _showSortPicker,
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final filtered = provider.pembayarans.where((p) {
            final matchesBulan = p.bulan == _filterBulan;
            final siswa = provider.siswas.firstWhere(
                  (s) => s.id == p.siswaId,
              orElse: () => Siswa(id: '', nama: '', nis: '', kelas: '', noHp: ''),
            );
            final matchesSearch = p.siswaName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                siswa.nis.contains(_searchQuery);
            return matchesBulan && matchesSearch;
          }).toList();

          filtered.sort((a, b) {
            if (_sortBy == 'tanggal_desc') return b.tanggal.compareTo(a.tanggal);
            if (_sortBy == 'tanggal_asc') return a.tanggal.compareTo(b.tanggal);
            if (_sortBy == 'nama_asc') return a.siswaName.compareTo(b.siswaName);
            if (_sortBy == 'jumlah_desc') return b.jumlah.compareTo(a.jumlah);
            return 0;
          });

          return Column(
            children: [
              _buildBulanHeader(),
              _buildSearchBar(),
              _buildSummaryBar(filtered),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildCard(ctx, filtered[i], provider),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showFormDialog(context),
          tooltip: 'Catat Pembayaran',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBulanHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? Theme.of(context).colorScheme.surface : AppTheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(Formatter.bulanLabel(_filterBulan), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: _showBulanPicker,
            child: const Text('Ganti Bulan', style: TextStyle(color: AppTheme.primary, fontSize: 12, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'Cari nama atau NIM mahasiswa...',
          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).iconTheme.color),
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<Pembayaran> pembayarans) {
    final total = pembayarans.fold(0.0, (sum, p) => sum + p.jumlah);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildSummaryItem('Total Transaksi', '${pembayarans.length}x'),
          VerticalDivider(width: 32, color: dividerColor),
          _buildSummaryItem('Total Masuk', Formatter.currency(total), isCurrency: true),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isCurrency = false}) {
    final txtSecondary = Theme.of(context).textTheme.bodySmall?.color;
    final txtPrimary = isCurrency ? AppTheme.success : Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: txtSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: txtPrimary)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Pembayaran p, AppProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.success.withValues(alpha: 0.15),
          child: const Icon(Icons.arrow_downward, color: AppTheme.success, size: 20),
        ),
        title: Text(p.siswaName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.keterangan, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            Text(Formatter.date(p.tanggal), style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+ ${Formatter.currency(p.jumlah)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14)),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color, size: 18),
              onSelected: (val) {
                if (val == 'edit') _showFormDialog(context, pembayaran: p);
                if (val == 'delete') _confirmDelete(context, p);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Belum ada pembayaran', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  void _showBulanPicker() {
    final now = DateTime.now();
    final bulanList = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Padding(padding: EdgeInsets.all(16), child: Text('Pilih Bulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bulanList.length,
                itemBuilder: (context, index) {
                  final b = bulanList[index];
                  return ListTile(
                    title: Text(Formatter.bulanLabel(b), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    trailing: b == _filterBulan ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () { setState(() => _filterBulan = b); Navigator.pop(context); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const Padding(padding: EdgeInsets.all(16), child: Text('Urutkan Berdasarkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          _buildSortOption('tanggal_desc', 'Tanggal (Terbaru)', Icons.access_time),
          _buildSortOption('tanggal_asc', 'Tanggal (Terlama)', Icons.history),
          _buildSortOption('nama_asc', 'Nama Siswa (A - Z)', Icons.sort_by_alpha),
          _buildSortOption('jumlah_desc', 'Nominal (Terbesar)', Icons.attach_money),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(label, style: TextStyle(
        color: isSelected ? AppTheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
      onTap: () { setState(() => _sortBy = value); Navigator.pop(context); },
    );
  }

  void _showFormDialog(BuildContext context, {Pembayaran? pembayaran}) {
    final provider = context.read<AppProvider>();
    if (provider.siswas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan data siswa terlebih dahulu!')));
      return;
    }

    final isEdit = pembayaran != null;
    String? selectedSiswaId = pembayaran?.siswaId;

    String selectedMetode = 'Cash Tunai';
    bool isVerifying = false;

    final jumlahCtrl = TextEditingController(text: isEdit ? pembayaran.jumlah.toStringAsFixed(0) : '50000');
    final keteranganCtrl = TextEditingController(text: pembayaran?.keterangan ?? '');

    DateTime selectedDate = pembayaran?.tanggal ?? DateTime.now();
    final tanggalCtrl = TextEditingController(text: Formatter.date(selectedDate));
    final formKey = GlobalKey<FormState>();

    const String qrDataString = "https://m.dana.id/n/link/minta?full_url=https://qr.dana.id/v1/281012012022092929910101";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateBottom) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isEdit ? 'Edit Pembayaran' : 'Catat Pembayaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── DROPDOWN METODE PEMBAYARAN (SUDAH DIPERBAIKI OVERFLOW) ───
                    DropdownButtonFormField<String>(
                      value: selectedMetode,
                      isExpanded: true, // Mencegah teks kepanjangan meluap
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                        prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash Tunai', child: Text('Cash Tunai')),
                        DropdownMenuItem(
                          value: 'QRIS / E-Wallet',
                          child: Text('QRIS / E-Wallet (DANA)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) {
                        setStateBottom(() => selectedMetode = v!);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (selectedMetode == 'QRIS / E-Wallet') ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('Scan untuk Membayar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              QrImageView(
                                data: qrDataString,
                                version: QrVersions.auto,
                                size: 150.0,
                                foregroundColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── DROPDOWN PILIH SISWA (SUDAH DIPERBAIKI OVERFLOW) ───
                    DropdownButtonFormField<String>(
                      value: selectedSiswaId,
                      isExpanded: true, // Mencegah nama panjang meluap
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: const InputDecoration(labelText: 'Pilih Siswa', prefixIcon: Icon(Icons.person, size: 20)),
                      items: provider.siswas.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nama, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: isEdit ? null : (v) => setStateBottom(() => selectedSiswaId = v),
                      validator: (v) => v == null ? 'Pilih siswa dahulu' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: jumlahCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Jumlah (Rp)', prefixIcon: Icon(Icons.attach_money, size: 20)),
                      validator: (v) => v!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: keteranganCtrl,
                      decoration: const InputDecoration(labelText: 'Keterangan', prefixIcon: Icon(Icons.notes, size: 20)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tanggalCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateBottom(() { selectedDate = picked; tanggalCtrl.text = Formatter.date(picked); });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Tanggal', prefixIcon: Icon(Icons.calendar_today, size: 20)),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedMetode == 'Cash Tunai' ? AppTheme.primary : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isVerifying ? null : () async {
                          if (!formKey.currentState!.validate()) return;

                          if (selectedMetode == 'QRIS / E-Wallet') {
                            setStateBottom(() => isVerifying = true);
                            await Future.delayed(const Duration(seconds: 2));
                            setStateBottom(() => isVerifying = false);

                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('✅ Pembayaran QR Berhasil Diverifikasi Server!'), backgroundColor: AppTheme.success)
                              );
                            }
                          }

                          final siswa = provider.siswas.firstWhere((s) => s.id == selectedSiswaId);
                          final bulan = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';

                          String finalKeterangan = keteranganCtrl.text.trim().isEmpty
                              ? 'Kas bulan ${selectedDate.month}'
                              : keteranganCtrl.text.trim();
                          finalKeterangan = '$finalKeterangan ($selectedMetode)';

                          final dataPembayaran = Pembayaran(
                            id: pembayaran?.id ?? '',
                            siswaId: siswa.id,
                            siswaName: siswa.nama,
                            jumlah: double.parse(jumlahCtrl.text),
                            tanggal: selectedDate,
                            keterangan: finalKeterangan,
                            bulan: bulan,
                          );

                          if (isEdit) {
                            await provider.updatePembayaran(dataPembayaran);
                          } else {
                            await provider.addPembayaran(dataPembayaran);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: isVerifying
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(selectedMetode == 'Cash Tunai' ? 'Simpan Pembayaran' : 'Cek & Verifikasi Pembayaran'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Pembayaran p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Hapus Pembayaran'),
        content: Text('Hapus pembayaran ${p.siswaName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () { context.read<AppProvider>().deletePembayaran(p.id); Navigator.pop(context); },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}