//Busqueda de usuarios
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  String? currentUserId;
  List<String> myFriendsIds = [];

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadMyFriends();
  }

  Future<void> _loadMyFriends() async {
    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final friends = userDoc.data()?['friends'] ?? [];
    setState(() {
      myFriendsIds = List<String>.from(friends.map((f) => f['uid']));
    });
  }

  Future<void> _searchUsers() async {
    if (currentUserId == null) return;
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() => _isLoading = true);

    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: _searchController.text.trim())
        .where('username', isLessThan: _searchController.text.trim() + 'z')
        .orderBy('username')
        .get();

    setState(() {
      _searchResults = querySnapshot.docs;
      _isLoading = false;
    });
  }

  Future<void> _addFriend(String friendId, String friendUsername) async {
    if (currentUserId == null || currentUserId == friendId) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();

      List<dynamic> currentFriends = data?['friends'] ?? [];
      int currentCount = data?['friendsCount'] ?? 0;

      if (!currentFriends.any((f) => f['uid'] == friendId)) {
        currentFriends.add({'uid': friendId, 'username': friendUsername});
      }
      transaction.update(userRef, {
        'friends': currentFriends,
        'friendsCount': currentCount + 1,
      });
    });

    setState(() {
      myFriendsIds.add(friendId);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Amigo agregado')));
  }

  Future<void> _removeFriend(String friendId) async {
    if (currentUserId == null || currentUserId == friendId) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();

      List<dynamic> currentFriends = data?['friends'] ?? [];
      int currentCount = data?['friendsCount'] ?? 0;

      currentFriends.removeWhere((friend) => friend['uid'] == friendId);

      transaction.update(userRef, {
        'friends': currentFriends,
        'friendsCount': currentCount - 1,
      });
    });

    setState(() {
      myFriendsIds.remove(friendId);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Amigo eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  _searchUsers();
                } else {
                  setState(() => _searchResults.clear());
                }
              },
              decoration: InputDecoration(
                hintText: 'Buscar usuario',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults.clear());
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            "No hay usuarios que coincidan.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            var user = _searchResults[index];
                            String username = user['username'];
                            String userId = user.id;
                            String? profileImage = user['profileImage'];
                            int level = user['level'] ?? 1;

                            final isSelf = userId == currentUserId;
                            final alreadyFriend = myFriendsIds.contains(userId);

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: (profileImage?.isNotEmpty ?? false)
                                      ? NetworkImage(profileImage!)
                                      : const NetworkImage(
                                          'https://i.ibb.co/tqgf9gt/default-profile.png'),
                                ),
                                title: Text(
                                  username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                subtitle: Text(
                                  'Nivel: $level',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (alreadyFriend)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 28,
                                        ),
                                        tooltip: 'Eliminar amigo',
                                        onPressed: () => _removeFriend(userId),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        alreadyFriend ? Icons.check_circle : Icons.person_add,
                                        color: alreadyFriend
                                            ? Colors.green
                                            : Colors.blueAccent,
                                        size: 28,
                                      ),
                                      tooltip:
                                          alreadyFriend ? 'Amigo' : 'Agregar amigo',
                                      onPressed: (isSelf || alreadyFriend)
                                          ? null
                                          : () => _addFriend(userId, username),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ver perfil de $username')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
