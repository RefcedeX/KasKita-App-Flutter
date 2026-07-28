// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_utils.dart';
import 'login_screen.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Tambahkan "with SingleTickerProviderStateMixin" agar layar ini bisa menjalankan animasi
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Siapkan mesin penggerak animasi (berdurasi 1.5 detik)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. Buat gaya animasinya: Membesar dengan efek memantul halus (easeOutBack) di akhir
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // 3. Mulai mainkan animasinya!
    _animationController.forward();

    // 4. Jalankan pengecekan login seperti biasa
    _checkLoginStatus();
  }

  @override
  void dispose() {
    // Wajib dimatikan saat layar berpindah agar HP tidak boros RAM
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LockScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── KONTEN UTAMA DIBUNGKUS ANIMASI TRANSTION ───
            ScaleTransition(
              scale: _scaleAnimation, // Memanggil efek membesar-memantul
              child: FadeTransition(
                opacity: _animationController, // Memanggil efek memudar masuk (Fade-in)
                child: const Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 100,
                      color: Colors.white,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'KasKita',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sistem Manajemen Kas 04SISP007',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            // Animasi Gelombang Loading
            const SpinKitRipple(
              color: Colors.white,
              size: 70.0,
              borderWidth: 5.0,
            ),
          ],
        ),
      ),
    );
  }
}