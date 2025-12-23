import 'package:app_bhb/data/auth/models/materials_model.dart';
import 'package:app_bhb/domain/auth/repository/materials_repository.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class AddMaterialUseCase implements UseCase<Either, Materials> {
  @override
  Future<Either> call({Materials? params}) async {
    return await sl<MaterialsRepository>().addMaterial(params!);
  }
}

class GetMaterialsUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call({void params}) async {
    return await sl<MaterialsRepository>().getAllMaterials();
  }
}

class UpdateMaterialUseCase implements UseCase<Either, Map<String, dynamic>> {
  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final material = params['material'] as Materials;
    return await sl<MaterialsRepository>().updateMaterial(id, material);
  }
}

class DeleteMaterialUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async {
    return await sl<MaterialsRepository>().deleteMaterial(params!);
  }
}

class GetMaterialsByProjectIdUseCase implements UseCase<Either, String> {
  final MaterialsRepository repository;

  GetMaterialsByProjectIdUseCase({required this.repository});

  @override
  Future<Either> call({String? params}) async {
    return await repository.getMaterialsByProjectId(params!);
  }
}
