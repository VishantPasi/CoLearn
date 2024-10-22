// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/files_page_main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/pages/joining_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  List<DocumentSnapshot> folders = [];
  bool isLoading = true; // Add this variable
  DocumentSnapshot? folder;

  @override
  void initState() {
    super.initState();
    fetchJoinedFolders(); // Fetch folders when the page is initialized
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

  Future<void> fetchJoinedFolders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Student') // Replace with your collection name
          .doc(
              APIs.auth.currentUser!.uid) // Assuming you have the UID available
          .collection('JoinedFolders') // Subcollection name
          .get();

      List<DocumentSnapshot> fetchedFolders = snapshot.docs;
      setState(() {
        folders = fetchedFolders;
        isLoading = false; // Update loading state
      });
    } catch (e) {
      snackBarContainer('Error fetching folders: ${e.toString()}');
      setState(() {
        isLoading = false; // Update loading state in case of error
      });
    }
  }

  Future<void> onRefresh() async {
    await fetchJoinedFolders();
  }

  void addFolder(DocumentSnapshot folder) async {
    // Check if the folder is already in the list
    bool folderExists = folders.any((existingFolder) =>
        existingFolder['folderCode'] == folder['folderCode']);

    if (!folderExists) {
      setState(() {
        folders.add(folder);
      });

      // Update Firestore with the joined folder
      try {
        await FirebaseFirestore.instance
            .collection('Student') // Replace with your collection name
            .doc(APIs
                .auth.currentUser!.uid) // Assuming you have the UID available
            .collection('JoinedFolders') // Subcollection name
            .doc(folder[
                "folderName"]) // Use folder code or another unique identifier
            .set({
          'folderName': folder['folderName'],
          'folderCode': folder['folderCode'],
          'teacherUid': folder['teacherUid'],
          "description": folder['description'],
          "displayName": folder['displayName']
        });
      } catch (e) {
        snackBarContainer('Error updating Firestore: ${e.toString()}');
      }
    } else {
      snackBarContainer('Folder is already joined.');
    }
  }

  Future<void> removeUserfromFolder(String code) async {
    try {
      QuerySnapshot teacherSnapshot =
          await FirebaseFirestore.instance.collection('Teacher').get();

      for (var teacherDoc in teacherSnapshot.docs) {
        QuerySnapshot folderSnapshot = await teacherDoc.reference
            .collection('folders')
            .where('folderCode', isEqualTo: code)
            .get();

        if (folderSnapshot.docs.isNotEmpty) {
          folder = folderSnapshot.docs.first;

          // Remove the current user's UID from the 'sharedWith' field
          folder!.reference.update({
            'sharedWith': FieldValue.arrayRemove([APIs.auth.currentUser!.uid])
          });

          break;
        }
      }
    } catch (e) {
      snackBarContainer('Error removing from folder: ${e.toString()}');
    }
  }

  Future<void> unEnrollFolder(DocumentSnapshot folder) async {
    try {
      // Remove the folder from Firestore
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(APIs.auth.currentUser!.uid)
          .collection('JoinedFolders')
          .doc(folder[
              "folderName"]) // Assuming 'folder.id' is the document ID in Firestore
          .delete();

      // Remove the folder from the local list
      setState(() {
        folders.remove(folder);
      });
      await removeUserfromFolder(folder["folderCode"]);
      snackBarContainer('Folder unenrolled successfully');
    } catch (e) {
      snackBarContainer('Error unenrolling folder: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      body: RefreshIndicator(
          onRefresh: onRefresh, // Trigger the refresh function
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator()) // Show loading indicator
              : folders.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FilesPage(
                                          folderName: folder["folderName"],
                                          teacherUid: folder["teacherUid"],
                                          folderDesc: folder["description"],
                                          displayName: folder["displayName"],
                                        ))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromRGBO(118, 178, 255, 1),
                                      Color.fromRGBO(58, 141, 255, 1)
                                    ],
                                    tileMode: TileMode.mirror,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 30.0),
                                                child: Text(
                                                  folder["folderName"],
                                                  style: const TextStyle(
                                                      fontFamily: "RobotoMono",
                                                      color: Color.fromARGB(
                                                          223, 255, 255, 255),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 22),
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton(
                                              color: const Color.fromRGBO(
                                                  138, 186, 252, 1),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              onSelected: (value) {
                                                if (value == 'unenroll') {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      backgroundColor:
                                                          const Color.fromRGBO(
                                                              58, 141, 255, 1),
                                                      title: const Text(
                                                        'Delete File',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                "RobotoMono"),
                                                      ),
                                                      content: Text(
                                                        'Are you sure you want to unenroll ${folder["folderName"]} ?',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                "RobotoSlab"),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    "RobotoMono",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            unEnrollFolder(
                                                                folder);
                                                          },
                                                          child: const Text(
                                                              'Yes',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      "RobotoMono",
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                FontAwesomeIcons
                                                    .ellipsisVertical,
                                                size: 25,
                                                color: Color.fromARGB(
                                                    223, 255, 255, 255),
                                              ),
                                              itemBuilder:
                                                  (BuildContext context) {
                                                return [
                                                  PopupMenuItem(
                                                    height: 30,
                                                    value: 'unenroll',
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical:
                                                              5.0), // Adjust vertical padding
                                                      child: const Center(
                                                          child: Text(
                                                        'Unenroll',
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                "RobotoMono"),
                                                      )),
                                                    ),
                                                  ),
                                                ];
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Text(
                                          folder["description"],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontFamily: "RobotoSlab",
                                              color: Color.fromARGB(
                                                  223, 255, 255, 255),
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/no_data_found.png",
                            ),
                            const Text(
                              "No Folders Found!",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "RobotoMono",
                                  fontSize: 18),
                            )
                          ],
                        ),
                      ),
                    )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the JoinFolderPage and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JoinFolderPage()),
          );

          // If the result is not null, add the folder to the list
          if (result != null) {
            addFolder(result as DocumentSnapshot);
            setState(() {});
          }
        },
        backgroundColor: const Color.fromARGB(235, 72, 73, 148),
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 255, 224, 131),
          size: 30,
        ),
      ),
    );
  }
}
