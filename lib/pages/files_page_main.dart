// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/discuss_page.dart';
import 'package:colearn/pages/discuss_page_expanded.dart';
import 'package:colearn/pages/files_page.dart';
import 'package:colearn/pages/share_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class FilesPage extends StatefulWidget {
  final String folderName;
  final String teacherUid;
  final String folderDesc;
  final String displayName;

  const FilesPage(
      {super.key,
      required this.folderName,
      required this.teacherUid,
      required this.displayName,
      required this.folderDesc});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final userDetailsBox = GetStorage();
  String description = '';
  String displayName = '';
  String folderCode = '';
  String selectedTab = 'Files';
  Color? backgroundColor;
  double? fontSize;
  double usedStorageInBytes = 0.0;

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

  Future<void> fetchFolderDescription() async {
    try {
      // Fetch the folder document from Firestore
      DocumentSnapshot folderDoc = await APIs.firestore
          .collection(userDetailsBox.read("role"))
          .doc(APIs.auth.currentUser!.uid)
          .collection('folders')
          .doc(widget.folderName)
          .get();

      // Check if the document exists and contains the description field
      if (folderDoc.exists && folderDoc.data() != null) {
        setState(() {
          displayName = folderDoc['displayName'];
          folderCode = folderDoc['folderCode'];
          description = folderDoc['description'] ?? 'No description available';
        });
      } else {
        setState(() {
          description = 'No description available';
        });
      }
    } catch (e) {
      setState(() {
        description = 'Error fetching description';
      });
    }
  }

  Future<void> deleteFolder(String folderName) async {
    // Reference to Firebase Storage folder
    Reference folderRef = APIs.firebaseStorage
        .ref()
        .child("${APIs.auth.currentUser!.uid}/$folderName/");

    try {
      // Delete files in the folder from Firebase Storage
      ListResult result = await folderRef.listAll();
      for (Reference fileRef in result.items) {
        await fileRef.delete();
      }

      // Delete subfolders recursively
      for (Reference subFolderRef in result.prefixes) {
        await deleteFolder(subFolderRef.fullPath);
      }

      // Reference to Firestore folder document
      DocumentReference folderDocRef = APIs.firestore
          .collection('Teacher')
          .doc(APIs.auth.currentUser!.uid)
          .collection('folders')
          .doc(folderName);

      // Delete all chats related to the folder from Firestore
      QuerySnapshot chatsSnapshot =
          await folderDocRef.collection('messages').get();
      for (DocumentSnapshot chatDoc in chatsSnapshot.docs) {
        await chatDoc.reference.delete();
      }

      // Delete the Firestore folder document itself
      await folderDocRef.delete();
      Navigator.pop(context);
    } catch (e) {
      snackBarContainer('Error deleting folder and chats: $e');
    }
  }

  tabSelected() {
    switch (selectedTab) {
      case 'Files':
        return Files(
          teacherUid: widget.teacherUid,
          folderName: widget.folderName,
        );
      case 'Discuss':
        return Discuss(
          folderName: widget.folderName,
          teacherUid: widget.teacherUid,
        );
      case 'Share':
        return Share(
            teacherId: APIs.auth.currentUser!.uid,
            folderName: widget.folderName,
            folderCode: folderCode);
      default:
        return Files(
          teacherUid: widget.teacherUid,
          folderName: widget.folderName,
        );
    }
  }

  tabButton(String tab, Size size) {
    bool isSelected = selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = tab;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          width: tab == "Discuss" && isSelected ? 150 : 120,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromARGB(255, 27, 30, 68)
                : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tab,
                  style: TextStyle(
                    fontSize: isSelected ? 19 : 16,
                    color: Colors.white,
                    fontFamily: "RobotoMono",
                  ),
                ),
                if (tab == "Discuss" && isSelected) const SizedBox(width: 10),
                if (tab == "Discuss" && isSelected)
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DiscussPageExpanded(
                                    teacherUid: widget.teacherUid,
                                    folderName: widget.folderName)));
                      },
                      child: const Icon(
                        FontAwesomeIcons.upRightAndDownLeftFromCenter,
                        color: Colors.white,
                        size: 20,
                      ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> calculateUsedStorage([Reference? reference]) async {
    reference ??=
        FirebaseStorage.instance.ref().child("${APIs.auth.currentUser!.uid}/");

    try {
      // List all files in the current directory
      final ListResult result = await reference.listAll();

      // Fetch metadata for all files in parallel
      final List<Future<FullMetadata>> metadataFutures =
          result.items.map((item) => item.getMetadata()).toList();
      final List<FullMetadata> metadataList =
          await Future.wait(metadataFutures);

      // Sum up the sizes from the fetched metadata
      usedStorageInBytes +=
          metadataList.fold(0, (sum, metadata) => sum + (metadata.size ?? 0));

      // Recursively list all subdirectories and their files
      final List<Future<void>> folderFutures = result.prefixes
          .map((folder) => calculateUsedStorage(folder))
          .toList();
      await Future.wait(folderFutures);

      setState(() {});
    } catch (e) {
      snackBarContainer('Error calculating storage usage: $e');
    }
  }

  Future<void> signOut() async {
    userDetailsBox.erase();
    await APIs.auth.signOut();
  }

  @override
  void initState() {
    fetchFolderDescription();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double usedStorageInMB = usedStorageInBytes / (1024 * 1024);
    double totalStorageInMB = 1024; // 1 GB in MB
    double percentageUsed = usedStorageInMB / totalStorageInMB;

    switch (selectedTab) {
      case 'Files':
        backgroundColor = const Color.fromARGB(255, 27, 30, 68);
        fontSize = 18;

        break;
      case 'Discuss':
        backgroundColor = const Color.fromARGB(255, 27, 30, 68);
        fontSize = 18;
        break;
      case 'Share':
        backgroundColor = const Color.fromARGB(255, 27, 30, 68);
        fontSize = 18;

        break;
      default:
        backgroundColor = const Color.fromARGB(255, 27, 30, 68);
        fontSize = 18;
    }
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      body: Column(
        children: [
          Container(
            height: 260,
            width: size.width,
            decoration: BoxDecoration(
              border: Border.all(
                width: 0,
                color: const Color.fromARGB(255, 27, 30, 68),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: userDetailsBox.read("role") == "Teacher"
                    ? [
                        const Color.fromRGBO(255, 74, 100, 1),
                        const Color.fromRGBO(124, 40, 86, 1)
                      ]
                    : [
                        const Color.fromRGBO(118, 178, 255, 1),
                        const Color.fromRGBO(58, 141, 255, 1)
                      ],
                tileMode: TileMode.mirror,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.folderName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "RobotoMono",
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            userDetailsBox.read("role") == "Teacher"
                                ? IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color.fromRGBO(
                                              182, 54, 73, 1),
                                          title: const Text(
                                            'Delete Folder',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "RobotoMono"),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete directory "${widget.folderName}" ?',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: "RobotoSlab"),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: "RobotoMono",
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                                deleteFolder(widget.folderName);
                                              },
                                              child: const Text(
                                                'Yes',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: "RobotoMono",
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const FaIcon(
                                      FontAwesomeIcons.solidTrashCan,
                                      color: Colors.white,
                                    ))
                                : const Text(""),
                            const SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                onPressed: () {
                                  usedStorageInBytes = 0;
                                  calculateUsedStorage();
                                  scaffoldKey.currentState!.openEndDrawer();
                                },
                                icon: const Icon(FontAwesomeIcons.barsStaggered,
                                    color: Colors.white)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, right: 20, top: 2, bottom: 10),
                  child: Text(
                    "by ${widget.displayName}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "RobotoSlab"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, right: 20, top: 20, bottom: 10),
                  child: Text(
                    widget.folderDesc,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                    maxLines: 2,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "RobotoSlab"),
                  ),
                ),
                const Spacer(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      tabButton('Files', size),
                      tabButton('Discuss', size),
                      userDetailsBox.read("role") == "Teacher"
                          ? tabButton('Share', size)
                          : const Text(""),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(child: tabSelected()),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 27, 30, 68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: size.width,
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                            bottom: BorderSide(color: Colors.white54)),
                        color: Color.fromARGB(235, 72, 73, 148),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20.0, horizontal: 10),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.black45,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.solidUser,
                                        color: userDetailsBox.read("role") ==
                                                "Teacher"
                                            ? const Color.fromARGB(
                                                199, 255, 72, 59)
                                            : const Color.fromARGB(
                                                255, 131, 181, 255),
                                        size: 40,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userDetailsBox
                                            .read("fullName")
                                            .toString()
                                            .capitalize!,
                                        style: const TextStyle(
                                          overflow: TextOverflow.ellipsis,
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontFamily: "RobotoSlab",
                                        ),
                                      ),
                                      Text(
                                        APIs.auth.currentUser!.email.toString(),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: "RobotoSlab",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // Navigation Items
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.houseChimney,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        "Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "RobotoMono",
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.rightFromBracket,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontFamily: "RobotoMono",
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        signOut();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Divider(
                    color: Colors.white54,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  // Additional Items
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.circleInfo,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        "About",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "RobotoMono",
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 204, 50),
                                      borderRadius: BorderRadius.circular(20)),
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  height: 150,
                                  child: const Center(
                                      child: Text(
                                    textAlign: TextAlign.center,
                                    "Made by Vishant\nSEM V Project\nVersion 1.2",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "RobotoMono"),
                                  )),
                                ),
                              );
                            });
                      },
                    ),
                  ),
                ],
              ),
            ),
            userDetailsBox.read("role") == "Teacher"
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        LinearPercentIndicator(
                          percent: percentageUsed,
                          lineHeight: 8.0,
                          backgroundColor: Colors.white10,
                          progressColor: Colors.redAccent,
                          barRadius: const Radius.circular(5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${usedStorageInMB.toStringAsFixed(1)} MB of $totalStorageInMB MB",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text(""),
          ],
        ),
      ),
    );
  }
}
