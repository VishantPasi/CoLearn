// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:colearn/apis.dart';
import 'package:colearn/wrapper.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';

class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  late Timer timer;
  int sec = 30;
  int min = 1;
  bool canResendEmail = false;
  final userDetailsBox = GetStorage();

  snackBarContainer(snackBarText) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: const Color.fromARGB(255, 196, 54, 54),
          dismissDirection: DismissDirection.down,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          duration: const Duration(seconds: 3),
          content: Center(
            child: Text(snackBarText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 19)),
          )),
    );
  }

  Future addData() async {
    try {
      await APIs.firestore
          .collection(userDetailsBox.read("role"))
          .doc(APIs.auth.currentUser!.uid)
          .set({
        "full_name": userDetailsBox.read("fullName"),
        "email": userDetailsBox.read("email"),
        "role": userDetailsBox.read("role"),
      });
    } catch (e) {
      snackBarContainer('Failed to add data');
    }
  }

  Future verification() async {
    try {
      timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        APIs.auth.currentUser?.reload();

        if (APIs.auth.currentUser?.emailVerified == true) {
          addData();
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Wrapper()));
        } else if (APIs.auth.currentUser?.emailVerified == false) {}
      });
    } on Exception catch (e) {
      snackBarContainer(e.toString());
    }
  }

  @override
  void initState() {
    verification();
    countDown();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  countDown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sec == 0 && min == 0) {
        setState(() {
          canResendEmail = true;
          timer.cancel();
        });
      } else {
        setState(() {
          if (sec == 0 && min > 0) {
            min = --min;
            sec = 60;
          } else if (sec == 0) {
            min = 0;
            sec = 60;
          }

          sec--;
        });
      }
    });
  }

  resendVerificationEmail() async {
    try {
      await APIs.auth.currentUser?.sendEmailVerification();
      snackBarContainer('Verification email sent');
      setState(() {
        canResendEmail = false;
        min = 3;
        sec = 0;
      });
      countDown();
    } catch (e) {
      snackBarContainer('Failed to resend verification email');
    }
  }

  backButtonPressed() {
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 245, 214),
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.only(left: 20.0, right: 20, top: 25),
                        child: Text(
                          "Are you Sure?",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 20.0, right: 20, top: 15),
                        child: Text(
                          "Stop the Verification Process!",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            width: 80,
                            height: 45,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color:
                                    const Color.fromARGB(255, 153, 209, 255)),
                            child: TextButton(
                                onPressed: () {
                                  return Navigator.pop(context, false);
                                },
                                child: const Center(
                                    child: Text("No",
                                        style: TextStyle(
                                            fontFamily: "Ubuntu",
                                            fontSize: 16,
                                            color: Colors.black)))),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 45,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: const Color.fromARGB(255, 255, 177, 171)),
                          child: TextButton(
                              onPressed: () async {
                                await APIs.auth.currentUser?.delete();
                                Navigator.pop(context);
                              },
                              child: const Center(
                                  child: Text("Yes",
                                      style: TextStyle(
                                          fontFamily: "Ubuntu",
                                          fontSize: 18,
                                          color: Colors.black)))),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => backButtonPressed(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 57, 50, 83),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40, top: 40),
              child: Lottie.asset("assets/animations/verification.json"),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Verify your email address",
                  style: TextStyle(color: Colors.amber, fontSize: 25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 15),
                  child: Text(
                    "${APIs.auth.currentUser?.email}",
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.0, vertical: 10),
              child: Text(
                "We have sent an Email Verification link to the above email, please confirm your email to continue.",
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0, bottom: 30),
              child: Text(
                "$min : $sec",
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: "RobotoMono",
                    fontSize: 25),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 15),
                  child: Container(
                      decoration: BoxDecoration(
                          color: canResendEmail ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12)),
                      child: TextButton(
                          onPressed:
                              canResendEmail ? resendVerificationEmail : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.rotateRight,
                                color: Colors.white,
                                size: 26,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text(
                                "Resend",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    fontFamily: "RobotoMono",
                                    color: Colors.white),
                              ),
                            ],
                          ))),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, right: 15),
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color.fromRGBO(68, 142, 245, 1),
                          borderRadius: BorderRadius.circular(12)),
                      child: TextButton(
                          onPressed: () async {
                            bool isGmailInstalled =
                                await LaunchApp.isAppInstalled(
                                    androidPackageName:
                                        'com.google.android.gm');
                            if (isGmailInstalled) {
                              await LaunchApp.openApp(
                                  androidPackageName: 'com.google.android.gm');
                            } else {
                              snackBarContainer('Gmail app is not installed.');
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.google,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text(
                                textAlign: TextAlign.center,
                                "Open Gmail",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "RobotoMono",
                                    fontSize: 17,
                                    color: Colors.white),
                              ),
                            ],
                          ))),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
