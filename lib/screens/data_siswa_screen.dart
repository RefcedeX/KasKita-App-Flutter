// lib/screens/data_siswa_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/siswa.dart';
import '../providers/app_provider.dart';
import '../utils/app_utils.dart';

class DataSiswaScreen extends StatefulWidget {
  const DataSiswaScreen({super.key});

  @override
  State<DataSiswaScreen> createState() => _DataSiswaScreenState();
}

class _DataSiswaScreenState extends State<DataSiswaScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siswa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari siswa...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final filtered = provider.siswas
              .where((s) =>
                  s.nama.toLowerCase().contains(_search.toLowerCase()) ||
                  s.nis.contains(_search))
              .toList();

          if (filtered.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) =>
                _buildSiswaCard(ctx, filtered[i], provider),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0), // Agar tidak terhalang bar
        child: FloatingActionButton(
          onPressed: () => _showFormDialog(context),
          tooltip: 'Tambah Data Siswa',
          child: const Icon(Icons.person_add), // Menggunakan ikon tambah siswa
        ),
      ),
    );
  }

  Widget _buildSiswaCard(
      BuildContext context, Siswa siswa, AppProvider provider) {
    final sudahBayar = provider.sudahBayarBulanIni(siswa.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryLight,
          child: Text(
            siswa.nama[0].toUpperCase(),
            style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        title: Text(siswa.nama,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('NIS: ${siswa.nis}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            Text('Kelas: ${siswa.kelas}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sudahBayar
                    // ignore: deprecated_member_use
                    ? AppTheme.success.withOpacity(0.15)
                    // ignore: deprecated_member_use
                    : AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sudahBayar ? 'Lunas' : 'Menunggak',
                style: TextStyle(
                  color: sudahBayar ? AppTheme.success : AppTheme.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onSelected: (val) {
                if (val == 'edit') _showFormDialog(context, siswa: siswa);
                if (val == 'delete') _confirmDelete(context, siswa);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red))),
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
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada data siswa',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap tombol + untuk menambah siswa',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {Siswa? siswa}) {
    final isEdit = siswa != null;
    final namaCtrl = TextEditingController(text: siswa?.nama ?? '');
    final nisCtrl = TextEditingController(text: siswa?.nis ?? '');
    final kelasCtrl = TextEditingController(text: siswa?.kelas ?? '');
    final hpCtrl = TextEditingController(text: siswa?.noHp ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Nama Lengkap', namaCtrl, Icons.person,
                  validator: (v) =>
                      v!.isEmpty ? 'Nama tidak boleh kosong' : null),
              const SizedBox(height: 12),
              _buildField('NIS', nisCtrl, Icons.badge,
                  validator: (v) =>
                      v!.isEmpty ? 'NIS tidak boleh kosong' : null),
              const SizedBox(height: 12),
              _buildField('Kelas', kelasCtrl, Icons.class_,
                  validator: (v) =>
                      v!.isEmpty ? 'Kelas tidak boleh kosong' : null),
              const SizedBox(height: 12),
              _buildField('No. HP (opsional)', hpCtrl, Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final provider = context.read<AppProvider>();
                    final newSiswa = Siswa(
                      id: siswa?.id ?? '',
                      nama: namaCtrl.text.trim(),
                      nis: nisCtrl.text.trim(),
                      kelas: kelasCtrl.text.trim(),
                      noHp: hpCtrl.text.trim(),
                    );
                    if (isEdit) {
                      await provider.updateSiswa(newSiswa);
                    } else {
                      await provider.addSiswa(newSiswa);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Siswa'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {String? Function(String?)? validator,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Siswa siswa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text(
            'Hapus ${siswa.nama}? Seluruh data pembayaran siswa ini juga akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteSiswa(siswa.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
