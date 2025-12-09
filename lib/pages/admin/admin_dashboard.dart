import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../../theme.dart';
import 'kelola_postingan_kampus.dart';
import 'kelola_postingan_mahasiswa.dart';
import 'kelola_user.dart';
import 'kelola_ganto.dart';
import 'profil_admin.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 0;

  final List<Widget> _pages = const [
    KelolaPostinganKampus(),
    KelolaPostinganMahasiswa(),
    KelolaUser(),
    KelolaGanto(),
    ProfilAdmin(),
  ];

  final List<IconData> _iconList = [
    Icons.school,
    Icons.newspaper,
    Icons.manage_accounts,
    Icons.people,
    Icons.person,
  ];

  final List<String> _labels = [
    'Kampus',
    'Mahasiswa',
    'User',
    'Ganto',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _pages[_bottomNavIndex],
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        height: 75,
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? primaryColor : textSecondary;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconList[index], size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                _labels[index],
                style: isActive
                    ? semibold.copyWith(fontSize: 10, color: color)
                    : regular.copyWith(fontSize: 10, color: color),
              ),
            ],
          );
        },
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.defaultEdge,
        leftCornerRadius: 20,
        rightCornerRadius: 20,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        backgroundColor: Colors.white,
      ),
    );
  }
}
