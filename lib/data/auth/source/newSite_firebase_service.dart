
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class NewSiteFirebaseService {
  Future<Either> addNewSite(NewSite newSite);
  Future<Either> getAllNewSite();
  Future<Either> getNewSiteById(String id);
  Future<Either> updateTasksForSite(String siteId, SiteTask task, String? generalRemark);
}
class NewSiteFirebaseServiceImpl extends NewSiteFirebaseService {

  final _attendanceCollection = FirebaseFirestore.instance.collection('newSite');
  @override
  Future<Either> addNewSite(NewSite newSite) async {
    try {
      final docRef = await _attendanceCollection.add(newSite.toMap());
      return Right(docRef.id); // ici tu récupères l'ID généré par Firebase
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> getAllNewSite() async{
    try {
      final snapshot = await _attendanceCollection.get();
      final attendance = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) return null; // skip or handle empty doc
        return NewSite.fromMap(doc.id, data);
      }).whereType<NewSite>().toList(); // remove nulls
      return Right(attendance);
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> getNewSiteById(String id) async{
    try {
      final doc = await _attendanceCollection.doc(id).get();
      if (!doc.exists) {
        return Left('NewSite not found');
      }
      final attendance = NewSite.fromMap(doc.id, doc.data()!);
      return Right(attendance);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either> updateTasksForSite(String siteId, SiteTask task, String? generalRemark) async {
    try {
      final docRef = _attendanceCollection.doc(siteId);
      await docRef.update({
        'task': task.toMap(),
        'generalRemark': generalRemark,
      });
      return Right(true); // <-- success ici est un bool
    } catch (e) {
      return Left(e.toString());
    }
  }

}