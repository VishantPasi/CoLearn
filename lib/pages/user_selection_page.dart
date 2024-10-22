import 'package:colearn/pages/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';

class UserSelectionPage extends StatelessWidget {
  const UserSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userDetailsBox = GetStorage();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 43, 94),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80.0, bottom: 50),
            child: Lottie.asset("assets/animations/Selection.json"),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              "Welcome!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 30, bottom: 30),
            child: Text(
              "Please Select Your Role",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    userDetailsBox.write("role", "Student");
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SignUpPage(
                              role: "Student",
                            )));
                  },
                  child: Container(
                    width: 130,
                    height: 170,
                    decoration: BoxDecoration(
                        color: const Color.fromRGBO(236, 225, 239, 1),
                        borderRadius: BorderRadius.circular(30)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 25.0),
                          child: Image.asset(
                            "assets/images/Student_icon.png",
                            width: 90,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            "Student",
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    userDetailsBox.write("role", "Teacher");
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SignUpPage(
                              role: "Teacher",
                            )));
                  },
                  child: Container(
                    width: 130,
                    height: 170,
                    decoration: BoxDecoration(
                        color: const Color.fromRGBO(236, 225, 239, 1),
                        borderRadius: BorderRadius.circular(30)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Image.asset("assets/images/Teacher_icon.png",
                              width: 100),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text("Teacher",
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
