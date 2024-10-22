// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:colearn/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    splash();
    super.initState();
  }

  splash() async {
    await Future.delayed(const Duration(milliseconds: 3150), () {});
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Wrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 49, 27, 87),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 200),
            child: Lottie.asset(
              "assets/animations/Splash_Screen.json",
            ),
          ),
          Spacer(),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Image.asset(
                "assets/images/Logo.png",
                width: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
