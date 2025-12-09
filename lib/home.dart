import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import 'theme.dart';
import 'pages/halaman_beranda.dart';
import 'pages/postingan_kampus.dart';
import 'pages/postingan_mahasiswa.dart';
import 'pages/halaman_profil.dart';
import 'postingan/tambah_postingan.dart';

import 'services/user_session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final PageController pageController = PageController();

  final List<Widget> pages = const [
    HalamanBeranda(),
    PostinganKampus(),
    PostinganMahasiswa(),
    HalamanProfil(),
  ];

  final List<IconData> iconList = [
    Icons.home,
    Icons.school,
    Icons.people,
    Icons.person,
  ];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = UserSession.currentUser?.role == 'mhs-guest';

    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: Container(
        color: backgroundColor,
        child: PageView(
          controller: pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: pages,
        ),
      ),

      floatingActionButton: isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TambahPostingan()),
                );
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: currentIndex,
        height: 70,
        iconSize: 30,
        activeColor: primaryColor,
        inactiveColor: textSecondary,
        backgroundColor: secondaryColor,
        gapLocation: isGuest ? GapLocation.none : GapLocation.center,
        notchSmoothness: NotchSmoothness.defaultEdge,
        leftCornerRadius: 20,
        rightCornerRadius: 20,
        onTap: (index) {
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
