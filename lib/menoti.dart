library menoti;

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

class Menoti {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  AppLinks? _appLinks;

  final Location _location = Location();

  Future<void> initialize(
      {required Function(String deepLink) onDeepLink,
        required Function(RemoteMessage notificationData) onNotification,
        required Function(String regionId, bool entered) onGeofenceEvent,
        required List<Coordinate> geofenceCoordinates}) async {
    await _initializeFirebaseMessaging(onNotification);
    await _initializeLocalNotifications();
    await _initializeDeepLinking(onDeepLink);
    await _initializeGeofencing(geofenceCoordinates, onGeofenceEvent);
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

  bool _isWithinGeofence(
      Position userPosition,
      double geofenceLatitude,
      double geofenceLongitude,
      double geofenceRadiusInMeters,
      ) {
    double distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      geofenceLatitude,
      geofenceLongitude,
    );
    return distance <= geofenceRadiusInMeters;
  }

  Future<Position> _getUserLocation() async {
    LocationData locationData = await _location.getLocation();
    return Position(
      latitude: locationData.latitude!,
      longitude: locationData.longitude!,
      timestamp: DateTime.now(),
      accuracy: 50,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
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
      debugPrint('onAppLink: $uri');
      if (uri != null) {
        onDeepLink(uri.toString());
      }
    });
  }

  Future<void> _initializeGeofencing(
      List<Coordinate> coordinates,
      Function(
          String regionId,
          bool entered,
          ) onGeofenceEvent) async {
    _location.enableBackgroundMode(enable: true);

    _location.onLocationChanged.listen((LocationData locationData) {
      Position currentPosition = Position(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        timestamp: DateTime.now(),
        accuracy: 50,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      for (Coordinate coordinate in coordinates) {
        if (_isWithinGeofence(currentPosition, coordinate.latitude,
            coordinate.longitude, coordinate.radius)) {
          onGeofenceEvent(coordinate.id, true);
        } else {
          onGeofenceEvent(coordinate.id, false);
        }
      }
    });
  }
}

class Coordinate {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;

  Coordinate(this.id, this.name, this.latitude, this.longitude, this.radius);
}
