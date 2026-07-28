// lib/screens/pengeluaran_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pengeluaran.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart'; // Sesuaikan path jika berbeda
import '../utils/formatter.dart'; // Sesuaikan path jika berbeda
import '../utils/ocr_helper.dart'; // IMPORT MESIN AI SCANNER STRUK

class PengeluaranScreen extends StatelessWidget {
  const PengeluaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final list = provider.pengeluarans.toList()
            ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

          if (list.isEmpty) return _buildEmpty(context);

          return Column(
            children: [
              _buildTotalBar(context, provider.totalPengeluaran),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _buildCard(ctx, list[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.danger,
          foregroundColor: Colors.white,
          onPressed: () => _showFormDialog(context),
          tooltip: 'Tambah Pengeluaran',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTotalBar(BuildContext context, double total) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final txtSecondary = Theme.of(context).textTheme.bodySmall?.color ?? AppTheme.textSecondary;

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pengeluaran',
            style: TextStyle(fontSize: 12, color: txtSecondary),
          ),
          Text(
            Formatter.currency(total),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Pengeluaran p) {
    final categoryColors = {
      KategoriPengeluaran.alatTulis: AppTheme.primary,
      KategoriPengeluaran.konsumsi: Colors.orange,
      KategoriPengeluaran.dekorasi: Colors.pink,
      KategoriPengeluaran.kegiatan: Colors.purple,
      KategoriPengeluaran.lainnya: Colors.grey,
    };

    final color = categoryColors[p.kategori] ?? Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_getCategoryIcon(p.kategori), color: color, size: 20),
        ),
        title: Text(p.keterangan,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                p.kategori.label,
                style: TextStyle(fontSize: 11, color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(Formatter.date(p.tanggal),
                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color ?? AppTheme.textSecondary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${Formatter.currency(p.jumlah)}',
              style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color, size: 18),
              color: Theme.of(context).colorScheme.surface,
              onSelected: (val) {
                if (val == 'edit') _showFormDialog(context, pengeluaran: p);
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

  IconData _getCategoryIcon(KategoriPengeluaran k) {
    switch (k) {
      case KategoriPengeluaran.alatTulis: return Icons.edit;
      case KategoriPengeluaran.konsumsi: return Icons.restaurant;
      case KategoriPengeluaran.dekorasi: return Icons.celebration;
      case KategoriPengeluaran.kegiatan: return Icons.event;
      case KategoriPengeluaran.lainnya: return Icons.category;
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Belum ada pengeluaran', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16)),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {Pengeluaran? pengeluaran}) {
    final isEdit = pengeluaran != null;

    final keteranganCtrl = TextEditingController(text: pengeluaran?.keterangan ?? '');
    final jumlahCtrl = TextEditingController(text: pengeluaran != null ? pengeluaran.jumlah.toStringAsFixed(0) : '');

    KategoriPengeluaran selectedKategori = pengeluaran?.kategori ?? KategoriPengeluaran.lainnya;

    DateTime selectedDate = pengeluaran?.tanggal ?? DateTime.now();
    // Gunakan controller untuk tanggal agar tidak error
    final tanggalCtrl = TextEditingController(text: Formatter.date(selectedDate));

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateBottom) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: keteranganCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
                    prefixIcon: Icon(Icons.description, size: 20),
                  ),
                  validator: (v) => v!.isEmpty ? 'Keterangan tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                // ─── KOLOM NOMINAL DENGAN TOMBOL KAMERA AI OCR ───
                TextFormField(
                  controller: jumlahCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    // Tombol Ajaib AI
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.document_scanner, color: AppTheme.danger),
                      tooltip: 'Scan Struk Otomatis',
                      onPressed: () async {
                        // 1. Munculkan Notifikasi Loading
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Membuka Kamera Pemindai...'), duration: Duration(seconds: 1)),
                        );

                        // 2. Panggil Mesin AI Google
                        String? hasilScan = await OcrHelper.scanStruk();

                        if (hasilScan != null) {
                          // 3. Jika berhasil membaca angka, otomatis isi ke kotak teks
                          setStateBottom(() {
                            jumlahCtrl.text = hasilScan;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('✅ Nominal struk berhasil dibaca AI!'), backgroundColor: AppTheme.success),
                            );
                          }
                        } else {
                          // 4. Jika struk buram / tidak ada angka
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Gagal menemukan total belanja di foto.'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<KategoriPengeluaran>(
                  value: selectedKategori,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category, size: 20),
                  ),
                  items: KategoriPengeluaran.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                  onChanged: (v) => setStateBottom(() => selectedKategori = v!),
                ),
                const SizedBox(height: 12),

                // ─── KOTAK TANGGAL YANG SUDAH DIPERBAIKI BUGNYA ───
                TextFormField(
                  controller: tanggalCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setStateBottom(() {
                        selectedDate = picked;
                        tanggalCtrl.text = Formatter.date(picked); // Teks langsung berubah
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final prov = context.read<AppProvider>();
                      final newP = Pengeluaran(
                        id: pengeluaran?.id ?? '',
                        keterangan: keteranganCtrl.text.trim(),
                        jumlah: double.parse(jumlahCtrl.text),
                        tanggal: selectedDate,
                        kategori: selectedKategori,
                      );
                      if (isEdit) {
                        await prov.updatePengeluaran(newP);
                      } else {
                        await prov.addPengeluaran(newP);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Pengeluaran'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Pengeluaran p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Hapus Pengeluaran'),
        content: Text('Hapus pengeluaran "${p.keterangan}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deletePengeluaran(p.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}