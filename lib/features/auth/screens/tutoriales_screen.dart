//Etiquetas de dificultad y xp
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'tutorial_detail_screen.dart';
import 'dart:math';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({Key? key}) : super(key: key);

  @override
  _TutorialsScreenState createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen>
    with TickerProviderStateMixin {
  final String apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> videos = [];
  Set<String> savedVideoIds = {};
  String searchKeyword = 'origami';

  final List<String> origamiCategories = [
    'origami flores',
    'origami armas',
    'origami animales',
    'origami figuras',
    'origami aviones',
    'origami simples',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSavedVideoIds();
    _fetchYouTubeVideos(searchKeyword);
  }

  Future<void> _fetchSavedVideoIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('likedVideos')
            .get();

    setState(() {
      savedVideoIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _fetchYouTubeVideos(String query) async {
    String randomCategory =
        origamiCategories[DateTime.now().millisecondsSinceEpoch %
            origamiCategories.length];
    String searchQuery = query.isEmpty ? randomCategory : 'origami $query';

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$searchQuery&type=video&maxResults=10&relevanceLanguage=es&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        videos = data['items'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los videos')),
      );
    }
  }

  String _assignDifficulty(String title) {
    final List<String> difficulties = ['Fácil', 'Medio', 'Difícil'];
    return difficulties[Random().nextInt(difficulties.length)];
  }

  int _getXPFromDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Medio':
        return 10;
      case 'Difícil':
        return 15;
      default:
        return 5;
    }
  }

  Future<void> _saveVideoToFirestore(Map video) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final videoId = video['id']['videoId'];
    if (videoId == null) return;

    String title = video['snippet']['title'];
    String difficulty = _assignDifficulty(title);
    int xpPoints = _getXPFromDifficulty(difficulty);

    final videoData = {
      'videoId': videoId,
      'title': title,
      'description': video['snippet']['description'],
      'thumbnail': video['snippet']['thumbnails']['high']['url'],
      'channelTitle': video['snippet']['channelTitle'],
      'publishedAt': video['snippet']['publishedAt'],
      'difficulty': difficulty,
      'xpPoints': xpPoints,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('likedVideos')
        .doc(videoId);

    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set(videoData);
      setState(() {
        savedVideoIds.add(videoId);
      });
      _showHeartAnimation(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este video ya fue guardado.')),
      );
    }
  }

  void _showHeartAnimation(BuildContext context) {
    late AnimationController controller;
    controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        controller.forward();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          controller.dispose();
        });

        return Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: animation.value,
                child: Icon(
                  Icons.favorite,
                  size: 100 * animation.value,
                  color: Colors.red,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutoriales"),
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar with rounded corners and shadow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  setState(() {
                    searchKeyword =
                        value.trim().isNotEmpty ? value.trim() : 'origami';
                  });
                  _fetchYouTubeVideos(searchKeyword);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar $searchKeyword...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchKeyword = 'origami';
                      });
                      _fetchYouTubeVideos(searchKeyword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // Lista de videos con cards mejoradas
          Expanded(
            child: videos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      var video = videos[index];
                      var videoId = video['id']['videoId'];
                      var title = video['snippet']['title'];
                      var thumbnailUrl =
                          video['snippet']['thumbnails']['high']['url'];
                      var difficulty = _assignDifficulty(title);
                      var xpPoints = _getXPFromDifficulty(difficulty);
                      bool isSaved = savedVideoIds.contains(videoId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorialDetailScreen(
                                  videoId: videoId,
                                  difficulty: difficulty,
                                  xpPoints: xpPoints,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            _saveVideoToFirestore(video);
                          },
                          onDoubleTap: () {
                            _saveVideoToFirestore(video);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 6,
                            shadowColor: Colors.black26,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  child: Image.network(
                                    thumbnailUrl,
                                    width: 130,
                                    height: 95,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: difficulty == 'Fácil'
                                                    ? Colors.green[100]
                                                    : difficulty == 'Medio'
                                                        ? Colors.orange[100]
                                                        : Colors.red[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                difficulty,
                                                style: TextStyle(
                                                  color: difficulty == 'Fácil'
                                                      ? Colors.green[800]
                                                      : difficulty == 'Medio'
                                                          ? Colors.orange[800]
                                                          : Colors.red[800],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 18,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$xpPoints XP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      isSaved
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isSaved ? Colors.red : Colors.grey,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      if (!isSaved) {
                                        _saveVideoToFirestore(video);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
