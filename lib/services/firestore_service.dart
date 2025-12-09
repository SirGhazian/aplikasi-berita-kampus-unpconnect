import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/postingan_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PostinganModel>> getBeritaKampus() {
    return _db
        .collection('berita_kampus')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostinganModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<PostinganModel>> getBeritaMahasiswa() {
    return _db
        .collection('berita_mahasiswa')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostinganModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<PostinganModel>> getAllPosts() async* {
    await for (final kampusSnapshot
        in _db.collection('berita_kampus').snapshots()) {
      final mahasiswaSnapshot = await _db.collection('berita_mahasiswa').get();

      final allPosts = <PostinganModel>[];

      // Tambah kampus posts
      allPosts.addAll(
        kampusSnapshot.docs.map((doc) => PostinganModel.fromFirestore(doc)),
      );

      // Tambah mahasiswa posts
      allPosts.addAll(
        mahasiswaSnapshot.docs.map((doc) => PostinganModel.fromFirestore(doc)),
      );

      yield allPosts;
    }
  }

  Future<void> addPost(PostinganModel post, String collectionName) async {
    // Generate custom document ID: MM-DD_10randomchars
    final now = DateTime.now();
    final monthDay =
        '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final randomChars = _generateRandomString(10);
    final customDocId = '${monthDay}_$randomChars';

    // Create document custom ID
    await _db.collection(collectionName).doc(customDocId).set(post.toMap());

    await _db.collection('users').doc(post.uidPengunggah).update({
      'listPostingan': FieldValue.arrayUnion([customDocId]),
    });
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> incrementView({
    required String postId,
    required String collectionName,
    required String currentUserId,
    required String authorId,
  }) async {
    // jangan tambah increment jika user adalah author
    if (currentUserId == authorId) return;

    final docRef = _db.collection(collectionName).doc(postId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return;

    final data = docSnapshot.data()!;
    final viewedBy = List<String>.from(data['viewedBy'] ?? []);

    // cek apakah sudah dilihat
    if (viewedBy.contains(currentUserId)) return;

    // Increment
    await docRef.update({
      'views': FieldValue.increment(1),
      'viewedBy': FieldValue.arrayUnion([currentUserId]),
    });
  }

  Future<void> validateAndUpdateUserPosts(String uid, String role) async {
    String collection;
    if (role == 'dosen') {
      collection = 'berita_kampus';
    } else if (role == 'mhs-ganto') {
      collection = 'berita_mahasiswa';
    } else {
      return; // No posts for other roles
    }

    // Fetch collection
    final postsSnapshot = await _db
        .collection(collection)
        .where('uidPengunggah', isEqualTo: uid)
        .get();

    // Get list post IDs
    final actualPostIds = postsSnapshot.docs.map((doc) => doc.id).toList();

    // Update user listPostingan
    await _db.collection('users').doc(uid).update({
      'listPostingan': actualPostIds,
    });
  }

  Stream<List<PostinganModel>> getUserPosts(String uid, String role) {
    String collection;
    if (role == 'dosen') {
      collection = 'berita_kampus';
    } else if (role == 'mhs-ganto') {
      collection = 'berita_mahasiswa';
    } else {
      return Stream.value([]);
    }

    return _db
        .collection(collection)
        .where('uidPengunggah', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => PostinganModel.fromFirestore(doc))
              .toList();

          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return posts;
        });
  }

  Future<void> deletePost(String postId, String collectionName) async {
    try {
      // hapus dari collection
      await _db.collection(collectionName).doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost(
    String postId,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(collectionName).doc(postId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Get user data
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;

      final kampusPosts = await _db
          .collection('berita_kampus')
          .where('uidPengunggah', isEqualTo: uid)
          .get();
      for (var doc in kampusPosts.docs) {
        await doc.reference.delete();
      }

      final mahasiswaPosts = await _db
          .collection('berita_mahasiswa')
          .where('uidPengunggah', isEqualTo: uid)
          .get();
      for (var doc in mahasiswaPosts.docs) {
        await doc.reference.delete();
      }

      // hapus dokumen user
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'password': user.password,
        'nama': user.nama,
        'fotoProfil': user.fotoProfil,
        'bio': user.bio,
        'fakultas': user.fakultas,
        'prodi': user.prodi,
        'role': user.role,
        'statusVerifikasiGanto': user.statusVerifikasiGanto,
        'listFollowers': user.listFollowers,
        'listFollowing': user.listFollowing,
        'listPostingan': user.listPostingan,
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<Map<String, int>> getAdminStatistics() {
    return _db.collection('users').snapshots().asyncMap((userSnapshot) async {
      final kampusSnapshot = await _db.collection('berita_kampus').get();
      final mahasiswaSnapshot = await _db.collection('berita_mahasiswa').get();

      int dosenPosts = kampusSnapshot.docs.length;
      int mahasiswaPosts = mahasiswaSnapshot.docs.length;

      int dosenUsers = 0;
      int mahasiswaUsers = 0;
      int gantoMembers = 0;

      for (var doc in userSnapshot.docs) {
        final role = doc.data()['role'] as String? ?? '';
        if (role == 'dosen') {
          dosenUsers++;
        } else if (role == 'mhs-guest' || role == 'mhs-ganto') {
          mahasiswaUsers++;
          if (role == 'mhs-ganto') {
            gantoMembers++;
          }
        }
      }

      return {
        'dosenPosts': dosenPosts,
        'mahasiswaPosts': mahasiswaPosts,
        'dosenUsers': dosenUsers,
        'mahasiswaUsers': mahasiswaUsers,
        'gantoMembers': gantoMembers,
      };
    });
  }

  Future<void> updateGantoVerificationStatus(
    String uid,
    String status, {
    String? newRole,
  }) async {
    try {
      final data = <String, dynamic>{'statusVerifikasiGanto': status};

      if (newRole != null) {
        data['role'] = newRole;
      }

      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitGantoApplication(String uid, String buktiUrl) async {
    try {
      await _db.collection('users').doc(uid).update({
        'statusVerifikasiGanto': 'pending',
        'buktiKeanggotaan': buktiUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeGantoMember(String uid) async {
    try {
      // Delete all posts by this user
      final kampusPosts = await _db
          .collection('berita_kampus')
          .where('uidPengunggah', isEqualTo: uid)
          .get();
      for (var doc in kampusPosts.docs) {
        await doc.reference.delete();
      }

      final mahasiswaPosts = await _db
          .collection('berita_mahasiswa')
          .where('uidPengunggah', isEqualTo: uid)
          .get();
      for (var doc in mahasiswaPosts.docs) {
        await doc.reference.delete();
      }

      // Update user role, status, dan clear post list
      await _db.collection('users').doc(uid).update({
        'role': 'mhs-guest',
        'statusVerifikasiGanto': '',
        'listPostingan': [],
        'buktiKeanggotaan': FieldValue.delete(), // Optional: remove proof image
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> followUser(String currentUid, String targetUid) async {
    try {
      final batch = _db.batch();

      final currentUserRef = _db.collection('users').doc(currentUid);
      final targetUserRef = _db.collection('users').doc(targetUid);

      batch.update(currentUserRef, {
        'listFollowing': FieldValue.arrayUnion([targetUid]),
      });

      batch.update(targetUserRef, {
        'listFollowers': FieldValue.arrayUnion([currentUid]),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    try {
      final batch = _db.batch();

      final currentUserRef = _db.collection('users').doc(currentUid);
      final targetUserRef = _db.collection('users').doc(targetUid);

      batch.update(currentUserRef, {
        'listFollowing': FieldValue.arrayRemove([targetUid]),
      });

      batch.update(targetUserRef, {
        'listFollowers': FieldValue.arrayRemove([currentUid]),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isFollowing(String currentUid, String targetUid) async {
    try {
      final doc = await _db.collection('users').doc(currentUid).get();
      if (doc.exists) {
        final List<dynamic> following = doc.data()?['listFollowing'] ?? [];
        return following.contains(targetUid);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    try {
      final futures = uids.map((uid) => _db.collection('users').doc(uid).get());
      final snapshots = await Future.wait(futures);

      return snapshots
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
