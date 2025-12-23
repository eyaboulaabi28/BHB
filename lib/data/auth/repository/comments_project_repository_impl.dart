import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:app_bhb/data/auth/source/comments_project_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/comments_project_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class CommentsProjectRepositoryImpl extends CommentsProjectRepository {


  @override
  Future<Either<String, CommentsProject>> addCommentProject(CommentsProject commentProject) async{
    final result = await sl<CommentsProjectFirebaseService>().addCommentProject(commentProject);
    return result.fold(
          (l) => Left(l),
          (r) => Right(commentProject),
    );
  }

  @override
  Future<Either<String, void>> deleteCommentProject(String id) async{
    return await sl<CommentsProjectFirebaseService>().deleteCommentProject(id);

  }

  @override
  Future<Either<String, List<CommentsProject>>> getAllCommentsProject() async {
    return await sl<CommentsProjectFirebaseService>().getAllCommentsProject();
  }

  @override
  Future<Either<String, List<CommentsProject>>> getCommentsProjectByProjectId(String projectId) async{
    return await sl<CommentsProjectFirebaseService>().getCommentsProjectByProjectId(projectId);
  }

  @override
  Future<Either<String, CommentsProject>> updateCommentProject(String id, CommentsProject commentProject) async {

    final result = await sl<CommentsProjectFirebaseService>().updateCommentProject(id, commentProject);
    return result.fold(
          (l) => Left(l),
          (r) => Right(commentProject),
    );
  }

}