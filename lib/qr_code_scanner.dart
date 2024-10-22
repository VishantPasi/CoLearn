// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colearn/apis.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: "QR");
  QRViewController? controller;
  String result = "";
  bool isScanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned) {
        setState(() {
          result = scanData.code!;
          isScanned = true;
        });
        joinFolder(result);
        controller.pauseCamera();
      }
    });
  }

  DocumentSnapshot? folder;

  Future<void> joinFolder(String code) async {
    try {
      QuerySnapshot teacherSnapshot =
          await FirebaseFirestore.instance.collection('Teacher').get();

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
        Navigator.pop(context);
        Navigator.pop(context, folder);
      } else {
        // Handle the case where the folder was not found
        snackBarContainer('No folder found with that code.');
        controller?.resumeCamera(); // Allow the user to scan again
      }
    } catch (e) {
      snackBarContainer('Error: ${e.toString()}');
      controller?.resumeCamera(); // Resume camera on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.amber,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            )),
      ],
    );
  }
}
