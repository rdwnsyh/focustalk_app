import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaterialController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('✅ MaterialController initialized');
    print('📚 Study Topics loaded: ${studyTopics.length} topics');
  }

  // Data Materi Belajar (Bisa ditambah nanti)
  final List<Map<String, dynamic>> studyTopics = [
    {
      "title": "Tenses Mastery",
      "subtitle": "Past, Present, & Future",
      "icon": Icons.access_time_filled,
      "color": Colors.blueAccent,
      "description": "Pelajari 12 bentuk waktu dalam bahasa Inggris dengan rumus dan contoh mudah."
    },
    {
      "title": "Vocabulary",
      "subtitle": "Daily Words & Nouns",
      "icon": Icons.book,
      "color": Colors.green,
      "description": "Kumpulan kosakata sehari-hari yang wajib dihafal untuk pemula."
    },
    {
      "title": "Grammar Rules",
      "subtitle": "Structure & Syntax",
      "icon": Icons.rule,
      "color": Colors.orange,
      "description": "Aturan tata bahasa dasar untuk menyusun kalimat yang benar."
    },
    {
      "title": "Common Idioms",
      "subtitle": "Native Expressions",
      "icon": Icons.chat_bubble,
      "color": Colors.purple,
      "description": "Ungkapan unik agar bahasa Inggrismu terdengar seperti native speaker."
    },
    {
      "title": "Prepositions",
      "subtitle": "In, On, At, & More",
      "icon": Icons.place,
      "color": Colors.redAccent,
      "description": "Cara penggunaan kata depan yang tepat dalam konteks kalimat."
    },
    {
      "title": "Conversation",
      "subtitle": "Speaking Practice",
      "icon": Icons.record_voice_over,
      "color": Colors.teal,
      "description": "Contoh dialog percakapan untuk situasi formal dan informal."
    },
  ];

  // Fungsi saat item diklik
  void openTopic(String title) {
    print('🎓 Opening topic: $title');
    // Nanti bisa diarahkan ke halaman detail PDF atau Teks
    Get.snackbar(
      "Opening Material",
      "Sedang memuat materi: $title",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}