import 'package:colearn/apis.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class NavBarDrawer extends StatefulWidget {
  const NavBarDrawer({super.key});

  @override
  State<NavBarDrawer> createState() => _NavBarDrawerState();
}

class _NavBarDrawerState extends State<NavBarDrawer> {
  final userDetailsBox = GetStorage();
  double usedStorageInBytes = 0.0;

  @override
  void initState() {
    super.initState();
    calculateUsedStorage();
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
  Widget build(BuildContext context) {
    double usedStorageInMB = usedStorageInBytes / (1024 * 1024);
    double totalStorageInMB = 1024; // 1 GB in MB
    double percentageUsed = usedStorageInMB / totalStorageInMB;
    final size = MediaQuery.of(context).size;
    return Drawer(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color:
                                        const Color.fromARGB(255, 255, 204, 50),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
    );
  }
}
