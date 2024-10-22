// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/index_page.dart';
import 'package:colearn/verification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  final userDetailsBox = GetStorage();
  String? fullName;
  String? role;

  Future fetchData() async {
    try {
      final collections = ['Student', 'Teacher'];

      for (String collection in collections) {
        final querySnapshot = await APIs.firestore
            .collection(collection)
            .where('email', isEqualTo: APIs.auth.currentUser!.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final DocumentSnapshot doc = querySnapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          userDetailsBox.write("fullName", data["full_name"]);
          userDetailsBox.write("email", data["email"]);
          userDetailsBox.write("role", data["role"]);
          userDetailsBox.write("sharedWith", data["sharedWith"]);

          setState(() {
            fullName = data["full_name"];
            role = data["role"];
          });

          break;
        }
      }
    } catch (e) {
      snackBarContainer("Error fetching user data: $e");
    }
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

  @override
  void initState() {
    super.initState();

    isEmailVerified = APIs.auth.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();
    }
  }

  Future sendVerificationEmail() async {
    try {
      final user = APIs.auth.currentUser!;
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code != "too-many-requests") {
        snackBarContainer(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      isEmailVerified ? const IndexPage() : const Verification();
}
