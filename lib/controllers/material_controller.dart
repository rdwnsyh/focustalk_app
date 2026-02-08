import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaterialModel {
  final int id;
  final String category;
  final String title;
  final String duration;
  final String level;
  final IconData icon;
  final Color themeColor;
  final RxBool isDownloading;
  final RxBool isDownloaded;

  MaterialModel({
    required this.id,
    required this.category,
    required this.title,
    required this.duration,
    required this.level,
    required this.icon,
    required this.themeColor,
    bool isDownloading = false,
    bool isDownloaded = false,
  })  : isDownloading = isDownloading.obs,
        isDownloaded = isDownloaded.obs;
}

class MaterialController extends GetxController {
  final List<MaterialModel> allMaterials = <MaterialModel>[
    MaterialModel(
      id: 1,
      category: 'GRAMMAR',
      title: 'Simple Present Tense',
      duration: '15 Mins',
      level: 'Beginner',
      icon: Icons.access_time_filled,
      themeColor: Colors.blue,
    ),
    MaterialModel(
      id: 2,
      category: 'VOCABULARY',
      title: 'Business Vocabulary',
      duration: '20 Mins',
      level: 'Intermediate',
      icon: Icons.work_rounded,
      themeColor: Colors.teal,
    ),
    MaterialModel(
      id: 3,
      category: 'EXAM PREP',
      title: 'TOEFL Listening',
      duration: '25 Mins',
      level: 'Advanced',
      icon: Icons.headphones_rounded,
      themeColor: Colors.deepPurple,
    ),
    MaterialModel(
      id: 4,
      category: 'PRONUNCIATION',
      title: 'Minimal Pairs Drill',
      duration: '10 Mins',
      level: 'Beginner',
      icon: Icons.record_voice_over_rounded,
      themeColor: Colors.orange,
    ),
    MaterialModel(
      id: 5,
      category: 'WRITING',
      title: 'Email Writing Basics',
      duration: '18 Mins',
      level: 'Intermediate',
      icon: Icons.edit_rounded,
      themeColor: Colors.redAccent,
    ),
  ];

  final RxList<MaterialModel> filteredMaterials = <MaterialModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    filteredMaterials.assignAll(allMaterials);
  }

  void filterMaterials(String query) {
    final trimmedQuery = query.trim().toLowerCase();

    if (trimmedQuery.isEmpty) {
      filteredMaterials.assignAll(allMaterials);
      return;
    }

    final results = allMaterials.where((material) {
      return material.title.toLowerCase().contains(trimmedQuery) ||
          material.category.toLowerCase().contains(trimmedQuery);
    }).toList();

    filteredMaterials.assignAll(results);
  }

  Future<void> downloadFile(MaterialModel material) async {
    if (material.isDownloading.value || material.isDownloaded.value) {
      return;
    }

    material.isDownloading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    material.isDownloading.value = false;
    material.isDownloaded.value = true;

    Get.snackbar(
      'Download Complete',
      'File saved to /Downloads',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}