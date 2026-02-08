import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaterialModel {
  final int id;
  final String category;
  final String title;
  final String duration;
  final String level;
  final String fileName;
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
    required this.fileName,
    required this.icon,
    required this.themeColor,
    bool isDownloading = false,
    bool isDownloaded = false,
  })  : isDownloading = isDownloading.obs,
        isDownloaded = isDownloaded.obs;
}

class MaterialController extends GetxController {
  final Stopwatch _focusTimer = Stopwatch();
  final List<MaterialModel> allMaterials = <MaterialModel>[
    MaterialModel(
      id: 1,
      category: 'GRAMMAR',
      title: 'Simple Present Tense',
      duration: '15 Mins',
      level: 'Beginner',
      fileName: 'simple_present_tense.pdf',
      icon: Icons.access_time_filled,
      themeColor: Colors.blue,
    ),
    MaterialModel(
      id: 2,
      category: 'VOCABULARY',
      title: 'Business Vocabulary',
      duration: '20 Mins',
      level: 'Intermediate',
      fileName: 'business_vocabulary.pdf',
      icon: Icons.work_rounded,
      themeColor: Colors.teal,
    ),
    MaterialModel(
      id: 3,
      category: 'EXAM PREP',
      title: 'TOEFL Listening',
      duration: '25 Mins',
      level: 'Advanced',
      fileName: 'toefl_listening.pdf',
      icon: Icons.headphones_rounded,
      themeColor: Colors.deepPurple,
    ),
    MaterialModel(
      id: 4,
      category: 'SPEAKING',
      title: 'Pronunciation Drills',
      duration: '10 Mins',
      level: 'Beginner',
      fileName: 'pronunciation_drills.pdf',
      icon: Icons.record_voice_over_rounded,
      themeColor: Colors.orange,
    ),
    MaterialModel(
      id: 5,
      category: 'WRITING',
      title: 'Email Writing Basics',
      duration: '18 Mins',
      level: 'Intermediate',
      fileName: 'email_writing.pdf',
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

  @override
  void onClose() {
    _stopAndSaveFocusTime();
    super.onClose();
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

  Future<String> _getLocalFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  Future<void> openMaterial(MaterialModel item) async {
    try {
      _startFocusTimer();
      final filePath = await _getLocalFilePath(item.fileName);
      final file = File(filePath);
      if (!await file.exists()) {
        Get.snackbar(
          'File not found',
          'Please download the file first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      await OpenFile.open(filePath);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> downloadMaterial(MaterialModel item) async {
    if (item.isDownloading.value) {
      return;
    }

    if (item.isDownloaded.value) {
      await openMaterial(item);
      return;
    }

    item.isDownloading.value = true;

    try {
      await Future.delayed(const Duration(seconds: 2));

      final data = await rootBundle.load('assets/materials/${item.fileName}');
      final bytes = data.buffer.asUint8List();

      final filePath = await _getLocalFilePath(item.fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      item.isDownloaded.value = true;

      Get.snackbar(
        'Success',
        'File saved! Opening...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      _startFocusTimer();
      await OpenFile.open(filePath);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      item.isDownloading.value = false;
    }
  }

  void _startFocusTimer() {
    if (!_focusTimer.isRunning) {
      _focusTimer.start();
    }
  }

  Future<void> _stopAndSaveFocusTime() async {
    if (!_focusTimer.isRunning) {
      return;
    }

    _focusTimer.stop();
    final elapsedSeconds = _focusTimer.elapsed.inSeconds;
    _focusTimer.reset();

    if (elapsedSeconds <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastDate = prefs.getString('focus_time_date');

    if (lastDate != todayKey) {
      await prefs.setInt('focus_time_today', 0);
      await prefs.setString('focus_time_date', todayKey);
    }

    final current = prefs.getInt('focus_time_today') ?? 0;
    await prefs.setInt('focus_time_today', current + elapsedSeconds);
  }
}
