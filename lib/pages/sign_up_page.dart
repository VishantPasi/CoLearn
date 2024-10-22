// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';

class SignUpPage extends StatefulWidget {
  final String role;
  const SignUpPage({super.key, required this.role});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController fullName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  late Timer timer;
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

  Future signUp() async {
    try {
      showDialog(
          context: context,
          builder: (context) {
            return const Center(child: CircularProgressIndicator());
          });

      await APIs.auth.createUserWithEmailAndPassword(
          email: email.text.toLowerCase().trim(),
          password: confirmPassword.text.trim());

      userDetailsBox.write('fullName', fullName.text.trim());
      userDetailsBox.write('email', email.text.trim());
      userDetailsBox.write('role', widget.role);

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      if (e.code == "invalid-email") {
        snackBarContainer("Enter a Valid Email-ID");
      } else {
        snackBarContainer(e.message);
      }
    }
  }

  textFieldContainer(hintTextData, iconData, textController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 13),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color.fromARGB(255, 80, 71, 114),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          height: 60,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: textController,
              style: const TextStyle(
                  fontSize: 17, color: Colors.white, fontFamily: "Ubuntu"),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: FaIcon(
                      iconData,
                      size: 25,
                    ),
                  ),
                  prefixIconColor: Colors.white,
                  hintText: hintTextData,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                      fontFamily: "Ubuntu",
                      color: Color.fromARGB(204, 255, 255, 255))),
            ),
          )),
    );
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userRole = widget.role;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 57, 50, 83),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 70, bottom: 10),
              child: Center(
                  child: Text(
                "Sign Up",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              )),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
              child: Center(
                  child: Text(
                "Create your account",
                style: TextStyle(color: Colors.white, fontSize: 23),
              )),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.solidUser,
                    color: Color.fromARGB(255, 226, 99, 99),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    userRole,
                    style: const TextStyle(color: Colors.amber, fontSize: 23),
                  ),
                ],
              )),
            ),
            textFieldContainer(
                "Full Name", FontAwesomeIcons.solidUser, fullName),
            textFieldContainer("Email", FontAwesomeIcons.solidEnvelope, email),
            textFieldContainer("Password", FontAwesomeIcons.lock, password),
            textFieldContainer(
                "Confirm Password", FontAwesomeIcons.key, confirmPassword),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 196, 54, 54),
                      borderRadius: BorderRadius.circular(20)),
                  child: TextButton(
                      onPressed: () {
                        if (fullName.text.isEmpty &&
                            email.text.isEmpty &&
                            password.text.isEmpty &&
                            confirmPassword.text.isEmpty) {
                          snackBarContainer("Please Fill in the Details");
                        } else if (fullName.text.isEmpty) {
                          snackBarContainer("Name cannot be empty!");
                        } else if (email.text.isEmpty) {
                          snackBarContainer("Email cannot be empty!");
                        } else if (password.text.isEmpty) {
                          snackBarContainer("Password cannot be empty!");
                        } else if (confirmPassword.text.isEmpty) {
                          snackBarContainer(
                              "Confirm Password cannot be empty!");
                        } else if (password.text != confirmPassword.text) {
                          snackBarContainer(
                              "The password and confirmation do not match!");
                        } else {
                          signUp();
                        }
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Ubuntu",
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ))),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white, fontSize: 19),
                  ),
                  GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage())),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                            color: Color.fromARGB(255, 15, 182, 15),
                            fontSize: 19,
                            fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
