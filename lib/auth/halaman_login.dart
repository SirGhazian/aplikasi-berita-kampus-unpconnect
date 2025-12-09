import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

import '../theme.dart';
import '../utils/audio_helper.dart';
import '../home.dart';
import '../models/user_model.dart';
import '../services/user_session.dart';
import '../pages/admin/admin_dashboard.dart';

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  final TextEditingController uidC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  bool loading = false;

  Future<void> _loginUser() async {
    final uid = uidC.text.trim();
    final password = passC.text.trim();

    if (uid.isEmpty || password.isEmpty) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text('Lengkapi NIM/NIP dan password'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text('Akun tidak ditemukan'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        setState(() => loading = false);
        return;
      }

      final data = doc.data()!;
      if (data['password'] != password) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text('Password salah'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        setState(() => loading = false);
        return;
      }

      UserSession.currentUser = UserModel.fromMap(data);

      if (!mounted) return;
      if (!mounted) return;

      if (UserSession.currentUser!.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text('Terjadi kesalahan, coba lagi'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER BIRU
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 65,
                  horizontal: 25,
                ),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  image: DecorationImage(
                    image: AssetImage('assets/images/login_pattern.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Text(
                  "UNP\nConnect",
                  style: large.copyWith(
                    color: Colors.white,
                    fontSize: 52,
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // FORM LOGIN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // UID (NIM / NIP)
                    TextField(
                      controller: uidC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: primaryColor.withAlpha((0.18 * 255).round()),
                        hintText: "NIM / NIP Portal UNP",
                        hintStyle: regular.copyWith(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 25, right: 8),
                          child: Icon(Icons.badge, color: primaryColor),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD
                    TextField(
                      controller: passC,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: primaryColor.withAlpha((0.18 * 255).round()),
                        hintText: "Password",
                        hintStyle: regular.copyWith(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 25, right: 8),
                          child: Icon(Icons.lock, color: primaryColor),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TOMBOL MASUK
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: loading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Masuk",
                                style: semibold.copyWith(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // INFO PORTAL
                    Text(
                      "Login menggunakan akun Portal UNP.",
                      style: regular.copyWith(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
