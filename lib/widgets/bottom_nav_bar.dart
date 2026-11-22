import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // 👈 Added for styling
import '../routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final String role;
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.role,
    required this.currentIndex,
  });

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);

  @override
  Widget build(BuildContext context) {
    // Admin uses drawer/sidebar, so hide bottom nav
    if (role == 'admin') return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _brandGreen,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        onTap: (index) {
          if (role == 'student') {
            switch (index) {
              case 0:
                context.go(AppRoutes.studentDashboard);
                break;
              case 1:
                context.go(AppRoutes.chatbot);
                break;
              case 2:
                context.go(AppRoutes.studentProfile);
                break;
            }
          } else if (role == 'registrar') {
            switch (index) {
              case 0:
                context.go(AppRoutes.registrarDashboard);
                break;
              case 1:
                context.go(AppRoutes.studentRecords);
                break;
              case 2:
                context.go(AppRoutes.scanner);
                break;
            }
          }
        },
        items: role == 'student'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded, color: _brandGreenDark),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(
                    Icons.chat_bubble_rounded,
                    color: _brandGreenDark,
                  ),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(
                    Icons.person_rounded,
                    color: _brandGreenDark,
                  ),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(
                    Icons.dashboard_rounded,
                    color: _brandGreenDark,
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_search_rounded),
                  activeIcon: Icon(
                    Icons.manage_search_rounded,
                    color: _brandGreenDark,
                  ),
                  label: 'Records',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_rounded),
                  activeIcon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _brandGreenDark,
                  ),
                  label: 'Scanner',
                ),
              ],
      ),
    );
  }
}
