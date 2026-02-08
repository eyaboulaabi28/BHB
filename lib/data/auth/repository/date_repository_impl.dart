import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/data/auth/source/date_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/date_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';

class DateRepositoryImpl extends DateRepository {


  @override
  Future<Either> addDate(Date date)   async {
    return await sl<DateFirebaseService>().addDate(date);
  }

  @override
  Future<Either> getAllDate({
    required String userId,
    required String role,
  }) async {
    return await sl<DateFirebaseService>()
        .getAllDate(userId: userId, role: role);
  }

  @override
  Future<Either> getDateById(String id) async {
    return await sl<DateFirebaseService>().getDateById(id);
  }

  @override
  Future<Either> updateDate(String id, Date date) async {
    return await sl<DateFirebaseService>().updateDate(id, date);
  }


}