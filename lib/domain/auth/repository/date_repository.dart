import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:dartz/dartz.dart';

abstract class DateRepository {
  Future<Either> addDate(Date date);
  Future<Either> getAllDate({
    required String userId,
    required String role,
  });
  Future<Either> getDateById(String id);
  Future<Either> updateDate(String id, Date date);
}