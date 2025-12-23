import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:app_bhb/data/auth/source/meeting_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/MeetingRepository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class MeetingRepositoryImpl extends MeetingRepository {
  @override
  Future<Either> addMeeting(Meeting meeting) async {
    return await sl<MeetingFirebaseService>().addMeeting(meeting);
  }
  @override
  Future<Either> deleteMeeting(String id) async{
    return await sl<MeetingFirebaseService>().deleteMeeting(id);
  }
  @override
  Future<Either> getAllMeeting() async{
    return await sl<MeetingFirebaseService>().getAllMeeting();
  }
  @override
  Future<Either> getMeetingById(String id) async {
    return await sl<MeetingFirebaseService>().getMeetingById(id);
  }
}