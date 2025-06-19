//Perfil
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _lastKnownLevel;

  void _checkForNewAvatars(int currentLevel) {
    if (_lastKnownLevel == null) {
      _lastKnownLevel = currentLevel;
      return;
    }

    if (currentLevel > _lastKnownLevel!) {
      final List<int> unlockLevels = List.generate(37, (index) {
        return 5 + (index ~/ 5) * 5;
      });

      final newUnlocks = unlockLevels.where((lvl) =>
          lvl > _lastKnownLevel! && lvl <= currentLevel).toList();

      if (newUnlocks.isNotEmpty) {
        final minLevel = newUnlocks.reduce((a, b) => a < b ? a : b);
        final maxLevel = newUnlocks.reduce((a, b) => a > b ? a : b);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Felicidades! Has desbloqueado nuevas fotos de perfil especiales para niveles $minLevel a $maxLevel. ¡Puedes usarlas ahora!',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    _lastKnownLevel = currentLevel;
  }

  void _selectAvatar() async {
    final normalAvatars = List.generate(
      30,
      (index) => 'assets/images/avatars/avatar_${index + 1}.png',
    );

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final level = userData['level'] ?? 1;

    final specialAvatars = List.generate(37, (index) {
      final path = 'assets/images/avatars/especiales/a_${index + 1}.png';
      final requiredLevel = 5 + (index ~/ 5) * 5;
      final unlocked = level >= requiredLevel;
      return {
        'path': path,
        'unlocked': unlocked,
        'requiredLevel': requiredLevel,
      };
    });

    final groupedSpecials = <int, List<Map<String, dynamic>>>{};
    for (var avatar in specialAvatars) {
      final reqLevel = avatar['requiredLevel'] as int;
      groupedSpecials.putIfAbsent(reqLevel, () => []).add(avatar);
    }

    final avatarWidgets = <Widget>[
      Wrap(
        spacing: 15,
        runSpacing: 15,
        alignment: WrapAlignment.center,
        children: normalAvatars.map((path) => _HoverAvatar(
          imagePath: path,
          onTap: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .update({'profileImage': path});
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar actualizado')),
            );
            setState(() {});
          },
        )).toList(),
      ),
      const SizedBox(height: 20),
      const Divider(thickness: 1.5),
      const SizedBox(height: 8),
    ];

    groupedSpecials.entries.forEach((entry) {
      avatarWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          'Desbloqueados a partir del nivel ${entry.key}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ));

      avatarWidgets.add(
        Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: entry.value.map((avatar) => _HoverAvatar(
            imagePath: avatar['path'] as String,
            unlocked: avatar['unlocked'] as bool,
            lockedTooltip: 'Desbloquea al nivel ${avatar['requiredLevel']}',
            onTap: () async {
              if (avatar['unlocked'] as bool) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update({'profileImage': avatar['path']});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avatar actualizado')),
                );
                setState(() {});
              }
            },
          )).toList(),
        ),
      );

      avatarWidgets.add(const SizedBox(height: 20));
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: isWide ? 500 : MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: avatarWidgets,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int expRequiredForNextLevel(int level) => 10 + (level * 5);

  int calculateTotalExpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += 10 + (i * 5);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOwner = widget.userId == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/f2.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.white.withOpacity(0.35),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final imagePath = data['profileImage'] ?? '';
                final isAsset = imagePath.startsWith('assets/');
                final level = data['level'] ?? 1;
                final currentExp = data['experience'] ?? 0;
                final totalExp = calculateTotalExpForLevel(level) + currentExp;
                final expForNext = expRequiredForNextLevel(level);
                final progress = currentExp / expForNext;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkForNewAvatars(level);
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 12,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepOrangeAccent,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: isAsset
                                ? AssetImage(imagePath) as ImageProvider
                                : NetworkImage(imagePath),
                            backgroundColor: Colors.white,
                          ),
                          if (isOwner)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _selectAvatar,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrangeAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),

                      const SizedBox(height: 16),

                      // FILA NIVEL Y EXPERIENCIA DEBAJO DE LA FOTO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.deepOrange, size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  'Nivel $level',
                                  style: TextStyle(
                                    color: Colors.deepOrange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.deepOrange, size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  '$currentExp / $expForNext XP',
                                  style: TextStyle(
                                    color: Colors.deepOrange.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        data['username'] ?? 'Usuario',
                        style: textTheme.headlineMedium?.copyWith(
                          fontFamily: 'OrigamiFont',
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.deepOrangeAccent.withOpacity(0.5),
                              offset: const Offset(2, 2),
                            )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatRow('Nivel', '$level'),
                              const Divider(),
                              _buildStatRow(
                                'Experiencia',
                                '$currentExp / $expForNext (${(progress * 100).toStringAsFixed(1)}%)',
                              ),
                              const Divider(),
                              _buildStatRow('Total Exp acumulada', '$totalExp'),
                              const Divider(),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Logros:',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  data['achievements']?.join(', ') ?? 'Ninguno',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              const Divider(),
                              _buildStatRow('Amigos', '${data['friends']?.length ?? 0}'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (!isOwner)
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Solicitud de amistad enviada'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF1A6),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            'Enviar solicitud de amistad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _HoverAvatar extends StatefulWidget {
  final String imagePath;
  final void Function() onTap;
  final bool unlocked;
  final String? lockedTooltip;

  const _HoverAvatar({
    required this.imagePath,
    required this.onTap,
    this.unlocked = true,
    this.lockedTooltip,
  });

  @override
  State<_HoverAvatar> createState() => _HoverAvatarState();
}

class _HoverAvatarState extends State<_HoverAvatar> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(widget.imagePath, width: 60, height: 60);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });
      },
      child: GestureDetector(
        onTap: widget.unlocked ? widget.onTap : null,
        child: Tooltip(
          message: widget.unlocked ? '' : (widget.lockedTooltip ?? 'Bloqueado'),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image,
              ),
              if (!widget.unlocked)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white70,
                    size: 30,
                  ),
                ),
              if (_hovering && widget.unlocked)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepOrangeAccent,
                      width: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
