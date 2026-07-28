// lib/utils/notification_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('007');

      const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      try {
        await scheduleWeeklyTuesdayNotification();
      } catch (e) {
        debugPrint('Gagal menjadwalkan alarm Selasa: $e');
      }
    } catch (e) {
      debugPrint('Error saat inisialisasi notifikasi: $e');
    }
  }

  // ─── FUNGSI NOTIFIKASI TRANSAKSI KAS ───
  static Future<void> showTransactionNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'transaction_channel',
      'Transaksi Kas',
      channelDescription: 'Notifikasi untuk pemasukan dan pengeluaran kas',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1E88E5),
      icon: '007',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // ─── FUNGSI JADWAL RUTIN SELASA JAM 08:00 PAGI ───
  static Future<void> scheduleWeeklyTuesdayNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'channel_selasa_otomatis',
      'Pengingat Kas Selasa',
      channelDescription: 'Channel untuk notifikasi rutin',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1E88E5),
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notif_aplikasi'),
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // ─── PERBAIKAN: Parameter yang usang (uiLocalNotification...) sudah dihapus ───
    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Waktunya Tagih Kas! 📢',
      body: 'Hari Selasa nih, WOI GOBLOG BAYAR UANG KAS YA ANJENK!.',
      scheduledDate: _nextInstanceOfTuesday(),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ─── FUNGSI ALA SHOPEE: CHANNEL DINAMIS UNTUK TOMBOL TEST ───
  static Future<void> tampilkanNotifSuaraKustom(String namaFileSuara) async {
    try {
      String channelIdDinamis = 'channel_notif_$namaFileSuara';

      AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        channelIdDinamis,
        'Notifikasi Kas',
        channelDescription: 'Channel untuk notifikasi dengan suara kustom',
        importance: Importance.max,
        priority: Priority.high,
        color: const Color(0xFF1E88E5),
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound(namaFileSuara),
      );

      NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: 'Test Suara Dinamis! 📢',
        body: 'Cek suara kas masuk. Ting Tong!',
        notificationDetails: platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint("ERROR GAGAL NOTIF: $e");
    }
  }

  // ─── FUNGSI PEMBANTU: PENCARI HARI SELASA TERDEKAT JAM 08:00 PAGI ───
  static tz.TZDateTime _nextInstanceOfTuesday() {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Setting ke Jam 08:00 Pagi
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);

    // Cari hari Selasa (DateTime.tuesday)
    while (scheduledDate.weekday != DateTime.tuesday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Jika hari ini sudah Selasa tapi jam 8 pagi sudah lewat, lempar ke Selasa depan
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}