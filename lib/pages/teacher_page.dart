// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/pages/files_page_main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/create_directory_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final StreamController<Map<String, String>> foldersStreamController =
      StreamController<Map<String, String>>();

  @override
  void initState() {
    super.initState();
    updateFolderList();
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

  Future<void> updateFolderList() async {
    try {
      ListResult result = await APIs.firebaseStorage
          .ref()
          .child("${APIs.auth.currentUser!.uid}/")
          .listAll();

      List<String> folderNames =
          result.prefixes.map((prefix) => prefix.name).toList();

      // Fetch descriptions from Firestore
      final firestore = FirebaseFirestore.instance;
      final folderDescriptions =
          <String, String>{}; // Map to hold folder names and descriptions

      for (var folderName in folderNames) {
        DocumentSnapshot doc = await firestore
            .collection('Teacher')
            .doc(APIs.auth.currentUser!.uid)
            .collection("folders")
            .doc(folderName)
            .get();
        if (doc.exists) {
          folderDescriptions[folderName] =
              doc['description'] ?? 'No description available';
        } else {
          folderDescriptions[folderName] = 'No description available';
        }
      }

      foldersStreamController.add(folderDescriptions);
    } catch (e) {
      snackBarContainer('Error updating folder list: $e');
    }
  }

  Future<void> onRefresh() async {
    await updateFolderList();
  }

  @override
  void dispose() {
    foldersStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RefreshIndicator(
      onRefresh: () => onRefresh(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 30, 68),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<Map<String, String>>(
                stream: foldersStreamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SizedBox(
                        height:
                            size.height, // Provide enough space for scrolling
                        child: Padding(
                          padding: const EdgeInsets.all(60.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/no_data_found.png",
                                ),
                                const Text(
                                  "Empty Directory",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "RobotoMono",
                                      fontSize: 18),
                                )
                              ],
                            ),
                          ),
                        ));
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListView(
                        children: snapshot.data!.entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final doc = await APIs.firestore
                                          .collection('Teacher')
                                          .doc(APIs.auth.currentUser!.uid)
                                          .collection("folders")
                                          .doc(entry.key)
                                          .get();

                                      if (doc.exists) {
                                        final displayName = doc['displayName'];
                                        final description = doc['description'];

                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FilesPage(
                                              folderName: entry.key,
                                              teacherUid:
                                                  APIs.auth.currentUser!.uid,
                                              folderDesc: description,
                                              displayName: displayName,
                                            ),
                                          ),
                                        );
                                        updateFolderList();
                                      }
                                    },
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color.fromRGBO(216, 62, 85, 1),
                                            Color.fromRGBO(124, 40, 86, 1)
                                          ],
                                          tileMode: TileMode.mirror,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 30.0),
                                                      child: Text(
                                                        entry.key,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              "RobotoMono",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    FontAwesomeIcons
                                                        .solidFolderClosed,
                                                    size: 30,
                                                    color: Color.fromARGB(
                                                        255, 255, 224, 131),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 25,
                                              ),
                                              Text(
                                                entry.value,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "RobotoSlab",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateDirectory()),
            );
            updateFolderList(); // Update the list after returning
          },
          backgroundColor: const Color.fromARGB(235, 72, 73, 148),
          child: const Icon(
            Icons.add,
            color: Color.fromARGB(255, 255, 224, 131),
            size: 30,
          ),
        ),
      ),
    );
  }
}
