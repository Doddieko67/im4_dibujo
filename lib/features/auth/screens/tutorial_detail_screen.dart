//Buscar videos
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorialDetailScreen extends StatefulWidget {
  final String videoId;
  final String difficulty;
  final int xpPoints;

  const TutorialDetailScreen({
    Key? key,
    required this.videoId,
    required this.difficulty,
    required this.xpPoints,
  }) : super(key: key);

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen> {
  late YoutubePlayerController _controller;
  bool _buttonEnabled = false;
  bool _tutorialAlreadyCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        enableJavaScript: true,
        strictRelatedVideos: true,
      ),
    );

    _checkTutorialStatus();
    _startTimer();
  }

  Future<void> _checkTutorialStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    final completados = List<String>.from(data?['tutorialesCompletados'] ?? []);

    if (completados.contains(widget.videoId) && mounted) {
      setState(() {
        _tutorialAlreadyCompleted = true;
      });
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          _buttonEnabled = true;
        });
      }
    });
  }

  int requiredExp(int level) {
    return 10 + (level * 5);
  }

  Future<void> _onFinishPressed() async {
    if (_tutorialAlreadyCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este tutorial ya fue completado.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (!_buttonEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes terminar de ver el tutorial para desbloquear el botón.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = await docRef.get();
    final data = userData.data() ?? {};

    final completados = List<String>.from(data['tutorialesCompletados'] ?? []);
    if (completados.contains(widget.videoId)) return;

    int expActual = data['experience'] ?? 0;
    int xpGanada = widget.xpPoints;
    int expTotal = data['experienceTotal'] ?? 0;
    int level = data['level'] ?? 1;

    int nuevaExp = expActual + xpGanada;
    expTotal += xpGanada;

    while (true) {
      int requiredXP = requiredExp(level);
      if (nuevaExp < requiredXP) break;
      nuevaExp -= requiredXP;
      level++;
    }

    try {
      await docRef.update({
        'tutorialesCompletados': FieldValue.arrayUnion([widget.videoId]),
        'experience': nuevaExp,
        'experienceTotal': expTotal,
        'level': level,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tutorial completado! 🎉 XP otorgada'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _tutorialAlreadyCompleted = true;
      });
    } catch (e) {
      print("Error al actualizar Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error al actualizar los datos en Firestore.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return Colors.green.shade400;
      case 'medio':
        return Colors.orange.shade400;
      case 'difícil':
        return Colors.red.shade400;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00BCD4),
        title: const Text("Ver Tutorial"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(controller: _controller),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              'Dificultad: ${widget.difficulty}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                _getDifficultyColor(widget.difficulty),
                          ),
                          Chip(
                            label: Text(
                              '${widget.xpPoints} XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            avatar: const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 20,
                            ),
                            backgroundColor: Colors.blue.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        _tutorialAlreadyCompleted
                            ? "¡Has completado este tutorial!"
                            : "Mira el video completo para desbloquear el botón de finalizar.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _tutorialAlreadyCompleted
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Tooltip(
            message: _buttonEnabled
                ? "Presiona para finalizar el tutorial"
                : "Debes terminar de ver el video para desbloquear",
            child: ElevatedButton.icon(
              onPressed: _buttonEnabled && !_tutorialAlreadyCompleted
                  ? _onFinishPressed
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                "Finalizar tutorial",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                disabledBackgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
