import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DailyTasksFirebaseService {
  Future<Either<String, String>> addDailyTask(DailyTasks dailyTasks);
  Future<Either<String, List<DailyTasks>>>  getAllDailyTasks();
  Future<Either<String, Unit>> updateDailyTaskStatus(DailyTasks dailyTasks);
  Future<Either<String, List<DailyTasks>>> getDailyTasksByStatus(String status);
  Future<Either<String, List<DailyTasks>>> getTasksByEngineerAndStatus(
      String engineerId, String status);
  Future<Either<String, int>> countTasksByEngineerPerMonth(
      String engineerId, int year, int month);

  Future<Either<String, int>> countCompletedTasksByEngineerPerMonth(
      String engineerId, int year, int month);
  Future<Either<String, int>> getTotalDurationByEngineerAndMonth(
      String engineerId, int year, int month);
}

class DailyTasksFirebaseServiceImpl extends DailyTasksFirebaseService {

  final _dailyTasksCollection = FirebaseFirestore.instance.collection('dailyTasks');


  @override
  Future<Either<String, String>> addDailyTask(DailyTasks dailyTasks) async {
    try {
      await _dailyTasksCollection.add(dailyTasks.toMap());
      return const Right('dailyTasks added successfully');
    } catch (e) {
      return Left('Error adding dailyTasks: $e');
    }
  }

  @override
  Future<Either<String, List<DailyTasks>>> getAllDailyTasks() async{
    try {
      final querySnapshot = await _dailyTasksCollection.get();
      final dailyTasks = querySnapshot.docs
          .map((doc) => DailyTasks.fromMap(doc.id, doc.data()))
          .toList();
      return Right(dailyTasks);
    } catch (e) {
      return Left('Error fetching dailyTasks: $e');
    }
  }

  @override
  Future<Either<String, Unit>> updateDailyTaskStatus(DailyTasks dailyTasks) async {
    try {
      if (dailyTasks.id == null || dailyTasks.id!.isEmpty) {
        return left("ID du dailyTasks requis");
      }

      await _dailyTasksCollection.doc(dailyTasks.id).update({
        'status': dailyTasks.status,
      });

      return right(unit); // succès
    } on FirebaseException catch (e) {
      return left("Erreur Firebase : ${e.message}");
    } catch (e) {
      return left("Erreur inattendue : $e");
    }
  }

  @override
  Future<Either<String, List<DailyTasks>>> getDailyTasksByStatus(String status) async {
    try {
      final querySnapshot = await _dailyTasksCollection
          .where('status', isEqualTo: status)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => DailyTasks.fromMap(doc.id, doc.data()))
          .toList();

      return Right(tasks);
    } catch (e) {
      return Left("Erreur lors du chargement par status : $e");
    }
  }

  @override
  Future<Either<String, List<DailyTasks>>> getTasksByEngineerAndStatus(String engineerId, String status) async {
    try {
      final querySnapshot = await _dailyTasksCollection
          .where('engineerId', isEqualTo: engineerId)
          .where('status', isEqualTo: status)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => DailyTasks.fromMap(doc.id, doc.data()))
          .toList();

      return Right(tasks);
    } catch (e) {
      return Left("Erreur lors du filtrage engineerId + status : $e");
    }
  }
  @override
  Future<Either<String, int>> getTotalDurationByEngineerAndMonth(
      String engineerId, int year, int month) async {
    try {
      final querySnapshot = await _dailyTasksCollection
          .where('engineerId', isEqualTo: engineerId)
          .get();
      final checkIns = querySnapshot.docs
          .map((doc) => DailyTasks.fromMap(doc.id, doc.data()))
          .where((c) => c.createdAt?.year == year && c.createdAt?.month == month)
          .toList();
      int totalDays = checkIns.fold(0, (sum, c) {
        final day = int.tryParse(c.duration ?? '0') ?? 0;
        return sum + day;
      });
      return Right(totalDays);
    } catch (e) {
      return Left('Error calculating total days: $e');
    }
  }
  @override
  Future<Either<String, int>> countTasksByEngineerPerMonth(String engineerId, int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

      final snapshot = await _dailyTasksCollection
          .where('engineerId', isEqualTo: engineerId)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();
      final allTasks = await _dailyTasksCollection.get();
      for (var doc in allTasks.docs) {
        print(doc.data());
      }
      return Right(snapshot.docs.length);
    } catch (e) {
      return Left("Erreur lors du comptage des tâches : $e");
    }
  }

  @override
  Future<Either<String, int>> countCompletedTasksByEngineerPerMonth(String engineerId, int year, int month) async {

    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

      final snapshot = await _dailyTasksCollection
          .where('engineerId', isEqualTo: engineerId)
          .where('status', isEqualTo: "مكتملة")
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      final allTasks = await _dailyTasksCollection.get();
      for (var doc in allTasks.docs) {
        print(doc.data());
      }
      return Right(snapshot.docs.length);
    } catch (e) {
      return Left("Erreur lors du comptage des tâches complétées : $e");
    }
  }
}