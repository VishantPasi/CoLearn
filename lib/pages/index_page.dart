import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:colearn/pages/Teacher_page.dart';
import 'package:colearn/pages/nav_bar_drawer.dart';
import 'package:colearn/pages/student_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _StudentState();
}

class _StudentState extends State<IndexPage> {
  final userDetailsBox = GetStorage();
  String? fullName;
  String? role;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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

  @override
  void initState() {
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        endDrawer: const NavBarDrawer(),
        backgroundColor: const Color.fromARGB(255, 27, 30, 68),
        appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20))),
            backgroundColor: const Color.fromARGB(235, 72, 73, 148),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                    onPressed: () {
                      scaffoldKey.currentState!.openEndDrawer();
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.barsStaggered,
                      color: Color.fromARGB(255, 255, 224, 131),
                    )),
              )
            ],
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(137, 255, 255, 255),
                                  width: 2),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(50)),
                              color: const Color.fromARGB(120, 0, 0, 0)),
                          child: Center(
                              child: FaIcon(FontAwesomeIcons.solidUser,
                                  size: 20,
                                  color: userDetailsBox.read("role") ==
                                          "Teacher"
                                      ? const Color.fromARGB(199, 255, 72, 59)
                                      : const Color.fromARGB(
                                          255, 131, 181, 255))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 180,
                            child: Text(
                              userDetailsBox
                                      .read("fullName")
                                      .toString()
                                      .capitalize ??
                                  fullName.toString().capitalize!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontFamily: "RobotoSlab"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        body: (userDetailsBox.read("fullName") == null || fullName == null)
            ? const Center(child: CircularProgressIndicator())
            : (role == "Teacher" ? const TeacherPage() : const StudentPage()));
  }
}
