import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/material_controller.dart'; 

class MaterialView extends StatelessWidget {
  const MaterialView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('🎨 MaterialView build called');
    final MaterialController controller = Get.put(MaterialController());

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Cream Background
      appBar: AppBar(
        title: const Text(
          "Study Materials",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35), // Primary Orange
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35), // Orange extension
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What do you want to learn today?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Select a topic to improve your skills.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Grid Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: controller.studyTopics.isEmpty
                  ? const Center(
                      child: Text("No topics available"),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.studyTopics.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 Kolom
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85, // Rasio Tinggi vs Lebar Kartu
                      ),
                      itemBuilder: (context, index) {
                        final topic = controller.studyTopics[index];
                        return _buildMaterialCard(
                          title: topic['title'],
                          subtitle: topic['subtitle'],
                          icon: topic['icon'],
                          color: topic['color'],
                          onTap: () => controller.openTopic(topic['title']),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Kartu Materi
  Widget _buildMaterialCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}