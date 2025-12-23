import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:app_bhb/domain/auth/repository/comments_project_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddCommentsProjectUseCase implements UseCase<Either<String, CommentsProject>, CommentsProject> {
  @override
  Future<Either<String, CommentsProject>> call({CommentsProject? params}) async {
    return await sl<CommentsProjectRepository>().addCommentProject(params!);
  }
}
class GetAllCommentsProjectUseCase implements UseCase<Either<String, List<CommentsProject>>, void> {
  @override
  Future<Either<String, List<CommentsProject>>> call({void params}) async {
    return await sl<CommentsProjectRepository>().getAllCommentsProject();
  }
}
class UpdateCommentsProjectUseCase implements UseCase<Either<String, CommentsProject>, Map<String, dynamic>> {
  @override
  Future<Either<String, CommentsProject>> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final commentsProject = params['comments'] as CommentsProject;
    return await sl<CommentsProjectRepository>().updateCommentProject(id, commentsProject);
  }
}
class DeleteCommentsProjectUseCase implements UseCase<Either<String, void>, String> {
  @override
  Future<Either<String, void>> call({String? params}) async {
    return await sl<CommentsProjectRepository>().deleteCommentProject(params!);
  }
}
class GetCommentsProjectByProjectIdUseCase implements UseCase<Either<String, List<CommentsProject>>, String> {
  final CommentsProjectRepository repository;

  GetCommentsProjectByProjectIdUseCase({required this.repository});

  @override
  Future<Either<String, List<CommentsProject>>> call({String? params}) async {
    return await repository.getCommentsProjectByProjectId(params!);
  }
}


