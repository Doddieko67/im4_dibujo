//Biblioteca
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tutorial_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Stream<QuerySnapshot> getSavedVideos() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('likedVideos')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteVideo(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('likedVideos')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Biblioteca"),
        backgroundColor: const Color(0xFF009688),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: getSavedVideos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger rebuild
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final videos = snapshot.data!.docs;

              if (videos.isEmpty) {
                return const Center(
                  child: Text(
                    "No hay videos guardados",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  itemCount: videos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final doc = videos[index];
                    final video = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.teal.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              video['thumbnail'],
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 45, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              video['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              video['channelTitle'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                                  tooltip: "Eliminar de favoritos",
                                  onPressed: () => deleteVideo(docId),
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF009688),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    minimumSize: const Size(60, 32),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TutorialDetailScreen(
                                          videoId: video['videoId'],
                                          difficulty: video['difficulty'] ?? 'Fácil',
                                          xpPoints: video['xpPoints'] ?? 5,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Ver",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
