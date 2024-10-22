// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/user_selection_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidden = true;
  bool loading = false;
  late KeyboardVisibilityController keyboardVisibilityController;
  late StreamSubscription<bool> keyboardVisibilitySubscription;
  bool isKeyboardVisible = false;
  final TextEditingController userEmail = TextEditingController();
  final TextEditingController userPassword = TextEditingController();
  final userDetailsBox = GetStorage();

  Widget isSecured() {
    return GestureDetector(
      onTap: () {
        setState(() {
          hidden = !hidden;
        });
      },
      child: hidden
          ? const FaIcon(
              FontAwesomeIcons.solidEye,
              color: Colors.white,
            )
          : const FaIcon(
              FontAwesomeIcons.solidEyeSlash,
              color: Colors.white,
            ),
    );
  }

  snackBarContainer(snackBarText) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        backgroundColor: const Color.fromARGB(255, 190, 13, 0),
        dismissDirection: DismissDirection.down,
        duration: const Duration(seconds: 3),
        content: Center(
          child: Text(snackBarText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 19)),
        )));
  }

  Future signIn() async {
    setState(() {
      loading = true;
    });
    try {
      await APIs.auth.signInWithEmailAndPassword(
          email: userEmail.text.toLowerCase().trim(),
          password: userPassword.text.trim());
      setState(() {
        loading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email") {
        snackBarContainer("Enter a Valid Email-ID");
        setState(() {
          loading = false;
        });
      } else if (e.code == "invalid-credential") {
        snackBarContainer("Invalid Email/Password");
        setState(() {
          loading = false;
        });
      } else {
        snackBarContainer("${e.code.toUpperCase()} : ${e.message}");
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    keyboardVisibilityController = KeyboardVisibilityController();
    isKeyboardVisible = keyboardVisibilityController.isVisible;

    keyboardVisibilitySubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        isKeyboardVisible = visible;
      });
    });
  }

  @override
  void dispose() {
    keyboardVisibilitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 57, 50, 83),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 30.0),
                      child: Lottie.asset("assets/animations/Login.json"),
                    )),
                    AnimatedPadding(
                      curve: Curves.easeInOutBack,
                      duration: const Duration(milliseconds: 600),
                      padding:
                          EdgeInsets.only(top: isKeyboardVisible ? 60 : 340),
                      child: Container(
                        height: size.height,
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(45),
                                topRight: Radius.circular(45)),
                            color: Colors.white),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: GestureDetector(
                                    onVerticalDragEnd: (details) {
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.white),
                                      width: 150,
                                      height: 30,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 67, 59, 95),
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          height: 6,
                                          width: 80,
                                        ),
                                      ),
                                    ))),
                            const Padding(
                              padding: EdgeInsets.only(left: 25.0),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: "Ubuntu",
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 10),
                              child: Text(
                                "Please Sign-in to continue",
                                style: TextStyle(
                                    fontSize: 19, fontFamily: "Ubuntu"),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 10),
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        const Color.fromARGB(255, 67, 59, 95),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  height: 60,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: userEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                          fontFamily: "Ubuntu"),
                                      cursorColor: Colors.white,
                                      decoration: const InputDecoration(
                                          prefixIcon: Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: FaIcon(
                                              FontAwesomeIcons.solidEnvelope,
                                              size: 25,
                                            ),
                                          ),
                                          prefixIconColor: Colors.white,
                                          hintText: "Email",
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                              fontFamily: "Ubuntu",
                                              color: Color.fromARGB(
                                                  204, 255, 255, 255))),
                                    ),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 10),
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        const Color.fromARGB(255, 67, 59, 95),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  height: 60,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: userPassword,
                                      obscureText: hidden,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                          fontFamily: "Ubuntu"),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                          prefixIcon: const Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: FaIcon(
                                              FontAwesomeIcons.lock,
                                              size: 25,
                                            ),
                                          ),
                                          prefixIconColor: Colors.white,
                                          hintText: "Password",
                                          suffixIcon: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: isSecured()),
                                          border: InputBorder.none,
                                          hintStyle: const TextStyle(
                                              fontFamily: "Ubuntu",
                                              color: Color.fromARGB(
                                                  204, 255, 255, 255))),
                                    ),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 30,
                                bottom: 15.0,
                              ),
                              child: Center(
                                child: Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 196, 54, 54),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: TextButton(
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          if (userEmail.text.isEmpty) {
                                            snackBarContainer(
                                                "Enter a Valid Email-ID");
                                          } else if (userPassword
                                              .text.isEmpty) {
                                            snackBarContainer(
                                                "Password is Required");
                                          } else {
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 100), () {
                                              signIn();
                                            });
                                          }
                                        },
                                        child: const Text(
                                          "Sign-In",
                                          style: TextStyle(
                                              fontFamily: "Ubuntu",
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 20),
                                        ))),
                              ),
                            ),
                            Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an Account? ",
                                  style: TextStyle(
                                      fontFamily: "Ubuntu", fontSize: 16),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UserSelectionPage())),
                                  child: const Text(
                                    "Sign up",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 156, 0),
                                        fontFamily: "Ubuntu",
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ))
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
