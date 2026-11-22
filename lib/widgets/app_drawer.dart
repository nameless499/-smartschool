import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart'; // 👈 This import fixes the AppRoutes error

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final effectiveRole = authProvider.role ?? '';

    // Get the current path to highlight the active menu item
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey background
      child: Column(
        children: [
          // ==========================================
          // 1. AESTHETIC HEADER (Curved Bottom)
          // ==========================================
          // Header is clickable to go to Profile
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.push(AppRoutes.profile); // Go to profile
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 32,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with white border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    profile?.fullName ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    profile?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. NAVIGATION ITEMS
          // ==========================================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildSectionHeader('MAIN MENU'),

                // Dashboard
                _buildDrawerItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isActive:
                      currentPath == AppRoutes.studentDashboard ||
                      currentPath == AppRoutes.registrarDashboard ||
                      currentPath == AppRoutes.adminDashboard,
                  onTap: () {
                    Navigator.pop(context);
                    if (effectiveRole == 'student') {
                      context.go(AppRoutes.studentDashboard);
                    } else if (effectiveRole == 'registrar') {
                      context.go(AppRoutes.registrarDashboard);
                    } else if (effectiveRole == 'admin') {
                      context.go(AppRoutes.adminDashboard);
                    }
                  },
                ),

                // STUDENT SPECIFIC
                if (effectiveRole == 'student') ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_rounded,
                    label: 'Request Document',
                    isActive: currentPath == AppRoutes.documentRequest,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.documentRequest);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: 'My Requests',
                    isActive: currentPath == AppRoutes.requestStatus,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.requestStatus);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Payments',
                    isActive: currentPath == AppRoutes.payments,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.payments);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.folder_shared_rounded,
                    label: 'Released Docs',
                    isActive: currentPath == AppRoutes.releasedDocs,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.releasedDocs);
                    },
                  ),
                ],

                // REGISTRAR SPECIFIC
                if (effectiveRole == 'registrar') ...[
                  _buildSectionHeader('ACADEMIC TOOLS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_search_rounded,
                    label: 'Student Records',
                    isActive: currentPath == AppRoutes.studentRecords,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.studentRecords);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.document_scanner_rounded,
                    label: 'Scanner',
                    isActive: currentPath == AppRoutes.scanner,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.scanner);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.task_alt_rounded,
                    label: 'Process Requests',
                    isActive: currentPath == AppRoutes.documentProcessing,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.documentProcessing);
                    },
                  ),
                ],

                // ADMIN SPECIFIC
                if (effectiveRole == 'admin') ...[
                  _buildSectionHeader('ADMIN TOOLS'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group_rounded,
                    label: 'Manage Users',
                    isActive: currentPath == AppRoutes.userManagement,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.userManagement);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.psychology_rounded,
                    label: 'Knowledge Base',
                    isActive: currentPath == AppRoutes.chatbotKnowledge,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.chatbotKnowledge);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.school_rounded,
                    label: 'Student Records',
                    isActive: currentPath == AppRoutes.studentRecords,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.studentRecords);
                    },
                  ),
                ],

                // HIDE "MY PROFILE" FOR STUDENTS
                if (effectiveRole == 'registrar' ||
                    effectiveRole == 'admin') ...[
                  _buildSectionHeader('ACCOUNT'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    isActive: currentPath == AppRoutes.profile,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.profile);
                    },
                  ),
                ],
              ],
            ),
          ),

          // ==========================================
          // 3. BOTTOM SIGN OUT
          // ==========================================
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.red.shade300,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to draw section headers (e.g., MAIN MENU)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Helper widget for the navigation items
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            // Highlight active tab with a soft green background
            color: isActive ? const Color(0xFFE8F5E9) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon Pill
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1B5E20) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (!isActive)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Label
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF1B5E20) : Colors.black87,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
