import 'dart:typed_data';

import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

abstract class DateFirebaseService {
  Future<Either> addDate(Date date);
  Future<Either> getAllDate({
    required String userId,
    required String role,
  });
  Future<Either> getDateById(String id);
  Future<Either> updateDate(String id, Date date);

}
class DateFirebaseServiceImpl extends DateFirebaseService {

  final _datesCollection = FirebaseFirestore.instance.collection('dates');
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either> addDate(Date date) async {
    try {
      final doc = await _datesCollection.add(date.toMap());
      return Right(doc.id);
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> getAllDate({
    required String userId,
    required String role,
  }) async {
    try {
      Query query = _firestore.collection('dates');

      // 👇 customer يشوف غير متاعو
      if (role == "customer") {
        query = query.where('uidCustomer', isEqualTo: userId);
      }

      final snapshot = await query.get();

      final dates = snapshot.docs
          .map((doc) => Date.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList();

      return Right(dates);
    } catch (e) {
      return Left(e.toString());
    }
  }


  @override
  Future<Either> getDateById(String id) async {
   try {
      final doc = await _datesCollection.doc(id).get();
      if (!doc.exists) {
        return Left('attendance not found');
      }
      final date = Date.fromMap(doc.id, doc.data()!);
      return Right(date);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateDate(String id, Date date) async {
    try {
      await _firestore.collection('dates').doc(id).update(date.toMap());
      return const Right('date updated successfully');
    } catch (e) {
      return Left('Error updating date: $e');
    }
  }

}