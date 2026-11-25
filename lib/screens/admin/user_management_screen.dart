import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/app_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  static const Color primary = Color(0xFF176B3A);
  static const Color secondary = Color(0xFF2E9B61);
  static const Color background = Color(0xFFF5F8F6);
  static const Color textDark = Color(0xFF1D3025);

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _isLoading = true;
  String? _error;
  String _filterRole = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  // LOAD USERS
  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  // SEARCH AND FILTER
  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();

    final results = _users.where((user) {
      final role = (user['role'] ?? '').toString().toLowerCase();

      if (_filterRole != 'All' && role != _filterRole.toLowerCase()) {
        return false;
      }

      if (query.isEmpty) return true;

      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final studentId = (user['student_id'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          studentId.contains(query);
    }).toList();

    if (!mounted) return;

    setState(() {
      _filtered = results;
    });
  }

  // COUNT USERS BY ROLE
  int _countRole(String role) {
    if (role == 'All') return _users.length;

    return _users.where((user) {
      return (user['role'] ?? '').toString().toLowerCase() ==
          role.toLowerCase();
    }).length;
  }

  // ROLE COLORS
  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'registrar':
        return const Color(0xFF2877B8);
      case 'student':
        return primary;
      default:
        return Colors.grey;
    }
  }

  // DELETE USER PROFILE
  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final name = (user['full_name'] ?? 'this user').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete User Profile?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the profile of $name?\n\n'
          'This action deletes the profile record only. '
          'It does not automatically delete the Supabase Auth account.',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('profiles').delete().eq('id', user['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User profile deleted successfully.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete user: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // SECTION TITLE
  Widget _sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SUMMARY CARD
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // RESPONSIVE SUMMARY CARDS
  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;

        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Total Users',
                value: _isLoading ? '...' : '${_countRole('All')}',
                icon: Icons.people_alt_outlined,
                iconColor: primary,
                iconBackground: const Color(0xFFE4F2E9),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Students',
                value: _isLoading ? '...' : '${_countRole('Student')}',
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF2877B8),
                iconBackground: const Color(0xFFE7F1FA),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Registrar Staff',
                value: _isLoading ? '...' : '${_countRole('Registrar')}',
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFFB17A24),
                iconBackground: const Color(0xFFFFF3DD),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Administrators',
                value: _isLoading ? '...' : '${_countRole('Admin')}',
                icon: Icons.admin_panel_settings_outlined,
                iconColor: Colors.deepPurple,
                iconBackground: const Color(0xFFF0E9FA),
              ),
            ),
          ],
        );
      },
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(fontSize: 13, color: textDark),
      decoration: InputDecoration(
        hintText: 'Search by name, email, or ID...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _searchController.clear,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F8F6),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ROLE FILTERS
  Widget _buildRoleFilters() {
    final roles = ['All', 'Student', 'Registrar', 'Admin'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((role) {
          final selected = _filterRole == role;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                role,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              selected: selected,
              selectedColor: primary,
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
              onSelected: (value) {
                if (!value) return;

                setState(() {
                  _filterRole = role;
                });

                _applyFilter();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // USER CARD
  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = (user['role'] ?? 'student').toString();
    final name = (user['full_name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final studentId = (user['student_id'] ?? '').toString();
    final avatarUrl = (user['avatar_url'] ?? '').toString();

    final color = _roleColor(role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EFEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.10),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (role.toLowerCase() == 'student' && studentId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Student ID: $studentId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Delete user profile',
            onPressed: () => _deleteUser(user),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // USER DIRECTORY CONTENT
  // Uses Wrap instead of nested ListView/GridView.
  // The main page handles scrolling.
  Widget _buildUserList() {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 45, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'No users found.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Try changing your search or filter.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 2 : 1;

        const spacing = 12.0;

        final cardWidth = columns == 2
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _filtered.map((user) {
            return SizedBox(width: cardWidth, child: _buildUserCard(user));
          }).toList(),
        );
      },
    );
  }

  // MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: background,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh users',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EFEA), height: 1),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadUsers,
        color: primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? 28 : 18,
            vertical: 22,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Manage student, registrar, and administrator accounts.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SUMMARY CARDS
                  _buildSummaryCards(),

                  const SizedBox(height: 26),

                  // USER DIRECTORY
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth > 600 ? 20 : 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8EFEA)),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.035),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Registered Users',
                          'View and manage system accounts',
                          Icons.manage_accounts_outlined,
                        ),

                        const SizedBox(height: 22),

                        _buildSearchBar(),

                        const SizedBox(height: 16),

                        _buildRoleFilters(),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'User Directory',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${_filtered.length} users',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildUserList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      'SmartSchool • Medina Ipil College',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
