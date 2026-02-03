import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/data/auth/models/site_task_model.dart';
import 'package:dartz/dartz.dart';

abstract class NewSiteRepository {
  Future<Either> addNewSite(NewSite newSite);
  Future<Either> getAllNewSite();
  Future<Either> getNewSiteById(String id);
  Future<Either> updateTasksForSite(String siteId, SiteTask task, String? generalRemark);
}