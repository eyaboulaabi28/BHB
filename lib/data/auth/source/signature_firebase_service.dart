
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_bhb/data/auth/models/ElectronicSignatureModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


abstract class SignatureFirebaseService {
  Future<void> addSignature(ElectronicSignatureModel model);
}


class SignatureFirebaseServiceImpl extends SignatureFirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  Future<void> addSignature(ElectronicSignatureModel model) async {
    // Générer un nom unique pour le fichier
    final fileName = "signatures/${DateTime.now().millisecondsSinceEpoch}.png";

    // Convertir Base64 en Uint8List si nécessaire
    final Uint8List bytes = base64Decode(model.signatureImage!);

    // Uploader dans Firebase Storage
    final ref = storage.ref().child(fileName);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));

    // Récupérer l'URL de téléchargement
    final downloadUrl = await ref.getDownloadURL();

    // Enregistrer dans Firestore
    final docRef = firestore.collection("electronic_signatures").doc();
    await docRef.set({
      'id': docRef.id,
      'userId': model.userId,
      'signatureImageUrl': downloadUrl, // ⚡ URL au lieu de Base64
      'createdAt': model.createdAt?.toIso8601String(),
    });
  }
}
