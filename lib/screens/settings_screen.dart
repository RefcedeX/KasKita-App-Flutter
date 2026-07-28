// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart'; // Pastikan import ini sesuai dengan struktur folder Anda
import '../utils/app_utils.dart';
import '../utils/notification_helper.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'ID'; // Default: Bahasa Indonesia
  bool _isLoadingCloud = false; // State untuk animasi loading

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  // ─── FUNGSI MEMUAT & MENYIMPAN BAHASA ───
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'ID';
    });
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', newLang);
      setState(() {
        _selectedLanguage = newLang;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newLang == 'ID' ? '🇮🇩 Bahasa diubah ke Indonesia' : '🇬🇧 Language changed to English'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── FUNGSI CLOUD BACKUP & RESTORE ───
  Future<void> _handleCloudAction(bool isBackup) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Tampilkan animasi loading
    setState(() => _isLoadingCloud = true);

    try {
      if (isBackup) {
        await provider.pushDataKeCloud();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedLanguage == 'ID' ? '☁️ Berhasil Menyimpan Data ke Cloud!' : '☁️ Successfully Backed Up Data to Cloud!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await provider.loadDataDariCloud();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedLanguage == 'ID' ? '☁️ Database Kas berhasil dipulihkan!' : '☁️ Cash Database successfully restored!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      // Matikan animasi loading
      setState(() => _isLoadingCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Teks Multi-Bahasa
    final titleText = _selectedLanguage == 'ID' ? 'Pengaturan & Utilitas' : 'Settings & Utilities';
    final sectionLangText = _selectedLanguage == 'ID' ? 'Preferensi Tampilan' : 'Display Preferences';
    final sectionNotifText = _selectedLanguage == 'ID' ? 'Sistem Notifikasi' : 'Notification System';
    final sectionDataText = _selectedLanguage == 'ID' ? 'Manajemen Data' : 'Data Management';
    final sectionOtherText = _selectedLanguage == 'ID' ? 'Lainnya' : 'Others';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Menggunakan Stack agar bisa menumpuk animasi loading di atas ListView
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── BAGIAN 1: PREFERENSI BAHASA (BARU) ───
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(sectionLangText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F7FA),
                    child: Icon(Icons.language, color: Color(0xFF00ACC1)),
                  ),
                  title: Text(_selectedLanguage == 'ID' ? 'Bahasa Aplikasi' : 'App Language', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(_selectedLanguage == 'ID' ? 'Pilih bahasa antarmuka' : 'Select interface language', style: const TextStyle(fontSize: 12)),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ID', child: Text('🇮🇩 Indonesia')),
                      DropdownMenuItem(value: 'EN', child: Text('🇬🇧 English')),
                    ],
                    onChanged: _changeLanguage,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── BAGIAN 2: PENGATURAN NOTIFIKASI ───
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(sectionNotifText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _notificationsEnabled ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    child: Icon(
                      _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: _notificationsEnabled ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                  title: Text(_selectedLanguage == 'ID' ? 'Notifikasi Aplikasi' : 'App Notifications', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      _notificationsEnabled
                          ? (_selectedLanguage == 'ID' ? 'Status: Aktif' : 'Status: Active')
                          : (_selectedLanguage == 'ID' ? 'Status: Nonaktif' : 'Status: Inactive'),
                      style: const TextStyle(fontSize: 12)
                  ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? (_selectedLanguage == 'ID' ? 'Notifikasi sistem diaktifkan!' : 'System notifications enabled!')
                              : (_selectedLanguage == 'ID' ? 'Notifikasi sistem dibisukan!' : 'System notifications muted!')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── BAGIAN 3: DATA & CLOUD (DIPERBARUI) ───
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(sectionDataText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8EAF6),
                        child: Icon(Icons.cloud_upload, color: Color(0xFF3F51B5)),
                      ),
                      title: Text(_selectedLanguage == 'ID' ? 'Simpan Data (Backup)' : 'Backup Data', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(_selectedLanguage == 'ID' ? 'Amankan data kas ke server awan' : 'Secure cash data to the cloud', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _handleCloudAction(true), // PANGGIL BACKUP
                    ),
                    const Divider(height: 1, indent: 70),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.cloud_download, color: Color(0xFF1E88E5)),
                      ),
                      title: Text(_selectedLanguage == 'ID' ? 'Pulihkan Data (Restore)' : 'Restore Data', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(_selectedLanguage == 'ID' ? 'Tarik data lama dari server awan' : 'Retrieve old data from the cloud', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _handleCloudAction(false), // PANGGIL RESTORE
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── BAGIAN 4: DIAGNOSTIK & INFO ───
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(sectionOtherText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF5F5F5),
                        child: Icon(Icons.developer_mode, color: Colors.grey),
                      ),
                      title: Text(_selectedLanguage == 'ID' ? 'Sistem Diagnostik Audio' : 'Audio Diagnostic System', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(_selectedLanguage == 'ID' ? 'Uji coba fungsi suara kustom' : 'Test custom sound functions', style: const TextStyle(fontSize: 12)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!_notificationsEnabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_selectedLanguage == 'ID' ? 'Gagal! Aktifkan switch notifikasi terlebih dahulu.' : 'Failed! Enable notification switch first.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                            return;
                          }

                          await NotificationHelper.tampilkanNotifSuaraKustom('fa_kas');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_selectedLanguage == 'ID' ? 'Pemicu Test Notifikasi Suara Berhasil...' : 'Voice Notification Test Trigger Successful...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(_selectedLanguage == 'ID' ? 'Tes Suara' : 'Test Audio'),
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.info_outline, color: Colors.orange),
                      ),
                      title: Text(_selectedLanguage == 'ID' ? 'Tentang Aplikasi' : 'About Application', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(_selectedLanguage == 'ID' ? 'Informasi sistem dan versi KasKita' : 'System info and KasKita version', style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(_selectedLanguage == 'ID' ? 'Tentang KasKita' : 'About KasKita'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedLanguage == 'ID' ? 'Nama Sistem: KasKita App' : 'System Name: KasKita App', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Text('Kode Kelas: 04SISP007'),
                                const SizedBox(height: 8),
                                Text(_selectedLanguage == 'ID'
                                    ? 'Sistem informasi manajemen kas kelas terintegrasi dengan Firebase Cloud & Push Notification.'
                                    : 'Class cash management information system integrated with Firebase Cloud & Push Notifications.'),
                                const SizedBox(height: 12),
                                const Text('Versi Aplikasi: v1.0.0 (Release Edition)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(_selectedLanguage == 'ID' ? 'Tutup' : 'Close', style: const TextStyle(color: AppTheme.primary)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ─── BAGIAN 5: LOGOUT ───
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: Text(_selectedLanguage == 'ID' ? 'Keluar dari Akun (Logout)' : 'Log Out of Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  // 1. Logout dari Firebase Auth
                  await FirebaseAuth.instance.signOut();

                  // 2. Hapus memori email lokal di SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('loggedInEmail');

                  // 3. Tendang user kembali ke layar Login
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),

          // ─── ANIMASI LOADING CLOUD OVERLAY ───
          if (_isLoadingCloud)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(
                            _selectedLanguage == 'ID' ? 'Menyinkronkan Cloud...' : 'Syncing with Cloud...',
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}