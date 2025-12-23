import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../service_locator.dart';

class SubStageTasksList extends StatelessWidget {
  final String subStageId;
  final String projectId;
  const SubStageTasksList({super.key, required this.subStageId,  required this.projectId,});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<String, List<Tasks>>>(
      future: sl<GetTasksBySubStageUseCase>().call(params: GetTasksBySubStageParams(projectId: projectId, subStageId: subStageId,),),
      builder: (context, snapshot) {

        // 🔄 Chargement
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 📦 Résultat (succès ou erreur)
        return snapshot.data!.fold(
          // ❌ Erreur
              (error) => Center(child: Text(error)),

          // ✅ Succès
              (tasks) {
            if (tasks.isEmpty) {
              return const Center(child: Text("لا توجد مهام بعد"));
            }

            // 📋 Liste des tâches
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskModernCard(task: task);
              },
            );
          },
        );
      },
    );
  }

}
class TaskModernCard extends StatelessWidget {
  final Tasks task;

  const TaskModernCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final imagesBefore = List<String>.from(task.imagesBefore ?? []);
    final imagesAfter = List<String>.from(task.imagesAfter ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 📝 Notes
          Row(
            children: const [
              Icon(Icons.notes, color: Colors.blueGrey, size: 20),
              SizedBox(width: 6),
              Text(
                "الملاحظات",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.notes ?? "—",
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          /// 📸 Before
          TaskImagesSection(
            title: "قبل العمل",
            icon: Icons.image_outlined,
            images: imagesBefore,
          ),

          if (imagesBefore.isNotEmpty) const SizedBox(height: 14),

          /// 📸 After
          TaskImagesSection(
            title: "بعد العمل",
            icon: Icons.check_circle_outline,
            images: imagesAfter,
          ),
        ],
      ),
    );
  }
}
class TaskImagesSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> images;

  const TaskImagesSection({
    super.key,
    required this.title,
    required this.icon,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, w, p) =>
                  p == null ? w : const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
