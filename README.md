## Features

 - Notification Management
   ```text
      Set your functionality when Notification is received from FCM
      Notifications are displayed when triggered from FCM
      Notification tap can also be set
   ```
 - Geofencing
   ```text
      Get the status of user if he is in your set location(s)
      Trigger notifications based on user location
   ```

## Getting started

 - **Android**
    
    - GEOFENCING
   
        Since the geofencing service works based on location, we need to declare location permission. 
        Open the ```AndroidManifest.xml``` file and declare permission between the <manifest> and <application> tags.
    
        ```xml
        <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
        <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
        <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
      ```
      
        In Manifest also add a service
        ```xml
        <service android:name="io.flutter.plugins.geofencing.GeofencingService"
        android:permission="android.permission.BIND_JOB_SERVICE"
        android:exported="true"/>
      ```

    - NOTIFICATIONS
   
        In app/build.gradle add the below
        ```groovy
        android {
            defaultConfig {
                multiDexEnabled true
            }
            compileOptions {
                coreLibraryDesugaringEnabled true
            }
            dependencies {
                coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.2'
                implementation 'androidx.window:window:1.0.0'
                implementation 'androidx.window:window-java:1.0.0'
            }
        }
        ```
        
        In Manifest add the below
         ```xml
          <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
            <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
                <intent-filter>
                    <action android:name="android.intent.action.BOOT_COMPLETED"/>
                    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                    <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
                </intent-filter>
            </receiver>
         ```
   
- **IOS**
   Open the ```ios/Runner/Info.plist``` file and declare description within the <dict> tag.
        
    ```xml
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Used to collect location data.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Used to collect location data in the background.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Used to collect location data in the background.</string>
    <key>UIBackgroundModes</key>
    <array>
    <string>fetch</string>
    <string>location</string>
    </array>
  ```

## Usage

   Menoti has a class named ```Coordinate```, a list of this is to be created to be passed for geofencing locations.
   this class has required params as id, name, latitude, longitude and radius.

   It also has a class named ```MenotiNotification``` which contains the notification data 

   Both classes are used in below code

   ```dart
      List<Coordinate> list = [
         Coordinate("test1", "Royal Park", 18.5775513, 73.7660493, 300)
      ];

      final menoti = Menoti();
      await menoti.initialize(
      onDeepLink: (deepLink) => debugPrint('Deep Link: $deepLink'),
      onNotification: (MenotiNotification notificationData) =>
        debugPrint('Notification Data: ${notificationData.body}'),
      onGeofenceEvent: (regionId, entered) =>
        debugPrint('Geofence Event: $regionId, Entered: $entered'),
      geofenceCoordinates: list,
      onNotificationTap: (MenotiNotification notificationData) {
        debugPrint("N-TAP");
      });
   ```

