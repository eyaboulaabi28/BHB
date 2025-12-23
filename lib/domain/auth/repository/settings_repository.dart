import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/data/auth/models/settings_model.dart';
import 'package:dartz/dartz.dart';

abstract class SettingsRepository {
  Future<Either> addSetting(SettingsModel settings);
  Future<Either> getAllSettings();
  Future<Either> updateSetting(String id, SettingsModel settings);
  Future<Either> deleteSetting(String id);

}
