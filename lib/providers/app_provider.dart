// lib/providers/app_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/siswa.dart';
import '../models/pembayaran.dart';
import '../models/pengeluaran.dart';
import '../utils/notification_helper.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  // ─── STATE PIN DINAMIS ───
  String _appPin = "";
  String get appPin => _appPin;

  Future<void> updatePin(String newPin) async {
    _appPin = newPin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', newPin);
    await pushDataKeCloud(); // Langsung amankan ke cloud database
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.name);
    notifyListeners();
  }

  List<Siswa> _siswas = [];
  List<Pembayaran> _pembayarans = [];
  List<Pengeluaran> _pengeluarans = [];

  List<Siswa> get siswas => List.unmodifiable(_siswas);
  List<Pembayaran> get pembayarans => List.unmodifiable(_pembayarans);
  List<Pengeluaran> get pengeluarans => List.unmodifiable(_pengeluarans);

  double get totalPemasukan => _pembayarans.fold(0, (sum, p) => sum + p.jumlah);
  double get totalPengeluaran => _pengeluarans.fold(0, (sum, p) => sum + p.jumlah);
  double get saldoKas => totalPemasukan - totalPengeluaran;

  int get jumlahSiswaSudahBayar {
    final bulanIni = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final siswaYangBayar = _pembayarans.where((p) => p.bulan == bulanIni).map((p) => p.siswaId).toSet();
    return siswaYangBayar.length;
  }

  int get jumlahSiswaBelumBayar {
    final bulanIni = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final siswaYangBayar = _pembayarans.where((p) => p.bulan == bulanIni).map((p) => p.siswaId).toSet();
    return _siswas.where((s) => !siswaYangBayar.contains(s.id)).length;
  }

  bool sudahBayarBulanIni(String siswaId) {
    final bulanIni = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    return _pembayarans.any((p) => p.siswaId == siswaId && p.bulan == bulanIni);
  }

  List<Pembayaran> getPembayaranBySiswa(String siswaId) =>
      _pembayarans.where((p) => p.siswaId == siswaId).toList()..sort((a, b) => b.tanggal.compareTo(a.tanggal));

  Map<String, double> getPengeluaranByKategori() {
    final map = <String, double>{};
    for (final p in _pengeluarans) {
      map[p.kategori.label] = (map[p.kategori.label] ?? 0) + p.jumlah;
    }
    return map;
  }

  Map<String, double> getPemasukanPerBulan() {
    final map = <String, double>{};
    for (final p in _pembayarans) {
      map[p.bulan] = (map[p.bulan] ?? 0) + p.jumlah;
    }
    return map;
  }

  // ─── CLOUD SYNC LOGIC (DENGAN TAMBAHAN PIN) ─────────────────────

  Future<void> uploadStrukturPerdanaKeCloud() async {
    _appPin = ""; // Reset PIN agar pengguna baru wajib mendaftar PIN dulu
    await _seedData();
    await pushDataKeCloud();
  }

  Future<void> pushDataKeCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users_data').doc(user.uid);
    await docRef.set({
      'app_pin': _appPin, // Simpan PIN ke database sesuai akun email
      'siswas': _siswas.map((e) => e.toJson()).toList(),
      'pembayarans': _pembayarans.map((e) => e.toJson()).toList(),
      'pengeluarans': _pengeluarans.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> loadDataDariCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docSnap = await _firestore.collection('users_data').doc(user.uid).get();
    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data()!;

      // Ambil data PIN dari database cloud
      if (data['app_pin'] != null) {
        _appPin = data['app_pin'];
      }
      if (data['siswas'] != null) {
        _siswas = (data['siswas'] as List).map((e) => Siswa.fromJson(e)).toList();
      }
      if (data['pembayarans'] != null) {
        _pembayarans = (data['pembayarans'] as List).map((e) => Pembayaran.fromJson(e)).toList();
      }
      if (data['pengeluarans'] != null) {
        _pengeluarans = (data['pengeluarans'] as List).map((e) => Pengeluaran.fromJson(e)).toList();
      }

      await _save();
      notifyListeners();
    }
  }

  // ─── PERSISTENCE LOKAL ──────────────────────────────────────────
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString('themeMode');
    _themeMode = (savedTheme == 'dark') ? ThemeMode.dark : ThemeMode.light;

    _appPin = prefs.getString('app_pin') ?? "";

    final siswasJson = prefs.getString('siswas');
    if (siswasJson != null) {
      _siswas = (jsonDecode(siswasJson) as List).map((e) => Siswa.fromJson(e)).toList();
    }
    final pembayaransJson = prefs.getString('pembayarans');
    if (pembayaransJson != null) {
      _pembayarans = (jsonDecode(pembayaransJson) as List).map((e) => Pembayaran.fromJson(e)).toList();
    }
    final pengeluaransJson = prefs.getString('pengeluarans');
    if (pengeluaransJson != null) {
      _pengeluarans = (jsonDecode(pengeluaransJson) as List).map((e) => Pengeluaran.fromJson(e)).toList();
    }

    if (_siswas.isEmpty && FirebaseAuth.instance.currentUser != null) {
      await loadDataDariCloud();
    }

    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', _appPin);
    await prefs.setString('siswas', jsonEncode(_siswas.map((e) => e.toJson()).toList()));
    await prefs.setString('pembayarans', jsonEncode(_pembayarans.map((e) => e.toJson()).toList()));
    await prefs.setString('pengeluarans', jsonEncode(_pengeluarans.map((e) => e.toJson()).toList()));
  }

  // ─── OPERASI CRUD UTAMA KASKITA ───

  // SISWA CRUD
  Future<void> addSiswa(Siswa siswa) async {
    final newSiswa = siswa.copyWith(id: _uuid.v4());
    _siswas.add(newSiswa);
    await _save(); await pushDataKeCloud(); notifyListeners();
  }
  Future<void> updateSiswa(Siswa siswa) async {
    final index = _siswas.indexWhere((s) => s.id == siswa.id);
    if (index != -1) { _siswas[index] = siswa; await _save(); await pushDataKeCloud(); notifyListeners(); }
  }
  Future<void> deleteSiswa(String id) async {
    _siswas.removeWhere((s) => s.id == id); _pembayarans.removeWhere((p) => p.siswaId == id);
    await _save(); await pushDataKeCloud(); notifyListeners();
  }

  // PEMBAYARAN CRUD (SUDAH DIPERBAIKI)
  Future<void> addPembayaran(Pembayaran pembayaran) async {
    final newPembayaran = pembayaran.copyWith(id: _uuid.v4()); _pembayarans.add(newPembayaran);
    await _save(); await pushDataKeCloud();
    NotificationHelper.showTransactionNotification(title: 'Dana Masuk! 💰', body: 'Pembayaran kas dari ${newPembayaran.siswaName} berhasil dicatat.');
    notifyListeners();
  }
  Future<void> updatePembayaran(Pembayaran pembayaran) async {
    final index = _pembayarans.indexWhere((p) => p.id == pembayaran.id);
    if (index != -1) { _pembayarans[index] = pembayaran; await _save(); await pushDataKeCloud(); notifyListeners(); }
  }
  Future<void> deletePembayaran(String id) async { _pembayarans.removeWhere((p) => p.id == id); await _save(); await pushDataKeCloud(); notifyListeners(); }

  // PENGELUARAN CRUD (SUDAH DIPERBAIKI)
  Future<void> addPengeluaran(Pengeluaran pengeluaran) async {
    final newPengeluaran = pengeluaran.copyWith(id: _uuid.v4()); _pengeluarans.add(newPengeluaran);
    await _save(); await pushDataKeCloud();
    NotificationHelper.showTransactionNotification(title: 'Dana Keluar 💸', body: 'Pengeluaran untuk ${newPengeluaran.kategori.label} telah dicatat.');
    notifyListeners();
  }
  Future<void> updatePengeluaran(Pengeluaran pengeluaran) async {
    final index = _pengeluarans.indexWhere((p) => p.id == pengeluaran.id);
    if (index != -1) { _pengeluarans[index] = pengeluaran; await _save(); await pushDataKeCloud(); notifyListeners(); }
  }
  Future<void> deletePengeluaran(String id) async { _pengeluarans.removeWhere((p) => p.id == id); await _save(); await pushDataKeCloud(); notifyListeners(); }

  Future<void> _seedData() async {
    final kelasKaskita = '04SISP007';
    _siswas = [
      Siswa(id: _uuid.v4(), nis: '241091700546', nama: 'Ahmad Rijal Maulidina', kelas: kelasKaskita, noHp: '088976498862'),
      Siswa(id: _uuid.v4(), nis: '241091700412', nama: 'Aldi Kurniawan Aprianto', kelas: kelasKaskita, noHp: '0895365776429'),
      Siswa(id: _uuid.v4(), nis: '241091700599', nama: 'Alhadi Prawiro Saputro', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700507', nama: 'Asmaul Husna', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700622', nama: 'Aulia Syahidah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700433', nama: 'Bintang Ramadan', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700512', nama: 'Fatchur Rizky', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700414', nama: 'Fathul Ilmi Ramadhan', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700560', nama: 'Firman Hermansyah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700508', nama: 'Ibnu Hamdun', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700529', nama: 'Ihsan Radita', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700503', nama: 'Ilham Muhammad Ariansyah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700510', nama: 'Manda Maftukhah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700416', nama: 'Maulana Adin Al Irsyad', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700514', nama: 'Moh Nur Falah Aksal Faratama', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700523', nama: 'Muhammad Fathar Zahran Dhia', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700506', nama: 'Muhammad Alif Alghifari', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700480', nama: 'Muhammad Fadilah Arkan', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700460', nama: 'Muhammad Zaki Waliudin', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700553', nama: 'Mutiara Dinda Mahardika', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700435', nama: 'Nazwa Rihadatul Najiah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700540', nama: 'Nia Ni\'matul Maula', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700520', nama: 'Noval Arya Dwi Alamsyah', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700410', nama: 'Praninditha Zahara', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700566', nama: 'Rachel Chaeza Salsabila', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700338', nama: 'Rakha Farel Pratama', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700423', nama: 'Refangga Bagus Pratama', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700424', nama: 'Rizky Linda Anantasya', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700403', nama: 'Syahara Putri Amy Nabila', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700463', nama: 'Syahid Yasin', kelas: kelasKaskita, noHp: ''),
      Siswa(id: _uuid.v4(), nis: '241091700541', nama: 'Tio Tamamul Iman', kelas: kelasKaskita, noHp: ''),
    ];
    _pembayarans = []; _pengeluarans = []; await _save();
  }
}