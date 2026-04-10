import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:home_finder_/pages/login.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const String routeName="/splash";

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Duration duration = Duration();
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child:  Lottie.asset(
              "assets/loading1.json",
              backgroundLoading: true,
              onLoaded: (composit) {
                setState(() {
                  duration = composit.duration;
                });
              },
            ),
      ),
      backgroundColor: const Color.fromARGB(255, 241, 237, 171),
      splashIconSize: 500,
      duration: duration.inMilliseconds,
      nextScreen: LoginPage(),
    );
  }
}
