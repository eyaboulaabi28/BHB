import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:app_bhb/domain/auth/repository/newSite_Repository.dart';
import 'package:dartz/dartz.dart';

import '../../../service_locator.dart';
import '../source/newSite_firebase_service.dart';

class NewSiteRepositoryImpl extends NewSiteRepository {

  @override
  Future<Either> addNewSite(NewSite newSite) async{
    return await sl<NewSiteFirebaseService>().addNewSite(newSite);
  }

  @override
  Future<Either> getAllNewSite() async{
    return await sl<NewSiteFirebaseService>().getAllNewSite();
  }

  @override
  Future<Either> getNewSiteById(String id) async{
      return await sl<NewSiteFirebaseService>().getNewSiteById(id);
  }

  @override
  Future<Either> updateTasksForSite(String siteId, SiteTask task, String? generalRemark) async{
    return await sl<NewSiteFirebaseService>().updateTasksForSite(siteId, task, generalRemark);
  }

}