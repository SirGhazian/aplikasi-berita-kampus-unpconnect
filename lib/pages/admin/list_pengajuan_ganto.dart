import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toastification/toastification.dart';
import '../../theme.dart';
import '../../utils/audio_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ListPengajuanGanto extends StatefulWidget {
  const ListPengajuanGanto({super.key});

  @override
  State<ListPengajuanGanto> createState() => _ListPengajuanGantoState();
}

class _ListPengajuanGantoState extends State<ListPengajuanGanto> {
  late Stream<List<UserModel>> _usersStream;
  String? _processingUid; // TRACK USER MANA YANG DIPAKAI

  @override
  void initState() {
    super.initState();
    _usersStream = FirestoreService().getAllUsers();
  }

  Future<void> _handleVerification(
    String uid,
    bool isApproved,
    String userName,
  ) async {
    setState(() {
      _processingUid = uid;
    });

    try {
      if (isApproved) {
        await FirestoreService().updateGantoVerificationStatus(
          uid,
          'verified',
          newRole: 'mhs-ganto',
        );
      } else {
        await FirestoreService().updateGantoVerificationStatus(
          uid,
          '',
          newRole: 'mhs-guest', // RESET JIKA REJECTED
        );
      }

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: Text(
            "Pengajuan $userName ${isApproved ? 'diterima' : 'ditolak'}",
          ),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: Text("Gagal memproses: $e"),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingUid = null;
        });
      }
    }
  }

  void _showProofDialog(String imageUrl, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Bukti Keanggotaan",
                    style: medium.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    userName,
                    style: semibold.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Tutup",
                            style: semibold.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "List Pengajuan Ganto",
          style: semibold.copyWith(fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final users = snapshot.data ?? [];
          final pendingUsers = users
              .where((user) => user.statusVerifikasiGanto == 'pending')
              .toList();

          if (pendingUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada pengajuan pending",
                    style: regular.copyWith(color: textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CachedNetworkImage(
                            imageUrl: user.fotoProfil,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nama,
                                style: semibold.copyWith(fontSize: 14),
                              ),
                              Text(
                                "${user.prodi} - ${user.fakultas}",
                                style: regular.copyWith(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (user.buktiKeanggotaan != null)
                      GestureDetector(
                        onTap: () =>
                            _showProofDialog(user.buktiKeanggotaan!, user.nama),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 18,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Lihat Bukti Keanggotaan",
                                style: medium.copyWith(
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _processingUid == user.uid
                                ? null
                                : () => _handleVerification(
                                    user.uid,
                                    false,
                                    user.nama,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _processingUid == user.uid
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Text(
                                    "Tolak",
                                    style: semibold.copyWith(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _processingUid == user.uid
                                ? null
                                : () => _handleVerification(
                                    user.uid,
                                    true,
                                    user.nama,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[50],
                              foregroundColor: Colors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _processingUid == user.uid
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                : Text(
                                    "Terima",
                                    style: semibold.copyWith(
                                      color: Colors.green,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
