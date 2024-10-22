import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class APIs {
  //For Authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //For Firestore
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // For FirebaseStorage
  static FirebaseStorage firebaseStorage = FirebaseStorage.instance;
}
