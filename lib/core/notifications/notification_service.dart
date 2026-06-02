import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sam_sama_alerts',
    'Alertes Sam Sama Allal',
    description: 'Notifications pour stocks, tickets et alertes importantes.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sam_sama_alerts',
          'Alertes Sam Sama Allal',
          channelDescription:
              'Notifications pour stocks, tickets et alertes importantes.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showStockAlert({
    required String itemName,
    required int quantity,
  }) async {
    final isOut = quantity <= 0;
    await showNotification(
      title: isOut ? 'Rupture de stock' : 'Stock faible',
      body: isOut
          ? '$itemName est en rupture.'
          : '$itemName est presque épuisé. Quantité restante: $quantity.',
    );
  }

  Future<void> showTicketDownloaded(String path) async {
    await showNotification(
      title: 'Ticket téléchargé',
      body: 'Le ticket de caisse a été enregistré.',
    );
  }
}
