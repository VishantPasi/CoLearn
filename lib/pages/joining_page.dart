// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:colearn/qr_code_scanner.dart';
import 'package:flutter/material.dart';

class JoinFolderPage extends StatefulWidget {
  const JoinFolderPage({super.key});

  @override
  _JoinFolderPageState createState() => _JoinFolderPageState();
}

class _JoinFolderPageState extends State<JoinFolderPage> {
  TextEditingController codeController = TextEditingController();
  DocumentSnapshot? folder;

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

  Future<void> joinFolder(String code) async {
    try {
      QuerySnapshot teacherSnapshot =
          await APIs.firestore.collection('Teacher').get();

      bool folderFound = false;

      for (var teacherDoc in teacherSnapshot.docs) {
        QuerySnapshot folderSnapshot = await teacherDoc.reference
            .collection('folders')
            .where('folderCode', isEqualTo: code)
            .get();

        if (folderSnapshot.docs.isNotEmpty) {
          folder = folderSnapshot.docs.first;
          folderFound = true;

          folder!.reference.update({
            'sharedWith': FieldValue.arrayUnion([APIs.auth.currentUser!.uid])
          });
          break;
        }
      }

      if (folderFound) {
        Navigator.pop(context, folder);
      } else if (codeController.text.isEmpty) {
        snackBarContainer('Enter a valid Code');
      } else {
        snackBarContainer('No folder found with this code.');
      }
    } catch (e) {
      snackBarContainer('Error joining folder: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(235, 72, 73, 148),
        foregroundColor: Colors.white,
        title: const Text(
          "Join a Folder",
          style: TextStyle(
            fontFamily: "RobotoMono",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              'To Join a Folder, Click on the "Scan QR Code" button OR enter the joining code below!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 50),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QrCodeScanner())),
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(58, 141, 255, 1),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded,
                          size: 60, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        "Scan QR Code",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "RobotoSlab",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Center(
              child: Text(
                "OR",
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: codeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  fillColor: const Color.fromARGB(85, 0, 0, 0),
                  filled: true,
                  labelText: "  Enter Joining Code",
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: "RobotoSlab",
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () => joinFolder(codeController.text),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(58, 141, 255, 1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  width: 160,
                  height: 50,
                  child: const Center(
                    child: Text(
                      "Join Folder",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
