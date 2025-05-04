import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  
  static get FlutterNativeTimezone => null;

  // Initialize notifications
  static Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  // Request notification permissions
  static Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await init();
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted = await androidPlugin?.requestPermission();
    return granted ?? false;
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  // Show immediate notification
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!await areNotificationsEnabled()) {
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int id = 0,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!await areNotificationsEnabled()) {
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Channel',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Set notifications enabled/disabled
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
  }

  // Notification for bus arrival
  static Future<void> showBusArrivalNotification({
    required int minutesAway,
    required String busNumber,
    required String stopName,
    int id = 1,
  }) async {
    final title = 'Bus $busNumber Approaching';
    final body = 'Your bus will arrive at $stopName in $minutesAway minutes';

    await showNotification(
      title: title,
      body: body,
      id: id,
      payload: 'bus_arrival:$busNumber:$stopName',
    );
  }

  // Notification for bus delay
  static Future<void> showBusDelayNotification({
    required int delayMinutes,
    required String busNumber,
    required String routeName,
    int id = 2,
  }) async {
    final title = 'Bus $busNumber Delayed';
    final body =
        'Your bus on route $routeName is delayed by $delayMinutes minutes';

    await showNotification(
      title: title,
      body: body,
      id: id,
      payload: 'bus_delay:$busNumber:$routeName',
    );
  }

  // Notification for route alert (service disruptions, etc.)
  static Future<void> showRouteAlertNotification({
    required String routeName,
    required String message,
    int id = 3,
  }) async {
    final title = 'Alert for Route $routeName';

    await showNotification(
      title: title,
      body: message,
      id: id,
      payload: 'route_alert:$routeName',
    );
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  requestPermission() {}
}
