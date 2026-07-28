// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import animasi keren
import '../providers/app_provider.dart';
import '../utils/app_utils.dart';
import 'lock_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ─── LOGIN MENGGUNAKAN EMAIL ───
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email dan Password wajib diisi!', AppTheme.danger);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _checkAndSyncData('Selamat datang kembali! Data kas berhasil dipulihkan. ☁️');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
          await _initNewUserData('Akun baru berhasil didaftarkan ke cloud server.');
        } catch (signUpError) {
          _showSnackbar('Pendaftaran gagal: ${signUpError.toString()}', AppTheme.danger);
        }
      } else {
        _showSnackbar('Autentikasi Gagal: ${e.message}', AppTheme.danger);
      }
    }

    setState(() => _isLoading = false);
  }

  // ─── LOGIN MENGGUNAKAN GOOGLE ───
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await _googleSignIn.signOut(); // Selalu tanya pilihan akun

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users_data').doc(user.uid).get();

        if (!doc.exists) {
          await _initNewUserData('Berhasil masuk via Google. Akun baru disiapkan!');
        } else {
          await _checkAndSyncData('Login Google berhasil. Sinkronisasi data selesai! ☁️');
        }
      }
    } catch (e) {
      _showSnackbar('Gagal masuk dengan Google: $e', AppTheme.danger);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkAndSyncData(String successMessage) async {
    if (mounted) {
      await Provider.of<AppProvider>(context, listen: false).loadDataDariCloud();
      _showSnackbar(successMessage, AppTheme.success);
      _goToLockScreen();
    }
  }

  Future<void> _initNewUserData(String successMessage) async {
    if (mounted) {
      await Provider.of<AppProvider>(context, listen: false).uploadStrukturPerdanaKeCloud();
      _showSnackbar(successMessage, AppTheme.primary);
      _goToLockScreen();
    }
  }

  void _goToLockScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // MENGGUNAKAN STACK AGAR LOADING BISA MELAYANG DI ATAS KONTEN
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  const Icon(Icons.account_balance_wallet, size: 80, color: AppTheme.primary),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang di KasKita',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sistem Informasi Manajemen Kas\nKelas 04SISP007',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 48),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Kampus / Pribadi',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      child: const Text('Login dengan Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ATAU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDADCE0), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                      label: const Text(
                        'Masuk dengan Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF3C4043)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── FITUR LOADING KEREN (OVERLAY) ───
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6), // Layar belakang jadi gelap
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animasi kubus melayang warna putih
                    const SpinKitCubeGrid(
                      color: Colors.white,
                      size: 60.0,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Mengamankan Koneksi...',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}