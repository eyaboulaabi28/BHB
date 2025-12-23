import 'package:app_bhb/data/auth/models/attachments_model.dart';
import 'package:app_bhb/data/auth/source/attachments_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/attachments_repository.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:dartz/dartz.dart';

class AttachmentsRepositoryImpl extends AttachmentsRepository {
  @override
  Future<Either<String, Attachments>> addAttachment(Attachments attachment) async {
    final result = await sl<AttachmentsFirebaseService>().addAttachment(attachment);
    return result.fold(
          (l) => Left(l),
          (r) => Right(attachment),
    );
  }

  @override
  Future<Either<String, Attachments>> updateAttachment(String id, Attachments attachment) async {
    final result = await sl<AttachmentsFirebaseService>().updateAttachment(id, attachment);
    return result.fold(
          (l) => Left(l),
          (r) => Right(attachment),
    );
  }

  @override
  Future<Either<String, String>> deleteAttachment(String id) async {
    return await sl<AttachmentsFirebaseService>().deleteAttachment(id);
  }

  @override
  Future<Either<String, List<Attachments>>> getAllAttachments() async {
    return await sl<AttachmentsFirebaseService>().getAllAttachments();
  }

  @override
  Future<Either<String, List<Attachments>>> getAttachmentsByProjectId(String projectId) async {
    return await sl<AttachmentsFirebaseService>().getAttachmentsByProjectId(projectId);
  }
}
