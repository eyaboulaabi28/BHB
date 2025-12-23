import 'package:cloud_firestore/cloud_firestore.dart';



abstract class RolesDisplayState{}
class RolesLoading extends RolesDisplayState{}

class RolesLoaded extends RolesDisplayState{
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> roles  ;

  RolesLoaded({required this.roles});

}
class RolesLoadFailure extends RolesDisplayState{
  final String message ;

  RolesLoadFailure({required this.message});
}
