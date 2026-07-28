// lib/screens/lock_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_utils.dart';
import '../main.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = "";
  String _firstPin = ""; // Menampung PIN pertama saat pendaftaran
  bool _isConfirming = false; // Status apakah sedang konfirmasi PIN baru

  void _onPinTap(String number, String storedPin) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += number);
    }

    if (_enteredPin.length == 4) {
      // ─── KONDISI A: JIKA BELUM ADA PIN DI DATABASE (PENDAFTARAN) ───
      if (storedPin.isEmpty) {
        if (!_isConfirming) {
          // Langkah 1: Simpan PIN pertama dan minta konfirmasi
          setState(() {
            _firstPin = _enteredPin;
            _enteredPin = "";
            _isConfirming = true;
          });
        } else {
          // Langkah 2: Cocokkan PIN konfirmasi dengan PIN pertama
          if (_enteredPin == _firstPin) {
            // Sukses! Daftarkan ke Provider (Lokal & Cloud)
            Provider.of<AppProvider>(context, listen: false).updatePin(_enteredPin).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN Berhasil Didaftarkan ke Database! 🔐'), backgroundColor: AppTheme.success),
              );
              _goToDashboard();
            });
          } else {
            // Gagal, reset ulang pendaftaran
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN tidak cocok! Silakan ulangi.'), backgroundColor: AppTheme.danger),
            );
            setState(() {
              _firstPin = "";
              _enteredPin = "";
              _isConfirming = false;
            });
          }
        }
      }
      // ─── KONDISI B: JIKA PIN SUDAH TERDAFTAR (VERIFIKASI MASUK) ───
      else {
        if (_enteredPin == storedPin) {
          _goToDashboard();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN Salah! Coba lagi.'), backgroundColor: AppTheme.danger),
          );
          setState(() => _enteredPin = ""); // Reset
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final String storedPin = provider.appPin;

    // Menentukan judul dinamis berdasarkan status akun
    String titleText = "Masukkan PIN KasKita";
    if (storedPin.isEmpty) {
      titleText = _isConfirming ? "Konfirmasi PIN Baru Anda" : "Daftarkan PIN Baru KasKita";
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            titleText,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (storedPin.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'PIN ini akan diamankan di database cloud sesuai email Anda',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 30),
          // Indikator Titik-Titik PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Container(
              margin: const EdgeInsets.all(8),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _enteredPin.length ? Colors.white : Colors.white24,
              ),
            )),
          ),
          const SizedBox(height: 40),
          // Numpad Keypad
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 50),
            children: [
              ...List.generate(9, (index) => _numpadButton((index + 1).toString(), storedPin)),
              const SizedBox(),
              _numpadButton("0", storedPin),
              IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.white),
                  onPressed: _onBackspace
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadButton(String number, String storedPin) {
    return TextButton(
      onPressed: () => _onPinTap(number, storedPin),
      child: Text(number, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}