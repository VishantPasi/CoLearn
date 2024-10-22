import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Share extends StatefulWidget {
  final String teacherId;
  final String folderName;
  final String folderCode;
  const Share(
      {super.key,
      required this.teacherId,
      required this.folderName,
      required this.folderCode});

  @override
  State<Share> createState() => _ShareState();
}

class _ShareState extends State<Share> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 30, 68),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "To share this folder, either scan the QR code or use the joining code below!",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(
              height: 80,
            ),
            Center(
              child: Container(
                height: 185,
                width: 180,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 5.0, right: 5, top: 7, bottom: 5),
                  child: QrImageView(
                    data: widget.folderCode,
                    version: QrVersions.auto,
                    gapless: false,
                    dataModuleStyle: const QrDataModuleStyle(
                        color: Color.fromARGB(255, 27, 30, 68),
                        dataModuleShape: QrDataModuleShape.circle),
                    eyeStyle: const QrEyeStyle(
                        color: Color.fromARGB(255, 27, 30, 68),
                        eyeShape: QrEyeShape.square),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Joining Code: ${widget.folderCode}",
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontFamily: "RobotoSlab"),
            ),
          ],
        ));
  }
}
