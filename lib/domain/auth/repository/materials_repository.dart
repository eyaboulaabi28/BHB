import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:dartz/dartz.dart';

abstract class MaterialsRepository {
  Future<Either> addMaterial(Materials material);
  Future<Either> getAllMaterials();
  Future<Either> updateMaterial(String id, Materials material);
  Future<Either> deleteMaterial(String id);
  Future<Either> getMaterialsByProjectId(String projectId);
}
