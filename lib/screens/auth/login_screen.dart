// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../main.dart';
import '../home_screen.dart';
import '../../api/apis.dart';
import '../../helpers/dialogs.dart';
import '../../helpers/loading_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isAnimate = false;

  AnimationController? _controllerI, _controllerG;
  Animation<Offset>? _animationIcon, _animationG;

  @override
  void initState() {
    super.initState();
    _controllerI = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _controllerG = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _animationIcon = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controllerI!, curve: Curves.easeIn));

    _animationG = Tween<Offset>(
      begin: const Offset(0, 2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controllerG!, curve: Curves.easeIn));

    _controllerI!.forward().then((value) => _controllerG!.forward());

    Future.delayed(
      const Duration(milliseconds: 500),
      () => setState(() => _isAnimate = true),
    );
  }

  @override
  void dispose() {
    _controllerI!.dispose();
    _controllerG!.dispose();
    super.dispose();
  }

  _handleGoogleButtonClick() {
    _signInWithGoogle().then(
      (user) async {
        if (user != null) {
          if (await APIs.userExists()) {
            await APIs.getSelfInfo().then(
              (_) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
            );
          } else {
            await APIs.createUser().then(
              (_) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
            );
          }
        }
      },
    );
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      LoadingScreen()
          .show(context: context, text: 'Please Wait While I Sigin You In');

      if (!kIsWeb) await InternetAddress.lookup('google.com');
      // Trigger the authentication flow

      final googleSignIn = GoogleSignIn(scopes: ['openid', 'email', 'profile']);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      var cred = await FirebaseAuth.instance.signInWithCredential(credential);
      LoadingScreen().hide();
      return cred;
    } catch (e) {
      log('\n_signInWithGoogle = $e');
      Dialogs.showSnackbar(context, 'Something went wrong');
      LoadingScreen().hide();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobileLoginScreen(),
      desktop: (BuildContext context) => desktopLoginScreen(),
    );
  }

  Widget mobileLoginScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to We Chat'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            top: mobileMq.height * .15,
            right: _isAnimate ? mobileMq.width * .25 : -mobileMq.width * .5,
            width: mobileMq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset('images/icon.png'),
          ),
          Positioned(
            bottom: mobileMq.height * .15,
            left: mobileMq.width * .05,
            width: mobileMq.width * .9,
            height: mobileMq.height * .06,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                shape: const StadiumBorder(),
                elevation: 1,
              ),
              onPressed: () => _handleGoogleButtonClick(),
              icon: Image.asset('images/google.png',
                  height: mobileMq.height * .03),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 18),
                  children: [
                    TextSpan(text: ' Login With '),
                    TextSpan(
                      text: 'Google',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget desktopLoginScreen() {
    Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to We Chat')),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SlideTransition(
                position: _animationIcon!,
                child: SizedBox(
                  width: double.infinity,
                  height: mq.height * .45,
                  child: Image.asset('images/icon.png'),
                ),
              ),
              SlideTransition(
                position: _animationG!,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                      shape: const StadiumBorder(),
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                          vertical: 23, horizontal: 100),
                    ),
                    onPressed: () => _handleGoogleButtonClick(),
                    icon: Image.asset('images/google.png',
                        height: mq.height * .05),
                    label: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        children: [
                          TextSpan(text: ' Login With '),
                          TextSpan(
                            text: 'Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
