import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/data/auth/source/materials_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/materials_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class MaterialsRepositoryImpl extends MaterialsRepository {
  @override
  Future<Either> addMaterial(Materials material) async {
    return await sl<MaterialsFirebaseService>().addMaterial(material);
  }

  @override
  Future<Either> getAllMaterials() async {
    return await sl<MaterialsFirebaseService>().getAllMaterials();
  }

  @override
  Future<Either> updateMaterial(String id, Materials material) async {
    return await sl<MaterialsFirebaseService>().updateMaterial(id, material);
  }

  @override
  Future<Either> deleteMaterial(String id) async {
    return await sl<MaterialsFirebaseService>().deleteMaterial(id);
  }

  @override
  Future<Either> getMaterialsByProjectId(String projectId) async {

    return await sl<MaterialsFirebaseService>().getMaterialsByProjectId(projectId);

  }
}
