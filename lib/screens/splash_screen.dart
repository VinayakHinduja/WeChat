// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../main.dart';
import '../api/apis.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    Future.delayed(const Duration(milliseconds: 1500), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarContrastEnforced: false,
          statusBarColor: Colors.white,
          systemNavigationBarColor: Colors.white,
        ),
      );
      if (APIs.auth.currentUser != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mobileMq = MediaQuery.of(context).size;

    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileLoginScreen(),
      desktop: (BuildContext context) => desktopLoginScreen(),
    );
  }

  Widget mobileLoginScreen() {
    Size mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: mq.height * .15,
            right: mq.width * .25,
            width: mq.width * .5,
            child: Image.asset('images/icon.png'),
          ),
          Positioned(
            bottom: mq.height * .15,
            width: mq.width,
            child: const Text(
              ' MADE IN INDIA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget desktopLoginScreen() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Image.asset('images/icon.png'),
          ),
          const SizedBox(height: 30),
          const Text(
            ' WE CHAT ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          // const SizedBox(height: 5),
          const Text(
            ' MADE IN INDIA ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              // letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
