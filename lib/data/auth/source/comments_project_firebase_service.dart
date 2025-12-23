import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CommentsProjectFirebaseService {
  Future<Either<String, String>> addCommentProject(CommentsProject commentProject);
  Future<Either<String, List<CommentsProject>>> getAllCommentsProject();
  Future<Either<String, String>> updateCommentProject(String id, CommentsProject commentProject);
  Future<Either<String, String>> deleteCommentProject(String id);
  Future<Either<String, List<CommentsProject>>> getCommentsProjectByProjectId(String projectId);
}

class CommentsProjectFirebaseServiceImpl extends CommentsProjectFirebaseService {

  final _commentsProjectCollection = FirebaseFirestore.instance.collection('commentsProject');


  @override
  Future<Either<String, String>> addCommentProject(CommentsProject commentProject) async{
    try {
      await _commentsProjectCollection.add(commentProject.toMap());
      return const Right('CommentProject added successfully');
    } catch (e) {
      return Left('Error adding CommentProject: $e');
    }
  }

  @override
  Future<Either<String, String>> deleteCommentProject(String id) async{
    try {
      await _commentsProjectCollection.doc(id).delete();
      return const Right('Project deleted successfully');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CommentsProject>>> getAllCommentsProject() async{
    try {
      final querySnapshot = await _commentsProjectCollection.get();
      final commentsProject = querySnapshot.docs
          .map((doc) => CommentsProject.fromMap(doc.id, doc.data()))
          .toList();
      return Right(commentsProject);
    } catch (e) {
      return Left('Error fetching commentsProject: $e');
    }
  }

  @override
  Future<Either<String, List<CommentsProject>>> getCommentsProjectByProjectId(String projectId) async{
    try {
      final querySnapshot = await _commentsProjectCollection
          .where('projectId', isEqualTo: projectId)
          .get();
      final commentsProject = querySnapshot.docs
          .map((doc) => CommentsProject.fromMap(doc.id, doc.data()))
          .toList();
      return Right(commentsProject);
    } catch (e) {
      return Left('Error fetching commentsProject by projectId: $e');
    }
  }

  @override
  Future<Either<String, String>> updateCommentProject(String id, CommentsProject commentProject) async {
    try {
      await _commentsProjectCollection.doc(id).update(commentProject.toMap());
      return const Right('commentProject updated successfully');
    } catch (e) {
      return Left('Error updating commentProject: $e');
    }
  }

}