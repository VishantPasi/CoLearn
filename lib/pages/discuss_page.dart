// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';

class Discuss extends StatefulWidget {
  final String folderName;
  final String teacherUid;
  const Discuss(
      {super.key, required this.teacherUid, required this.folderName});

  @override
  _DiscussState createState() => _DiscussState();
}

class _DiscussState extends State<Discuss> {
  final GlobalKey<ScaffoldState> scaffoldkey3 = GlobalKey<ScaffoldState>();
  TextEditingController messageController = TextEditingController();
  final userDetailsBox = GetStorage();
  String date = '';
  DocumentSnapshot? folder;
  String fullName = '';
  String email = '';
  String role = '';
  Color? color;

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

  Future<void> sendMessage(String message, String senderRole) async {
    User? currentUser = APIs.auth.currentUser;
    if (currentUser == null) {
      // Handle not signed-in user
      return;
    }

    await FirebaseFirestore.instance
        .collection('Teacher')
        .doc(widget.teacherUid)
        .collection('folders')
        .doc(widget.folderName)
        .collection("messages")
        .add({
      'senderId': currentUser.uid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderRole': senderRole,
      "email": APIs.auth.currentUser!.email,
      "fullName": userDetailsBox.read("fullName")
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'; // Format to HH:mm
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();

    switch (dateTime.month) {
      case 1:
        date = "${dateTime.day} Jan ${dateTime.year}";
        break;
      case 2:
        date = "${dateTime.day} Feb ${dateTime.year}";
        break;
      case 3:
        date = "${dateTime.day} Mar ${dateTime.year}";
        break;
      case 4:
        date = "${dateTime.day} Apr ${dateTime.year}";
        break;
      case 5:
        date = "${dateTime.day} May ${dateTime.year}";
        break;
      case 6:
        date = "${dateTime.day} Jun ${dateTime.year}";
        break;
      case 7:
        date = "${dateTime.day} Jul ${dateTime.year}";
        break;
      case 8:
        date = "${dateTime.day} Aug ${dateTime.year}";
        break;
      case 9:
        date = "${dateTime.day} Sep ${dateTime.year}";
        break;
      case 10:
        date = "${dateTime.day} Oct ${dateTime.year}";
        break;
      case 11:
        date = "${dateTime.day} Nov ${dateTime.year}";
        break;
      case 12:
        date = "${dateTime.day} Dec ${dateTime.year}";
        break;
    }

    return date; // Format to DD/MMM/YYYY
  }

  Color generateColorFromId(String senderId) {
    final int hash = senderId.hashCode;
    final Random random = Random(hash);
    return Color.fromARGB(
      255, // Opacity (fully opaque)
      100 + random.nextInt(155), // Red
      100 + random.nextInt(155), // Green
      100 + random.nextInt(155), // Blue
    );
  }

  Future<Map<String, dynamic>?> fetchUserDetails(String senderId) async {
    try {
      // Try fetching from the 'Teacher' collection first
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('Teacher')
              .doc(senderId)
              .get();

      if (userSnapshot.exists) {
        setState(() {
          color = const Color.fromARGB(255, 253, 120, 111);
        });

        return userSnapshot.data();
      }

      // If not found, try fetching from the 'Student' collection
      userSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .doc(senderId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          final userIconColor = generateColorFromId(senderId);
          color = userIconColor;
        });

        return userSnapshot.data();
      }

      // If still not found, return null
      return null;
    } catch (e) {
      snackBarContainer("Error fetching user details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldkey3,
      backgroundColor: const Color.fromARGB(255, 27, 30, 68),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.firestore
                    .collection('Teacher')
                    .doc(widget.teacherUid)
                    .collection('folders')
                    .doc(widget.folderName)
                    .collection("messages")
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var messages = snapshot.data!.docs;
                  if (messages.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var messageData = messages[index];
                          bool isMe = messageData['senderId'] ==
                              FirebaseAuth.instance.currentUser!.uid;
                          String? previousMessageDate;

                          String currentMessageDate =
                              formatDate(messageData["timestamp"]);
                          if (index + 1 < messages.length) {
                            var previousMessageData = messages[index + 1];
                            previousMessageDate =
                                formatDate(previousMessageData["timestamp"]);
                          }

                          bool shouldShowDate =
                              currentMessageDate != previousMessageDate;
                          Color userIconColor =
                              generateColorFromId(messageData['senderId']);
                          return ListTile(
                            contentPadding: isMe
                                ? const EdgeInsets.only(right: 10)
                                : const EdgeInsets.only(left: 10),
                            title: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (shouldShowDate)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: Text(
                                          formatDate(messageData["timestamp"]),
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  200, 255, 255, 255),
                                              fontFamily: "Ubuntu"),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        String senderId =
                                            messageData['senderId'];
                                        Map<String, dynamic>? userDetails =
                                            await fetchUserDetails(senderId);

                                        if (userDetails != null) {
                                          setState(() {
                                            fullName =
                                                userDetails['full_name'] ??
                                                    'Unknown';
                                            email = userDetails['email'] ??
                                                'Unknown';
                                            role = userDetails['role'] ??
                                                'Unknown';
                                          });
                                        }

                                        scaffoldkey3.currentState!
                                            .openEndDrawer();
                                      },
                                      child: Container(
                                        height: 25,
                                        width: 25,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black, width: 1),
                                          color: messageData["senderRole"] ==
                                                  "Teacher"
                                              ? const Color.fromARGB(
                                                  255, 253, 120, 111)
                                              : userIconColor,
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                        child: Align(
                                          alignment: isMe
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: const Center(
                                              child: Icon(
                                                  FontAwesomeIcons.solidUser,
                                                  size: 12,
                                                  color: Color.fromARGB(
                                                      193, 0, 0, 0))),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: isMe
                                        ? const EdgeInsets.only(
                                            left: 70, right: 3)
                                        : const EdgeInsets.only(
                                            right: 70, left: 3),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color.fromRGBO(
                                              221, 238, 255, 1.0)
                                          : const Color.fromARGB(
                                              48, 209, 209, 209),
                                      borderRadius: isMe
                                          ? const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                              topRight: Radius.circular(4))
                                          : const BorderRadius.only(
                                              topRight: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                              topLeft: Radius.circular(6)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: Text(
                                            messageData['message'],
                                            style: TextStyle(
                                                color: isMe
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontFamily: "Ubuntu"),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: Text(
                                            messageData['timestamp'] != null
                                                ? formatTimestamp(
                                                    messageData['timestamp'])
                                                : '', // Display the timestamp
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.black
                                                  : Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/no_messages.png',
                          width: 150,
                        ),
                        const Text(
                          "No Messages!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: "RobotoMono"),
                        )
                      ],
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16, top: 0, bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: '  Enter your message...',
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontFamily: "Ubuntu"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(85, 0, 0, 0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, size: 30, color: Colors.white),
                    onPressed: () {
                      if (messageController.text.isNotEmpty) {
                        sendMessage(
                          messageController.text,
                          userDetailsBox.read(
                              "role"), // Assuming students are sending messages
                        );
                        messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        backgroundColor: const Color.fromARGB(244, 72, 73, 148),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                        color: const Color.fromARGB(199, 0, 0, 0), width: 5),
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.solidUser,
                    size: 40,
                    color: Color.fromARGB(199, 0, 0, 0),
                  )),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  "Name:",
                  style: TextStyle(
                      color: Color.fromARGB(185, 255, 255, 255),
                      fontSize: 16,
                      fontFamily: "RobotoMono"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  fullName.capitalize!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  "Email:",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Color.fromARGB(185, 255, 255, 255),
                      fontSize: 16,
                      fontFamily: "RobotoMono"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  "Role:",
                  style: TextStyle(
                      color: Color.fromARGB(185, 255, 255, 255),
                      fontSize: 16,
                      fontFamily: "RobotoMono"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0, left: 8, right: 8),
                child: Text(
                  role,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
