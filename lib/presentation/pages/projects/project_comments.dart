import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/comments_project.dart';
import 'package:app_bhb/data/auth/source/comments_project_firebase_service.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_comments_project.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import '../../../service_locator.dart';

class ProjectComments extends StatefulWidget {
  final String projectId;

  const ProjectComments({super.key, required this.projectId});

  @override
  State<ProjectComments> createState() => _ProjectCommentsState();
}

class _ProjectCommentsState extends State<ProjectComments> {
  final List<Map<String, dynamic>> _projectComments = [];
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _loadProjectComments();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());

  }

  Future<void> _loadProjectComments() async {
    try {
      final result = await sl<CommentsProjectFirebaseService>()
          .getCommentsProjectByProjectId(widget.projectId);

      result.fold(
            (error) {
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
        },
            (projectComment) {
          setState(() {
            _projectComments.clear();
            _projectComments.addAll(projectComment.map((att) => att.toMap()));
          });
        },
      );
    } catch (e) {
      CustomSnackBar.show(context, message: e.toString(), type: SnackBarType.error);
    }
  }


  void _addProjectComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GenericFormModal(
          title: "إضافة ملاحظة",
          fields: [
            FormFieldConfig(
              key: "nameComment",
              hint: "عنوان الملاحظة",
            ),
            FormFieldConfig(
              key: "description",
              hint: "الملاحظة",
            ),
          ],
          onSubmit: (values) async {
            final String nameComment = values["nameComment"] ?? "";
            final String description = values["description"] ?? "";
            if (nameComment.isEmpty || description.isEmpty) {
              CustomSnackBar.show(
                context,
                message: "الرجاء إدخال جميع البيانات",
                type: SnackBarType.error,
              );
              return;
            }
            final comment = CommentsProject(
              projectId: widget.projectId,
              nameComment: nameComment,
              description: description,
            );
            final result = await sl<AddCommentsProjectUseCase>().call(params: comment);

            result.fold(
                  (error) {
                CustomSnackBar.show(
                  context,
                  message: "حدث خطأ أثناء إضافة الملاحظة : $error",
                  type: SnackBarType.error,
                );
              },
                  (addedComment) {
                Navigator.pop(context);

                CustomSnackBar.show(
                  context,
                  message: "تمت إضافة الملاحظة بنجاح",
                  type: SnackBarType.success,
                );
                _notificationService.send(
                  title: "إضافة الملاحظة",
                  message: "تم إضافة الملاحظة: ${comment.nameComment}",
                  route: "/home",
                );
                _loadProjectComments();
              },
            );
          },
        );
      },
    );
  }



  void _deleteComment(Map<String, dynamic> att) async {
    if (att["id"] == null) return;

    final result = await sl<DeleteCommentsProjectUseCase>().call(params: att["id"]);

    result.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "خطأ  في الحذف  : $failure",
          type: SnackBarType.error,
        );
      },
          (_) {
        CustomSnackBar.show(
          context,
          message: "تم حذف الملاحظة بنجاح",
          type: SnackBarType.success,
        );
        _loadProjectComments();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📘 ملاحظات المشروع",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addProjectComments,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text("إضافة ملاحظة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _projectComments.isEmpty
              ? Center(
            child: Column(
              children: [
                Icon(Icons.notes, color: Colors.grey.shade400, size: 70),
                const SizedBox(height: 8),
                const Text(
                  "لم تتم إضافة أي ملاحظات بعد",
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: _projectComments
                .map((att) => buildAttachmentCard(att))
                .toList(),
          ),

        ],
      ),
    );
  }


  Widget buildAttachmentCard(Map<String, dynamic> att) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,

                child:  CircleAvatar(
                  radius: 22,
                  backgroundColor: TColor.primary.withOpacity(0.2),
                  child:  Icon(Icons.notes, color: TColor.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      att["nameComment"] ?? "ملاحظة",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (att["description"] != null)
                      Text(
                        att["description"],
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Text(
                      att["createdAt"] != null
                          ? DateTime.parse(att["createdAt"])
                          .toLocal()
                          .toString()
                          .split('.')[0]
                          : "",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _deleteComment(att),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: "حذف الملاحظة",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



}
