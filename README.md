## Features

 - Notification Management
 - Deep Linking
 - Geofencing

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

   ```dart
   final menoti = Menoti();

   await menoti.initialize(
    onDeepLink: (deepLink) {
      print('Deep Link: $deepLink');
    },
    onNotification: (RemoteMessage notificationData) {
      print('Notification Data: $notificationData');
    },
    onGeofenceEvent: (regionId, entered) {
      print('Geofence Event: $regionId, Entered: $entered');
    },
   );
   ```

