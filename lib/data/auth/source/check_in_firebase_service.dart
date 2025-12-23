import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CheckInFirebaseService {
  Future<Either<String, String>> addCheckIn(DailyCheckIn checkIn);
  Future<Either<String, List<DailyCheckIn>>>  getAllDailyCheckIn();
  Future<Either<String, String>> updateCheckIn(DailyCheckIn checkIn);
  Future<Either<String, double>> getTotalHoursByEngineerAndMonth(String engineerId, int year, int month);
  Future<Either<String, double>> getOvertimeHoursByEngineerAndMonth(String engineerId, int year, int month);
  Future<Either<String, int>> getTotalDaysByEngineerAndMonth(String engineerId, int year, int month);

}

class CheckInFirebaseServiceImpl extends CheckInFirebaseService {

  final _checkInCollection = FirebaseFirestore.instance.collection('checkIn');

  @override
  Future<Either<String, String>> addCheckIn(DailyCheckIn checkIn) async {
    try {
      await _checkInCollection.add(checkIn.toMap());
      return const Right('checkIn added successfully');
    } catch (e) {
      return Left('Error adding checkIn: $e');
    }
  }

  @override
  Future<Either<String, List<DailyCheckIn>>> getAllDailyCheckIn() async {
    try {
      final querySnapshot = await _checkInCollection.get();
      final CheckIn = querySnapshot.docs
          .map((doc) => DailyCheckIn.fromMap(doc.id, doc.data()))
          .toList();
      return Right(CheckIn);
    } catch (e) {
      return Left('Error fetching CheckIn: $e');
    }
  }

  @override
  Future<Either<String, String>>updateCheckIn(DailyCheckIn checkIn) async {
    try {
      if (checkIn.id == null) return Left("CheckIn ID manquant");
      await _checkInCollection.doc(checkIn.id).update(checkIn.toMap());
      return const Right('CheckIn updated successfully');
    } catch (e) {
      return Left('Error updating CheckIn: $e');
    }
  }
  @override
  Future<Either<String, double>> getTotalHoursByEngineerAndMonth(String engineerId, int year, int month) async {
    try {
      final querySnapshot = await _checkInCollection
          .where('engineerId', isEqualTo: engineerId)
          .get();

      final checkIns = querySnapshot.docs
          .map((doc) => DailyCheckIn.fromMap(doc.id, doc.data()))
          .where((c) => c.createdAt?.year == year && c.createdAt?.month == month)
          .toList();

      double totalHours = 0;
      for (var checkIn in checkIns) {
        totalHours += double.tryParse(checkIn.hoursTotal ?? '0') ?? 0;
      }

      return Right(totalHours);
    } catch (e) {
      return Left('Error calculating total hours: $e');
    }
  }

  @override
  Future<Either<String, double>> getOvertimeHoursByEngineerAndMonth(String engineerId, int year, int month) async {
    final totalResult = await getTotalHoursByEngineerAndMonth(engineerId, year, month);
    return totalResult.fold(
          (l) => Left(l),
          (totalHours) {
        // heures sup = totalHeures / (4 semaines * 8 heures)
        double overtime = totalHours - (4 * 8);
        return Right(overtime > 0 ? overtime : 0);
      },
    );
  }

  @override
  Future<Either<String, int>> getTotalDaysByEngineerAndMonth(
      String engineerId, int year, int month) async {
    try {
      // Récupérer tous les check-ins de l'ingénieur
      final querySnapshot = await _checkInCollection
          .where('engineerId', isEqualTo: engineerId)
          .get();

      // Transformer les documents en DailyCheckIn et filtrer par année et mois
      final checkIns = querySnapshot.docs
          .map((doc) => DailyCheckIn.fromMap(doc.id, doc.data()))
          .where((c) => c.createdAt?.year == year && c.createdAt?.month == month)
          .toList();

      // Calculer le total des jours à partir de numberDay
      int totalDays = checkIns.fold(0, (sum, c) {
        final day = int.tryParse(c.numberDay ?? '0') ?? 0;
        return sum + day;
      });

      return Right(totalDays);
    } catch (e) {
      return Left('Error calculating total days: $e');
    }
  }

}