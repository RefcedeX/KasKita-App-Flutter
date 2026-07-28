// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File otomatis dari flutterfire configure
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'screens/splash_screen.dart';
import 'utils/notification_helper.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_siswa_screen.dart';
import 'screens/pembayaran_screen.dart';
import 'screens/pengeluaran_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationHelper.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Cek apakah ada user Firebase yang masih aktif login
  User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..loadData(),
      child: KasKitaApp(isLoggedIn: currentUser != null),
    ),
  );
}

class KasKitaApp extends StatelessWidget {
  final bool isLoggedIn;
  const KasKitaApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'KAS007',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<_NavItem> _items = [
    const _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Beranda', screen: DashboardScreen()),
    const _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Siswa', screen: DataSiswaScreen()),
    const _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Kas', screen: PembayaranScreen()),
    const _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Keluar', screen: PengeluaranScreen()),
    const _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan', screen: LaporanScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _items.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 68.0,
        color: isDark ? AppTheme.darkCard : AppTheme.primaryDark,
        buttonBackgroundColor: AppTheme.primary,
        backgroundColor: scaffoldBgColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: _items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isSelected = _currentIndex == i;

          return Container(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: isSelected ? 30 : 24,
                  color: Colors.white,
                ),
                if (!isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}