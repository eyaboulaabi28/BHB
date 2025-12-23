import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks_tests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../service_locator.dart';
class TasksTestsList extends StatelessWidget {
  final String subTestId;
  final String projectId;

  const TasksTestsList({
    super.key,
    required this.subTestId,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasksTest')
          .where('projectId', isEqualTo: projectId)
          .where('subTestId', isEqualTo: subTestId)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "لا توجد اختبارات مضافة بعد",
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
          );
        }

        final tasks = snapshot.data!.docs
            .map(
              (doc) => TasksTests.fromMap(
            doc.id, // ✅ id الوثيقة
            doc.data() as Map<String, dynamic>,
          ),
        ).toList();
        print('DEBUG → subTestId=$subTestId | docs=${snapshot.data?.docs.length}');

        return Column(
          children: tasks
              .map((task) => TaskTestModernCard(task: task))
              .toList(),
        );
      },
    );
  }
}
class TaskTestModernCard extends StatelessWidget {
  final TasksTests task;

  const TaskTestModernCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(task.images ?? []);

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
          /// 📝 NOTES
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
            task.notes?.isNotEmpty == true ? task.notes! : "—",
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          if (images.isNotEmpty) const SizedBox(height: 14),

          /// 📸 IMAGES
          TaskTestImagesSection(
            title: "صور الاختبار",
            icon: Icons.image_outlined,
            images: images,
          ),
        ],
      ),
    );
  }
}
class TaskTestImagesSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> images;

  const TaskTestImagesSection({
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
                  p == null
                      ? w
                      : const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
