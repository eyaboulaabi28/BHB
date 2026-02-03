import 'dart:typed_data';

import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

abstract class AttendanceFirebaseService {
  Future<Either> addAttendance(Attendance attendance);
  Future<Either> getAllAttendance();
  Future<Either> getAttendanceById(String id);
  Future<Either> getAttendanceByEmployeeAndMonth(String employeeId, DateTime month,);
}
class AttendanceFirebaseServiceImpl extends AttendanceFirebaseService {

  final _attendanceCollection = FirebaseFirestore.instance.collection('attendance');

  @override
  Future<Either> addAttendance(Attendance attendance) async {
    try {
      await _attendanceCollection.add(attendance.toMap());
      return const Right('attendance added successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAllAttendance() async{
    try {
      final snapshot = await _attendanceCollection.get();
      final attendance = snapshot.docs
          .map((doc) => Attendance.fromMap(doc.id, doc.data()))
          .toList();
      return Right(attendance);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAttendanceById(String id) async{
    try {
      final doc = await _attendanceCollection.doc(id).get();
      if (!doc.exists) {
        return Left('attendance not found');
      }
      final attendance = Attendance.fromMap(doc.id, doc.data()!);
      return Right(attendance);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> getAttendanceByEmployeeAndMonth(String employeeId, DateTime month,) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);

      final snapshot = await _attendanceCollection
          .where('employeeId', isEqualTo: employeeId)
          .where('startTime', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('startTime', isLessThan: end.toIso8601String())
          .orderBy('startTime')
          .get();

      final data = snapshot.docs
          .map((e) => Attendance.fromMap(e.id, e.data()))
          .toList();

      return Right(data);
    } catch (e) {
      return Left(e.toString());
    }
  }

}