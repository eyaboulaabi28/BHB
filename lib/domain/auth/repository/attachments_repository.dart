import 'package:dartz/dartz.dart';

import '../../../data/auth/models/attachments_model.dart';

abstract class AttachmentsRepository {
  Future<Either<String, Attachments>> addAttachment(Attachments attachment);
  Future<Either<String, List<Attachments>>> getAllAttachments();
  Future<Either<String, Attachments>> updateAttachment(String id, Attachments attachment);
  Future<Either<String, void>> deleteAttachment(String id);
  Future<Either<String, List<Attachments>>> getAttachmentsByProjectId(String projectId);
}
