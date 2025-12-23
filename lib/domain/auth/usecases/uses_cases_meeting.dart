import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:app_bhb/domain/auth/repository/MeetingRepository.dart';
import 'package:dartz/dartz.dart';
import 'package:app_bhb/core/usecase/usecase.dart';
import '../../../service_locator.dart';



class AddMeetingUseCase implements UseCase<Either,Meeting> {

  @override
  Future<Either> call({Meeting? params}) async {
    return await sl<MeetingRepository>().addMeeting(params!);
  }
}
class GetMeetingUseCase implements UseCase<Either, void> {
  final MeetingRepository _repo;

  GetMeetingUseCase(this._repo);

  @override
  Future<Either> call({void params}) async {
    return await _repo.getAllMeeting();
  }
}
class DeleteMeetingUseCase implements UseCase<Either, String> {
  final MeetingRepository _repository;

  DeleteMeetingUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.deleteMeeting(params!);
  }
}
class GetMeetingByIdUseCase implements UseCase<Either, String> {
  final MeetingRepository _repository;

  GetMeetingByIdUseCase(this._repository);

  @override
  Future<Either> call({String? params}) async {
    return await _repository.getMeetingById(params!);
  }
}

