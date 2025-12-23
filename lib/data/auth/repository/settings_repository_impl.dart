import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:app_bhb/data/auth/source/employees_firebase_service.dart';
import 'package:app_bhb/data/auth/source/settings_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/employees_repository.dart';
import 'package:app_bhb/domain/auth/repository/settings_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  
  @override
  Future<Either> addSetting(SettingsModel settings)async  {
    return await sl<SettingsFirebaseService>().addSetting(settings);

  }

  @override
  Future<Either> deleteSetting(String id) async  {
    return await sl<SettingsFirebaseService>().deleteSetting(id);

  }

  @override
  Future<Either> getAllSettings()async{
    return await sl<SettingsFirebaseService>().getAllSettings();

  }

  @override
  Future<Either> updateSetting(String id, SettingsModel settings) async{
    return await sl<SettingsFirebaseService>().updateSetting(id, settings);

  }
}