import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Point central Firebase — à importer partout dans l'app
// Equivalent de firebase.js en React

final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
final storage = FirebaseStorage.instance;
