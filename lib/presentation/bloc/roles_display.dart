import 'package:app_bhb/domain/auth/usecases/get_roles.dart';
import 'package:app_bhb/presentation/bloc/roles_display_state.dart';
import 'package:app_bhb/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesDisplay extends Cubit<RolesDisplayState> {
  RolesDisplay() : super(RolesLoading());

  Future<void> displayRoles() async {
    var returnedData = await sl<GetRoleSUseCase>().call();

    returnedData.fold(
          (message) => emit(RolesLoadFailure(message: message)), // ✅ Correction ici
          (data) => emit(RolesLoaded(roles: data)),
    );
  }
}
