import 'dart:typed_data';

import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

abstract class MeetingFirebaseService {
  Future<Either> addMeeting(Meeting meeting);
  Future<Either> getAllMeeting();
  Future<Either> deleteMeeting(String id);
  Future<Either> getMeetingById(String id);
}
class MeetingFirebaseServiceImpl extends MeetingFirebaseService {
  final _meetingCollection = FirebaseFirestore.instance.collection('meeting');
  @override
  Future<Either> addMeeting(Meeting meeting) async{
    try {
      await _meetingCollection.add(meeting.toMap());
      return const Right('Meeting added successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }
  @override
  Future<Either> deleteMeeting(String id) async{
    try {
      await _meetingCollection.doc(id).delete();
      return const Right('Meeting deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }
  @override
  Future<Either> getAllMeeting() async{
  try {
  final snapshot = await _meetingCollection.get();
  final meeting = snapshot.docs
      .map((doc) => Meeting.fromMap(doc.id, doc.data()))
      .toList();
  return Right(meeting);
  } catch (e) {
  return Left(e.toString());
  }
  }

  @override
  Future<Either> getMeetingById(String id) async {
    try {
      final doc = await _meetingCollection.doc(id).get();
      if (!doc.exists) {
        return Left('Meeting not found');
      }
      final meeting = Meeting.fromMap(doc.id, doc.data()!);
      return Right(meeting);
    } catch (e) {
      return Left(e.toString());
    }
  }

}