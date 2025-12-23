import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:dartz/dartz.dart';

abstract class CommentsProjectRepository {
  Future<Either<String, CommentsProject>> addCommentProject(CommentsProject commentProject);
  Future<Either<String, List<CommentsProject>>> getAllCommentsProject();
  Future<Either<String, CommentsProject>> updateCommentProject(String id, CommentsProject commentProject);
  Future<Either<String, void>> deleteCommentProject(String id);
  Future<Either<String, List<CommentsProject>>> getCommentsProjectByProjectId(String projectId);
}
