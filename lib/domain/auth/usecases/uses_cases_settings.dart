import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:app_bhb/domain/auth/repository/settings_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddSettingsUseCase implements UseCase<Either, SettingsModel> {

  @override
  Future<Either> call({SettingsModel? params}) async {
    return await sl<SettingsRepository>().addSetting(params!);
  }
}
class GetSettingsUseCase implements UseCase<Either, void> {

  @override
  Future<Either> call({void params}) async {
    return await sl<SettingsRepository>().getAllSettings();
  }
}
class DeleteSettingsUseCase implements UseCase<Either, String> {

  @override
  Future<Either> call({String? params}) async {
    return await sl<SettingsRepository>().deleteSetting(params!);
  }
}
class UpdateSettingsUseCase implements UseCase<Either, Map<String, dynamic>> {

  @override
  Future<Either> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final settings = params['settings'] as SettingsModel;
    return await sl<SettingsRepository>().updateSetting(id, settings);
  }
}

