import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:menoti/menoti.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

Future<void> getToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  var status = await Permission.location.request();
  if (status.isGranted) {
    debugPrint('Location permission granted');
  } else if (status.isDenied) {
    debugPrint('Location permission denied');
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    debugPrint('FCM Token retrieved: $token');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint('User granted provisional notification permission');
  } else {
    debugPrint('User declined notification permission');
  }
}

Future<void> requestLocationPermissions() async {
  var status = await Permission.locationWhenInUse.request();
  if (status.isGranted) {
    debugPrint('Location permission granted');
  } else if (status.isDenied) {
    debugPrint('Location permission denied');
    return;
  } else if (status.isPermanentlyDenied) {
    debugPrint(
        'Location permission permanently denied. Opening app settings...');
    await openAppSettings();
    return;
  }

  if (await Permission.locationAlways.isDenied) {
    var bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      debugPrint('Background location permission denied');
      return;
    }
    debugPrint('Background location permission granted');
  }

  // Check if location services are enabled
  bool locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
  if (!locationServicesEnabled) {
    debugPrint(
        'Location services are disabled. Prompting user to enable them.');
    await showEnableLocationServicesDialog();
  }
}

Future<void> initializeAsync() async {
  await Firebase.initializeApp();

  requestLocationPermissions();

  List<Coordinate> list = [
    Coordinate("test1", "Royal Park", 18.577551, 73.768624, 200)
  ];

  await getToken();
  final menoti = Menoti();
  await menoti.initialize(
      onNotification: (MenotiNotification notificationData) =>
          debugPrint('Notification Data: ${notificationData.body}'),
      onGeofenceEvent: (regionId, entered) {
        debugPrint('Geofence Event: $regionId, Entered: $entered');
        //If needed you can trigger notification here
        menoti.showLocalNotification(message: MenotiNotification(title: "title", body: "body"));
      },
      geofenceCoordinates: list,
      onNotificationTap: (MenotiNotification notificationData) {
        debugPrint(notificationData.toJsonString());
      });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(),
      ),
    );
  }
}

Future<void> showEnableLocationServicesDialog() async {
  await showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: const Text('Enable Location Services'),
      content: const Text(
          'This app requires location services to function. Please enable them in your device settings.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await Geolocator.openLocationSettings();
            Navigator.of(context).pop();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
