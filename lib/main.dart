import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .whenComplete(() async {
    await _initailizeFirebase();
    runApp(const MyApp());
  });
}

late Size homeMq;
late Size chatMq;
late Size mobileMq;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.black,
            fontSize: 19,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

Future<void> _initailizeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) return;
  await FlutterNotificationChannel.registerNotificationChannel(
    description: 'For showing message notifications',
    id: 'chats',
    name: 'Chats',
    importance: NotificationImportance.IMPORTANCE_HIGH,
  );
}
