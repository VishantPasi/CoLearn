// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';

class CreateDirectory extends StatefulWidget {
  const CreateDirectory({super.key});

  @override
  State<CreateDirectory> createState() => _CreateDirectoryState();
}

class _CreateDirectoryState extends State<CreateDirectory> {
  final TextEditingController folderNameController = TextEditingController();
  final TextEditingController createdByController = TextEditingController();
  final TextEditingController folderDescriptionController =
      TextEditingController();
  final userDetailsBox = GetStorage();
  String generatedCode = '';
  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    generateCode();
  }

  void generateCode() {
    setState(() {
      generatedCode = generateUniqueCode();
    });
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

  String generateUniqueCode({int length = 6}) {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future folderExists(String folderName) async {
    try {
      QuerySnapshot querySnapshot = await APIs.firestore
          .collection('Teacher')
          .doc(APIs.auth.currentUser!.uid)
          .collection("folders")
          .where('folderName', isEqualTo: folderName)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      snackBarContainer('Error checking folder existence: $e');
      return false;
    }
  }

  Future createFolder(String folderName) async {
    if (await folderExists(folderName)) {
      snackBarContainer('Folder with this name already exists.');
      return;
    }

    // To create a folder, you can upload a placeholder file or metadata
    Reference folderRef = APIs.firebaseStorage
        .ref()
        .child("${APIs.auth.currentUser!.uid}/$folderName/description.txt");

    await folderRef
        .putString('This is a Description for the folder $folderName');

    await addFolder(folderName);
  }

  Future addFolder(String folderName) async {
    try {
      await APIs.firestore
          .collection('Teacher')
          .doc(APIs.auth.currentUser!.uid)
          .collection("folders")
          .doc(folderName)
          .set({
        "folderName": folderName,
        "folderCode": generatedCode,
        "displayName": (createdByController.text.isEmpty
            ? userDetailsBox.read("fullName").toString().capitalize
            : createdByController.text),
        "description": folderDescriptionController.text,
        "teacherUid": APIs.auth.currentUser!.uid,
        "sharedWith": [],
      });
      snackBarContainer('Folder created successfully.');
    } catch (e) {
      snackBarContainer('Error: $e');
    } finally {
      setState(() {
        isButtonDisabled = false; // Re-enable the button after completion
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(235, 72, 73, 148),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Create Folder',
          style: TextStyle(fontFamily: "RobotoMono"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Enter folder Details: ",
                  style: TextStyle(
                      fontSize: 20,
                      color: Color.fromRGBO(255, 73, 100, 1),
                      fontFamily: "RobotoMono"),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              TextField(
                controller: folderNameController,
                cursorColor: const Color.fromRGBO(255, 73, 100, 1),
                style: const TextStyle(
                    color: Colors.white, fontFamily: "RobotoSlab"),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    FontAwesomeIcons.solidFolderClosed,
                    color: Color.fromRGBO(255, 73, 100, 1),
                  ),
                  fillColor: Color.fromARGB(
                      120, 72, 73, 148), // Set the background color here
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  labelText: 'Folder Name',
                  labelStyle:
                      TextStyle(color: Colors.white, fontFamily: "RobotoSlab"),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                cursorColor: const Color.fromRGBO(255, 73, 100, 1),
                style: const TextStyle(
                    color: Colors.white, fontFamily: "RobotoSlab"),
                controller: createdByController,
                decoration: const InputDecoration(
                    fillColor: Color.fromARGB(
                        120, 72, 73, 148), // Set the background color here
                    filled: true,
                    prefixIcon: Icon(
                      FontAwesomeIcons.solidUser,
                      color: Color.fromRGBO(255, 73, 100, 1),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    labelText: 'Display Name (Optional)',
                    labelStyle: TextStyle(
                        color: Colors.white, fontFamily: "RobotoSlab")),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                cursorColor: const Color.fromRGBO(255, 73, 100, 1),
                minLines: 3,
                maxLines: 5,
                maxLength: 60,
                style: const TextStyle(
                    color: Colors.white, fontFamily: "RobotoSlab"),
                controller: folderDescriptionController,
                decoration: const InputDecoration(
                  fillColor: Color.fromARGB(
                      120, 72, 73, 148), // Set the background color here
                  filled: true,
                  counterStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  hintText: 'description (Optional)',
                  hintStyle: TextStyle(
                      color: Color.fromARGB(255, 160, 160, 160),
                      fontFamily: "RobotoSlab"),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null // Disable button when flag is true
                    : () async {
                        if (folderNameController.text.isNotEmpty) {
                          setState(() {
                            isButtonDisabled = true; // Disable the button
                          });
                          await createFolder(folderNameController.text);
                          setState(() {});
                          Navigator.pop(context);
                        }
                      },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.disabled)) {
                        return const Color.fromARGB(
                            122, 255, 255, 255); // Set color when disabled
                      }
                      return const Color.fromRGBO(255, 73, 100, 1);
                    },
                  ),
                ),
                child: const Text(
                  'Create Folder',
                  style: TextStyle(
                      fontFamily: "Ubuntu", fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
