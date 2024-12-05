library menoti;

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofencing_api/geofencing_api.dart';

class Menoti {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AppLinks? _appLinks;

  Future<void> initialize({
    required Function(String deepLink) onDeepLink,
    required Function(RemoteMessage notificationData) onNotification,
    required Function(String regionId, bool entered) onGeofenceEvent,
  }) async {
    await _initializeFirebaseMessaging(onNotification);
    await _initializeLocalNotifications();
    await _initializeDeepLinking(onDeepLink);
    await _initializeGeofencing(onGeofenceEvent);
  }

  Future<void> _initializeFirebaseMessaging(
      Function(RemoteMessage notificationData) onNotification) async {
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        onNotification(message);
        _showLocalNotification(
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? 'No content',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        onNotification(message);
      }
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings =
        InitializationSettings(android: android, iOS: iOS);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'menoti_#825',
      'Menoti',
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

  Future<void> _initializeDeepLinking(
      Function(String deepLink) onDeepLink) async {
    _appLinks = AppLinks();
    final initialLink = await _appLinks?.getInitialLink();
    if (initialLink != null) {
      onDeepLink(initialLink.toString());
    }

    _appLinks?.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        onDeepLink(uri.toString());
      }
    });
  }

  Future<void> _initializeGeofencing(
      Function(String regionId, bool entered) onGeofenceEvent) async {
    Geofencing.instance.setup(
      interval: 5000,
      accuracy: 100,
      statusChangeDelay: 10000,
      allowsMockLocation: false,
      printsDebugLog: true,
    );

    final Set<GeofenceRegion> _regions = {
      GeofenceRegion.circular(
        id: 'circular_region',
        data: {
          'name': 'National Museum of Korea',
        },
        center: const LatLng(37.523085, 126.979619),
        radius: 250,
        loiteringDelay: 60 * 1000,
      ),
    };

    Geofencing.instance.addGeofenceStatusChangedListener(
        (GeofenceRegion geofenceRegion, GeofenceStatus geofenceStatus,
            Location location) {
      final String regionId = geofenceRegion.id;
      switch (geofenceStatus) {
        case GeofenceStatus.enter:
          onGeofenceEvent(regionId, true);
          break;
        case GeofenceStatus.exit:
          onGeofenceEvent(regionId, false);
          break;
        case GeofenceStatus.dwell:
          break;
      }
      return Future.value();
    });
    Geofencing.instance.addGeofenceErrorCallbackListener(_onGeofenceError);

    await Geofencing.instance.start(regions: _regions);
  }

  void _onGeofenceError(Object error, StackTrace stackTrace) {
    // print('error: $error\n$stackTrace');
  }

  /*void pauseGeofencing() {
    Geofencing.instance.pause();
  }

  void resumeGeofencing() {
    Geofencing.instance.resume();
  }

  void addRegions() {
    Geofencing.instance.addRegion(GeofenceRegion);
    Geofencing.instance.addRegions(Set<GeofenceRegion>);
  }

  void removeRegions() {
    Geofencing.instance.removeRegion(GeofenceRegion);
    Geofencing.instance.removeRegions(Set<GeofenceRegion>);
    Geofencing.instance.removeRegionById(String);
    Geofencing.instance.clearAllRegions();
  }

  void stopGeofencing() async {
    Geofencing.instance
        .removeGeofenceStatusChangedListener(_onGeofenceStatusChanged);
    Geofencing.instance.removeGeofenceErrorCallbackListener(_onGeofenceError);
    Geofencing.instance.removeLocationChangedListener(LocationChanged);
    Geofencing.instance.removeLocationServicesStatusChangedListener(
        LocationServicesStatusChanged);

    await Geofencing.instance.stop(keepsRegions: true);
  }*/
}
