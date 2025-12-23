
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


abstract class SettingsFirebaseService {

  Future<Either> addSetting(SettingsModel settings);
  Future<Either> getAllSettings();
  Future<Either> updateSetting(String id, SettingsModel settings);
  Future<Either> deleteSetting(String id);


}
class SettingsFirebaseServiceImpl extends SettingsFirebaseService {

  final _settingsCollection = FirebaseFirestore.instance.collection('settings');

  @override
  Future<Either> addSetting(SettingsModel settings) async{
    try {
      final doc =   await _settingsCollection.add(settings.toMap());
      return  Right(doc.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> deleteSetting(String id) async{
    try {
      await _settingsCollection.doc(id).delete();
      return const Right('settings deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAllSettings() async  {
    try {
      final snapshot = await _settingsCollection.get();
      final settings = snapshot.docs
          .map((doc) => SettingsModel.fromMap(doc.id, doc.data()))
          .toList();
      return Right(settings);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateSetting(String id, SettingsModel settings) async {
    try {
      await _settingsCollection.doc(id).update(settings.toMap());
      return const Right('settings updated successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }


}