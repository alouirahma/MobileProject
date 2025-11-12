import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    final androidDetails = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidDetails?.requestNotificationsPermission();

    final iosDetails = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosDetails?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> show({required String title, required String body, int id = 0}) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'reviews_channel',
      'Notifications Avis',
      channelDescription: 'Alertes pour réponses et modérations',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details);
  }

  Future<void> showReplyNotification({required String responderName, required String contentTitle}) async {
    await show(
      title: 'Nouvelle réponse',
      body: '$responderName a répondu: $contentTitle',
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    );
  }

  Future<void> showModerationNotification({required String status, required String contentTitle}) async {
    await show(
      title: 'Modération de votre avis',
      body: 'Votre avis sur "$contentTitle" a été $status.',
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    );
  }
}
