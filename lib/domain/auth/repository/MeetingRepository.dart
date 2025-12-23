import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:dartz/dartz.dart';

abstract class MeetingRepository {
  Future<Either> addMeeting(Meeting meeting);
  Future<Either> getAllMeeting();
  Future<Either> deleteMeeting(String id);
  Future<Either> getMeetingById(String id);
}
