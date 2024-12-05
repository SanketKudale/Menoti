library menoti;

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofencing_api/geofencing_api.dart';

class Menoti {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  AppLinks? _appLinks;

  Future<void> initialize({
    required Function (String deepLink) onDeepLink,
    required Function (String notificationData) onNotification,
    required Function (String regionId, bool entered) onGeofenceEvent
}) async {

  }

  Future<void> _initializeFirebaseMessaging(
      Function(String notificationData) onNotification) async {
    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notificationData = message.data.toString();
        onNotification(notificationData);
        _showLocalNotification(
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        onNotification(message.data.toString());
      }
    });
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings =
    InitializationSettings(android: android, iOS: iOS);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  /// Initialize deep linking with `app_links`
  Future<void> _initializeDeepLinking(Function(String deepLink) onDeepLink) async {
    _appLinks = AppLinks();
    final initialLink = await _appLinks?.getInitialAppLink();
    if (initialLink != null) {
      onDeepLink(initialLink.toString());
    }

    _appLinks?.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        onDeepLink(uri.toString());
      }
    });
  }

  /// Initialize geofencing
  Future<void> _initializeGeofencing(
      Function(String regionId, bool entered) onGeofenceEvent) async {
    Geofencing.initialize();
    GeofenceRegion region = GeofenceRegion(
      id: 'test_geofence',
      latitude: 37.7749, // Example latitude
      longitude: -122.4194, // Example longitude
      radius: 100, // Radius in meters
    );

    Geofen  cingAPI.registerGeofence(region, (GeofenceEvent event) {
      if (event == GeofenceEvent.enter) {
        onGeofenceEvent(region.id, true);
      } else if (event == GeofenceEvent.exit) {
        onGeofenceEvent(region.id, false);
      }
    });
  }

}
