library menoti;

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';


/// Menoti
class Menoti {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Location _location = Location();

  /// Method to be called by package user
  Future<void> initialize(
      {required Function(String deepLink) onDeepLink,
      required Function(MenotiNotification notificationData) onNotification,
      required Function(MenotiNotification notificationData) onNotificationTap,
      required Function(String regionId, bool entered) onGeofenceEvent,
      required List<Coordinate> geofenceCoordinates}) async {
    await _initializeFirebaseMessaging(onNotification);
    await _initializeLocalNotifications(onNotificationTap);
    await _initializeGeofencing(geofenceCoordinates, onGeofenceEvent);
  }

  Future<void> _initializeFirebaseMessaging(
      Function(MenotiNotification notificationData) onNotification) async {
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        RemoteNotification remoteNotification = message.notification!;

        MenotiNotification menotiNotification = MenotiNotification(
            title: remoteNotification.title.toString(),
            body: remoteNotification.body.toString(),
            data: message.data);

        onNotification(menotiNotification);
        _showLocalNotification(message: menotiNotification);
      }
    });
    FirebaseMessaging.onBackgroundMessage((RemoteMessage message){
      RemoteNotification remoteNotification = message.notification!;
        MenotiNotification menotiNotification = MenotiNotification(
            title: remoteNotification.title.toString(),
            body: remoteNotification.body.toString(),
            data: message.data);
        onNotification(menotiNotification);
        return Future.value();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification remoteNotification = message.notification!;
      if (message.data.isNotEmpty) {
        MenotiNotification menotiNotification = MenotiNotification(
            title: remoteNotification.title.toString(),
            body: remoteNotification.body.toString(),
            data: message.data);
        onNotification(menotiNotification);
      }
    });
  }

  Future<void> _initializeLocalNotifications(
      Function(MenotiNotification notificationData) onNotificationTap) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings =
        InitializationSettings(android: android, iOS: iOS);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      onNotificationTap(
          MenotiNotification.fromJsonString(response.payload.toString()));
    }, onDidReceiveBackgroundNotificationResponse:
            (NotificationResponse response) {
      onNotificationTap(
          MenotiNotification.fromJsonString(response.payload.toString()));
    });
  }

  Future<void> _showLocalNotification(
      {required MenotiNotification message}) async {
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
        0, message.title, message.body, notificationDetails,
        payload: message.toJsonString());
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

/// Geofence Coordinate Data Class
class Coordinate {
  /// ID of the Geofence.
  final String id;
  /// Name of the Geofence.
  final String name;
  /// Latitude of the Geofence center.
  final double latitude;
  /// Longitude of the Geofence center.
  final double longitude;
  /// Radius of Feofence
  final double radius;

  /// Constructor
  Coordinate(this.id, this.name, this.latitude, this.longitude, this.radius);
}

/// Notification Data Class
class MenotiNotification {
  /// Notification Title.
  final String title;
  /// Notification Body.
  final String body;
  /// Extra Data.
  final Map<String, dynamic> data;

  /// Constructor
  const MenotiNotification(
      {required this.title, required this.body, this.data = const {}});

  ///Method to convert Data Class to JSON String
  String toJsonString() {
    final jsonMap = {
      'title': title,
      'body': body,
      'data': data,
    };
    return jsonEncode(jsonMap);
  }

  /// Method to convert String to Data Class
  factory MenotiNotification.fromJsonString(String jsonString) {
    final jsonMap = jsonDecode(jsonString);
    return MenotiNotification(
      title: jsonMap['title'] as String,
      body: jsonMap['body'] as String,
      data: jsonMap['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
