import 'package:app_bhb/data/auth/models/attachments_model.dart';
import 'package:app_bhb/domain/auth/repository/attachments_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';

class AddAttachmentUseCase implements UseCase<Either<String, Attachments>, Attachments> {
  @override
  Future<Either<String, Attachments>> call({Attachments? params}) async {
    return await sl<AttachmentsRepository>().addAttachment(params!);
  }
}

class GetAllAttachmentsUseCase implements UseCase<Either<String, List<Attachments>>, void> {
  @override
  Future<Either<String, List<Attachments>>> call({void params}) async {
    return await sl<AttachmentsRepository>().getAllAttachments();
  }
}

class UpdateAttachmentUseCase implements UseCase<Either<String, Attachments>, Map<String, dynamic>> {
  @override
  Future<Either<String, Attachments>> call({Map<String, dynamic>? params}) async {
    final id = params!['id'] as String;
    final attachment = params['attachment'] as Attachments;
    return await sl<AttachmentsRepository>().updateAttachment(id, attachment);
  }
}

class DeleteAttachmentUseCase implements UseCase<Either<String, void>, String> {
  @override
  Future<Either<String, void>> call({String? params}) async {
    return await sl<AttachmentsRepository>().deleteAttachment(params!);
  }
}

class GetAttachmentsByProjectIdUseCase implements UseCase<Either<String, List<Attachments>>, String> {
  final AttachmentsRepository repository;

  GetAttachmentsByProjectIdUseCase({required this.repository});

  @override
  Future<Either<String, List<Attachments>>> call({String? params}) async {
    return await repository.getAttachmentsByProjectId(params!);
  }
}

