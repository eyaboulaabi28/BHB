
import 'package:app_bhb/data/auth/repository/attachments_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/auth_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/check_in_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/comments_project_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/contact_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/customers_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/employees_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/engineers_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/materials_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/meeting_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/notification_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/operationals_test_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/projects_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/settings_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/signature_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/stages_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/sub_stages_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/sub_test_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/task_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/tasks_test_repository_impl.dart';
import 'package:app_bhb/data/auth/repository/vacation_repository_impl.dart';
import 'package:app_bhb/data/auth/source/attachments_firebase_service.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/data/auth/source/check_in_firebase_service.dart';
import 'package:app_bhb/data/auth/source/comments_project_firebase_service.dart';
import 'package:app_bhb/data/auth/source/contact_firebase_service.dart';
import 'package:app_bhb/data/auth/source/customers_firebase_service.dart';
import 'package:app_bhb/data/auth/source/daily_task_firebase_service.dart';
import 'package:app_bhb/data/auth/source/employees_firebase_service.dart';
import 'package:app_bhb/data/auth/source/engineers_firebase_service.dart';
import 'package:app_bhb/data/auth/source/materials_firebase_service.dart';
import 'package:app_bhb/data/auth/source/meeting_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_firebase_service.dart';
import 'package:app_bhb/data/auth/source/operationals_test_firebase_service.dart';
import 'package:app_bhb/data/auth/source/projects_firebase_service.dart';
import 'package:app_bhb/data/auth/source/settings_firebase_service.dart';
import 'package:app_bhb/data/auth/source/stages_firebase_service.dart';
import 'package:app_bhb/data/auth/source/sub_stages_firebase_service.dart';
import 'package:app_bhb/data/auth/source/tasks_firebase_service.dart';
import 'package:app_bhb/data/auth/source/tasks_tests_firebase_service.dart';
import 'package:app_bhb/data/auth/source/vacation_firebase_service.dart';
import 'package:app_bhb/domain/auth/repository/MeetingRepository.dart';
import 'package:app_bhb/domain/auth/repository/attachments_repository.dart';
import 'package:app_bhb/domain/auth/repository/auth_repository.dart';
import 'package:app_bhb/domain/auth/repository/check_in_repository.dart';
import 'package:app_bhb/domain/auth/repository/comments_project_repository.dart';
import 'package:app_bhb/domain/auth/repository/contact_repository.dart';
import 'package:app_bhb/domain/auth/repository/daily_tasks_repository.dart';
import 'package:app_bhb/domain/auth/repository/employees_repository.dart';
import 'package:app_bhb/domain/auth/repository/engineers_repository.dart';
import 'package:app_bhb/domain/auth/repository/materials_repository.dart';
import 'package:app_bhb/domain/auth/repository/notification_repository.dart';
import 'package:app_bhb/domain/auth/repository/operationals_test_repository.dart';
import 'package:app_bhb/domain/auth/repository/projects_repository.dart';
import 'package:app_bhb/domain/auth/repository/settings_repository.dart';
import 'package:app_bhb/domain/auth/repository/signature_repository.dart';
import 'package:app_bhb/domain/auth/repository/stages_repository.dart';
import 'package:app_bhb/domain/auth/repository/sub_stages_repository.dart';
import 'package:app_bhb/domain/auth/repository/task_repository.dart';
import 'package:app_bhb/domain/auth/repository/tasks_test_repository.dart';
import 'package:app_bhb/domain/auth/repository/vacation_repository.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_signature.dart';
import 'package:app_bhb/domain/auth/usecases/get_roles.dart';
import 'package:app_bhb/domain/auth/usecases/materials_usecases.dart';
import 'package:app_bhb/domain/auth/usecases/send_password_reset.dart';
import 'package:app_bhb/domain/auth/usecases/signin.dart';
import 'package:app_bhb/domain/auth/usecases/signup.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attachemants.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_check_in.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_comments_project.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_contact.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_meeting.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_operationals_test.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_settings.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_stages.dart' hide UpdateStageStatusUseCase;
import 'package:app_bhb/domain/auth/usecases/uses_cases_sub_stages.dart' hide UpdateSubStageStatusUseCase;
import 'package:app_bhb/domain/auth/usecases/uses_cases_sub_tests.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks_tests.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_vacation.dart';
import 'package:app_bhb/presentation/pages/projects/stage_pdf_generator.dart';
import 'package:get_it/get_it.dart';

import 'data/auth/repository/daily_tasks_repository_impl.dart';
import 'data/auth/source/signature_firebase_service.dart';
import 'data/auth/source/sub_test_firebase_service.dart';
import 'domain/auth/repository/customers_repository.dart';
import 'domain/auth/repository/sub_test_repository.dart';

final sl  = GetIt.instance;

Future<void> initializeDependencies () async {
  await sl.reset();

  //services
  sl.registerSingleton<EngineerFirebaseService>(EngineerFirebaseServiceImpl());
  sl.registerSingleton<AuthFirebaseService>(AuthFirebaseServiceImpl());

  sl.registerSingleton<CustomerFirebaseService>(CustomerFirebaseServiceImpl());
  sl.registerSingleton<EmployeesFirebaseService>(EmployeesFirebaseServiceImpl());
  sl.registerSingleton<MaterialsFirebaseService>(MaterialsFirebaseServiceImpl());
  sl.registerSingleton<ProjectsFirebaseService>(ProjectsFirebaseServiceImpl());
  sl.registerSingleton<StagesFirebaseService>(StagesFirebaseServiceImpl());
  sl.registerSingleton<SubStagesFirebaseService>(SubStagesFirebaseServiceImpl());
  sl.registerSingleton<TasksFirebaseService>(TasksFirebaseServiceImpl());
  sl.registerSingleton<OperationalsTestFirebaseService>(OperationalsTestFirebaseServiceImpl());
  sl.registerSingleton<SubTestFirebaseService>(SubTestFirebaseServiceImpl());
  sl.registerSingleton<TasksTestsFirebaseService>(TasksTestsFirebaseServiceImpl());
  sl.registerSingleton<AttachmentsFirebaseService>(AttachmentsFirebaseServiceImpl());
  sl.registerSingleton<CommentsProjectFirebaseService>(CommentsProjectFirebaseServiceImpl());
  sl.registerSingleton<VacationFirebaseService>(VacationFirebaseServiceImpl());
  sl.registerSingleton<MeetingFirebaseService>(MeetingFirebaseServiceImpl());
  sl.registerSingleton<DailyTasksFirebaseService>(DailyTasksFirebaseServiceImpl());
  sl.registerLazySingleton<ContactFirebaseService>(() => ContactFirebaseServiceImpl());
  sl.registerLazySingleton<CheckInFirebaseService>(() => CheckInFirebaseServiceImpl());
  sl.registerSingleton<NotificationFirebaseService>(NotificationFirebaseServiceImpl(),);
  sl.registerSingleton<SettingsFirebaseService>(SettingsFirebaseServiceImpl(),);
  sl.registerSingleton<SignatureFirebaseService>(SignatureFirebaseServiceImpl(),);


  //Repositories

  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  sl.registerSingleton<EngineerRepository>(EngineerRepositoryImpl());
  sl.registerSingleton<CustomerRepository>(CustomerRepositoryImpl());
  sl.registerSingleton<EmployeesRepository>(EmployeesRepositoryImpl());
  sl.registerSingleton<MaterialsRepository>(MaterialsRepositoryImpl());
  sl.registerSingleton<ProjectsRepository>(ProjectsRepositoryImpl());
  sl.registerSingleton<StagesRepository>(StagesRepositoryImpl());
  sl.registerSingleton<SubStagesRepository>(SubStagesRepositoryImpl());
  sl.registerSingleton<TasksRepository>(TasksRepositoryImpl());
  sl.registerSingleton<OperationalsTestRepository>(OperationalsTestRepositoryImpl());
  sl.registerSingleton<SubTestRepository>(SubTestRepositoryImpl());
  sl.registerSingleton<TasksTestRepository>(TasksTestRepositoryImpl());
  sl.registerSingleton<AttachmentsRepository>(AttachmentsRepositoryImpl());
  sl.registerSingleton<CommentsProjectRepository>(CommentsProjectRepositoryImpl());
  sl.registerSingleton<VacationRepository>(VacationRepositoryImpl());
  sl.registerSingleton<MeetingRepository>(MeetingRepositoryImpl());
  sl.registerSingleton<DailyTasksRepository>(DailyTasksRepositoryImpl());
  sl.registerLazySingleton<ContactRepository>(() => ContactRepositoryImpl());
  sl.registerLazySingleton<CheckInRepository>(() => CheckInRepositoryImpl());
  sl.registerSingleton<NotificationRepository>(NotificationRepositoryImpl(),);
  sl.registerSingleton<SettingsRepository>(SettingsRepositoryImpl(),);
  sl.registerSingleton<SignatureRepository>(SignatureRepositoryImp(),);


  //Usecases Authentication
  sl.registerSingleton<SignupUseCase>(SignupUseCase());
  sl.registerSingleton<GetRoleSUseCase>(GetRoleSUseCase());
  sl.registerSingleton<SigninUseCase>(SigninUseCase());
  sl.registerSingleton<SendPasswordUseCase>(SendPasswordUseCase());
  sl.registerSingleton<GetUserProfileUseCase>(GetUserProfileUseCase());
  sl.registerSingleton<UpdateUserProfileUseCase>(UpdateUserProfileUseCase());


  // Engineer usecases
  sl.registerSingleton<AddEngineerUseCase>(AddEngineerUseCase());
  sl.registerSingleton<GetEngineersUseCase>(GetEngineersUseCase());
  sl.registerSingleton<UpdateEngineerUseCase>(UpdateEngineerUseCase());
  sl.registerSingleton<DeleteEngineerUseCase>(DeleteEngineerUseCase());
  sl.registerSingleton<CheckEmailUsedUseCase>(CheckEmailUsedUseCase(sl<EngineerRepository>()),);
  // Customer usecases
  sl.registerSingleton<AddCustomerUseCase>(AddCustomerUseCase());
  sl.registerSingleton<GetCustomerUseCase>(GetCustomerUseCase());
  sl.registerSingleton<UpdateCustomerUseCase>(UpdateCustomerUseCase());
  sl.registerSingleton<DeleteCustomerUseCase>(DeleteCustomerUseCase());
  //Employee usecases
  sl.registerSingleton<AddEmployeeUseCase>(AddEmployeeUseCase());
  sl.registerSingleton<GetEmployeeUseCase>(GetEmployeeUseCase());
  sl.registerSingleton<GetUsersUseCase>(GetUsersUseCase());
  sl.registerSingleton<UpdateEmployeeUseCase>(UpdateEmployeeUseCase());
  sl.registerSingleton<DeleteEmployeerUseCase>(DeleteEmployeerUseCase());
  sl.registerLazySingleton<GetEmployeerByProjectIdUseCase>(
        () => GetEmployeerByProjectIdUseCase(repository: sl<EmployeesRepository>()),
  );
  //  Materials usecases
  sl.registerSingleton<AddMaterialUseCase>(AddMaterialUseCase());
  sl.registerSingleton<GetMaterialsUseCase>(GetMaterialsUseCase());
  sl.registerSingleton<UpdateMaterialUseCase>(UpdateMaterialUseCase());
  sl.registerSingleton<DeleteMaterialUseCase>(DeleteMaterialUseCase());
  sl.registerLazySingleton<GetMaterialsByProjectIdUseCase>(
        () => GetMaterialsByProjectIdUseCase(repository: sl<MaterialsRepository>()),
  );
  // Projects usecases
  sl.registerSingleton<AddProjectUseCase>(AddProjectUseCase());
  sl.registerSingleton<GetProjectUseCase>(GetProjectUseCase(sl<ProjectsRepository>()),);
  sl.registerSingleton<DeleteProjectUseCase>(DeleteProjectUseCase(sl<ProjectsRepository>()),);
  sl.registerSingleton<GetProjectByIdUseCase>(GetProjectByIdUseCase(sl<ProjectsRepository>()),);
  // 🔹 NOUVEAUX USE CASES
  sl.registerSingleton<UpdateSubStageStatusUseCase>(
    UpdateSubStageStatusUseCase(sl<ProjectsRepository>()),
  );

  sl.registerSingleton<UpdateStageStatusUseCase>(
    UpdateStageStatusUseCase(sl<ProjectsRepository>()),
  );
  // Meeting usecases
  sl.registerSingleton<AddMeetingUseCase>(AddMeetingUseCase());
  sl.registerSingleton<GetMeetingUseCase>(GetMeetingUseCase(sl<MeetingRepository>()),);
  sl.registerSingleton<DeleteMeetingUseCase>(DeleteMeetingUseCase(sl<MeetingRepository>()),);
  sl.registerSingleton<GetMeetingByIdUseCase>(GetMeetingByIdUseCase(sl<MeetingRepository>()),);

  // Stages usecases
  sl.registerSingleton<AddStageUseCase>(AddStageUseCase(sl<StagesRepository>()));
  sl.registerSingleton<GetStageUseCase>(GetStageUseCase(sl<StagesRepository>()));

  // Tasks usecases
  sl.registerSingleton<AddTasksUseCase>(AddTasksUseCase(sl<TasksRepository>()));
  sl.registerSingleton<GetTaskUseCase>(GetTaskUseCase(sl<TasksRepository>()));
  sl.registerSingleton<UpdateTaskUseCase>(UpdateTaskUseCase(sl<TasksRepository>()));
  sl.registerSingleton<DeleteTaskUseCase>(DeleteTaskUseCase(sl<TasksRepository>()));


  // SubStages usecases
  sl.registerSingleton<AddSubStageUseCase>(AddSubStageUseCase(sl<SubStagesRepository>()));
  sl.registerSingleton<GetSubStageUseCase>(GetSubStageUseCase(sl<SubStagesRepository>()));
  /*sl.registerLazySingleton<UpdateSubStageStatusUseCase>(
          () => UpdateSubStageStatusUseCase(sl<SubStagesRepository>())
  );*/
  // PDF usecases
  /*sl.registerLazySingleton<StagePdfGenerator>(() => StagePdfGenerator(
    projectId: '',
    stage: {},
    subStages: [],
    tasks: [],
  ));*/

  // OperationalsTest usecases
  sl.registerSingleton<AddOperationalsTestUseCase>(AddOperationalsTestUseCase(sl<OperationalsTestRepository>()));
  sl.registerSingleton<GetOperationalsTestUseCase>(GetOperationalsTestUseCase(sl<OperationalsTestRepository>()));
  sl.registerLazySingleton<UpdateOperationalsTestStatusUseCase>(
          () => UpdateOperationalsTestStatusUseCase(sl<OperationalsTestRepository>())
  );
  // SubTest usecases
  sl.registerSingleton<AddSubTestUseCase>(AddSubTestUseCase(sl<SubTestRepository>()));
  sl.registerSingleton<GetSubTestUseCase>(GetSubTestUseCase(sl<SubTestRepository>()));
  sl.registerLazySingleton<UpdateSubTestStatusUseCase>(
          () => UpdateSubTestStatusUseCase(sl<SubTestRepository>())
  );
  // Tasks usecases
  sl.registerSingleton<AddTasksTestUseCase>(AddTasksTestUseCase(sl<TasksTestRepository>()));
  sl.registerSingleton<GetTaskTestUseCase>(GetTaskTestUseCase(sl<TasksTestRepository>()));
  sl.registerLazySingleton<GetTasksBySubStageUseCase>(
        () => GetTasksBySubStageUseCase(sl<TasksRepository>()),
  );sl.registerLazySingleton<GetTasksTestsBySubStageUseCase>(
        () => GetTasksTestsBySubStageUseCase(sl<TasksTestRepository>()),
  );


 // UseCases Attachments
  sl.registerSingleton<AddAttachmentUseCase>(AddAttachmentUseCase());
  sl.registerSingleton<GetAllAttachmentsUseCase>(GetAllAttachmentsUseCase());
  sl.registerSingleton<UpdateAttachmentUseCase>(UpdateAttachmentUseCase());
  sl.registerSingleton<DeleteAttachmentUseCase>(DeleteAttachmentUseCase());

  // UseCases CommentsProject
  sl.registerSingleton<AddCommentsProjectUseCase>(AddCommentsProjectUseCase());
  sl.registerSingleton<GetAllCommentsProjectUseCase>(GetAllCommentsProjectUseCase());
  sl.registerSingleton<UpdateCommentsProjectUseCase>(UpdateCommentsProjectUseCase());
  sl.registerSingleton<DeleteCommentsProjectUseCase>(DeleteCommentsProjectUseCase());
  // UseCases DailyTasks
  sl.registerSingleton<AddDailyTasksUseCase>(AddDailyTasksUseCase());
  sl.registerSingleton<GetAllDailyTasksUseCase>(GetAllDailyTasksUseCase());
  sl.registerLazySingleton<GetDailyTasksByEngineerIdStatusUseCase>(() => GetDailyTasksByEngineerIdStatusUseCase(sl()),);
  sl.registerLazySingleton<UpdateDailyTasksStatusUseCase>(() => UpdateDailyTasksStatusUseCase(sl<DailyTasksRepository>()));
  sl.registerLazySingleton<GetDailyTasksByStatusUseCase>(() => GetDailyTasksByStatusUseCase(sl()));
  sl.registerLazySingleton<CountTasksByEngineerPerMonthUseCase>(
        () => CountTasksByEngineerPerMonthUseCase(sl<DailyTasksRepository>()),
  );
  sl.registerLazySingleton<CountCompletedTasksByEngineerPerMonthUseCase>(
        () => CountCompletedTasksByEngineerPerMonthUseCase(sl<DailyTasksRepository>()),
  );

  // Uses cases checkIN
  sl.registerSingleton<AddDailyCheckInUseCase>(AddDailyCheckInUseCase());
  sl.registerSingleton<GetAllDailyCheckInUseCase>(GetAllDailyCheckInUseCase());
  sl.registerSingleton<GetTotalDaysByEngineerAndMonthUseCase>(GetTotalDaysByEngineerAndMonthUseCase());
  sl.registerSingleton<GetOvertimeHoursByEngineerAndMonthUseCase>(GetOvertimeHoursByEngineerAndMonthUseCase());
  sl.registerSingleton<GetTotalHoursByEngineerAndMonthUseCase>(GetTotalHoursByEngineerAndMonthUseCase());
  sl.registerSingleton<GetTotalDurationByEngineerAndMonthUseCase>(GetTotalDurationByEngineerAndMonthUseCase());
  sl.registerSingleton<UpdateDailyCheckInUseCase>(UpdateDailyCheckInUseCase());


  // UseCases CommentsProject
  sl.registerSingleton<AddVacationUseCase>(AddVacationUseCase());
  sl.registerSingleton<GetAllVacationUseCase>(GetAllVacationUseCase());
  sl.registerSingleton<DeleteVacationUseCase>(DeleteVacationUseCase());


 // UseCase avec injection du repository
  sl.registerLazySingleton<GetAttachmentsByProjectIdUseCase>(
        () => GetAttachmentsByProjectIdUseCase(repository: sl<AttachmentsRepository>()),
  );
  //Send Message
  sl.registerLazySingleton<SendContactMessageUseCase>(() => SendContactMessageUseCase(sl()));
  // UseCases Notification
  sl.registerSingleton<CreateNotificationUseCase>(CreateNotificationUseCase());
  sl.registerSingleton<GetNotificationUseCase>(GetNotificationUseCase());
  sl.registerSingleton<MarkNotificationAsReadUseCase>(MarkNotificationAsReadUseCase());
  //UseCases Settings
  sl.registerSingleton<AddSettingsUseCase>(AddSettingsUseCase());
  sl.registerSingleton<GetSettingsUseCase>(GetSettingsUseCase());
  sl.registerSingleton<UpdateSettingsUseCase>(UpdateSettingsUseCase());
  sl.registerSingleton<DeleteSettingsUseCase>(DeleteSettingsUseCase());

  //UseCases SSignature
  sl.registerLazySingleton<AddElectronicSignatureUseCase>(
          () => AddElectronicSignatureUseCase(sl<SignatureRepository>()));

  sl.registerLazySingleton(
        () => UpdateTestSectionStatusUseCase(sl()),
  );

  sl.registerLazySingleton(
        () => UpdateTestStatusUseCase(sl()),
  );


}

