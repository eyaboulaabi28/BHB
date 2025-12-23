import 'package:app_bhb/data/auth/models/attachments_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class AttachmentsFirebaseService {
  Future<Either<String, String>> addAttachment(Attachments attachment);
  Future<Either<String, List<Attachments>>> getAllAttachments();
  Future<Either<String, String>> updateAttachment(String id, Attachments attachment);
  Future<Either<String, String>> deleteAttachment(String id);
  Future<Either<String, List<Attachments>>> getAttachmentsByProjectId(String projectId);
}

class AttachmentsFirebaseServiceImpl extends AttachmentsFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<String, String>> addAttachment(Attachments attachment) async {
    try {
      await _firestore.collection('Attachments').add(attachment.toMap());
      return const Right('Attachment added successfully');
    } catch (e) {
      return Left('Error adding attachment: $e');
    }
  }

  Future<Either<String, String>> deleteAttachment(String id) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('Attachments').doc(id);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return Left("Attachment introuvable");

      final attachment = Attachments.fromMap(docSnapshot.id, docSnapshot.data()!);

      if (attachment.fileUrl != null) {
        final storageRef = FirebaseStorage.instance.refFromURL(attachment.fileUrl!);
        await storageRef.delete();
      }

      await docRef.delete();
      return Right("تم حذف المرفق بنجاح");
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Attachments>>> getAllAttachments() async {
    try {
      final querySnapshot = await _firestore.collection('Attachments').get();
      final attachments = querySnapshot.docs
          .map((doc) => Attachments.fromMap(doc.id, doc.data()))
          .toList();
      return Right(attachments);
    } catch (e) {
      return Left('Error fetching attachments: $e');
    }
  }

  @override
  Future<Either<String, String>> updateAttachment(String id, Attachments attachment) async {
    try {
      await _firestore.collection('Attachments').doc(id).update(attachment.toMap());
      return const Right('Attachment updated successfully');
    } catch (e) {
      return Left('Error updating attachment: $e');
    }
  }

  @override
  Future<Either<String, List<Attachments>>> getAttachmentsByProjectId(String projectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Attachments')
          .where('projectId', isEqualTo: projectId)
          .get();
      final attachments = querySnapshot.docs
          .map((doc) => Attachments.fromMap(doc.id, doc.data()))
          .toList();
      return Right(attachments);
    } catch (e) {
      return Left('Error fetching attachments by projectId: $e');
    }
  }
}
