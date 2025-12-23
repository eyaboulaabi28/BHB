import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class MaterialsFirebaseService {
  Future<Either> addMaterial(Materials material);
  Future<Either> getAllMaterials();
  Future<Either> updateMaterial(String id, Materials material);
  Future<Either> deleteMaterial(String id);
  Future<Either> getMaterialsByProjectId(String projectId);
}

class MaterialsFirebaseServiceImpl extends MaterialsFirebaseService{

  final _materialsCollection = FirebaseFirestore.instance.collection('materials');

  @override
  Future<Either> addMaterial(Materials material) async {
    try {
      final doc =   await _materialsCollection.add(material.toMap());
      await doc.update({'id': doc.id});
      return  Right(doc.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAllMaterials() async {
    try {
      final snapshot = await _materialsCollection.get();
      final materials = snapshot.docs
          .map((doc) => Materials.fromMap(doc.id, doc.data()))
          .toList();
      return Right(materials);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateMaterial(String id, Materials material) async {
    try {
      await _materialsCollection.doc(id).update(material.toMap());
      return const Right('Material updated successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }
  
  @override
  Future<Either> deleteMaterial(String id) async {
    try {
      await _materialsCollection.doc(id).delete();
      return const Right('Material deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getMaterialsByProjectId(String projectId) async {
    try {
      final snapshot = await _materialsCollection
          .where('projectId', isEqualTo: projectId)
          .get();

      final materials = snapshot.docs
          .map((doc) => Materials.fromMap(doc.id, doc.data()))
          .toList();

      return Right(materials);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

