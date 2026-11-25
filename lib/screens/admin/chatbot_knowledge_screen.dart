import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/app_drawer.dart';
import '../../routes/app_routes.dart';

class ChatbotKnowledgeScreen extends StatefulWidget {
  const ChatbotKnowledgeScreen({super.key});

  @override
  State<ChatbotKnowledgeScreen> createState() => _ChatbotKnowledgeScreenState();
}

class _ChatbotKnowledgeScreenState extends State<ChatbotKnowledgeScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  static const Color primary = Color(0xFF176B3A);
  static const Color secondary = Color(0xFF2E9B61);
  static const Color background = Color(0xFFF5F8F6);
  static const Color textDark = Color(0xFF1D3025);

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _filterCategory = 'All';

  final List<String> _categories = [
    'All',
    'Policies',
    'Procedures',
    'Requirements',
    'Fees',
    'Enrollment',
    'Graduation',
    'Documents',
    'General',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  // LOAD KNOWLEDGE BASE
  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client
          .from('chatbot_knowledge')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _entries = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load knowledge base: $e';
        _isLoading = false;
      });
    }
  }

  // SEARCH AND CATEGORY FILTER
  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();

    final results = _entries.where((entry) {
      if (_filterCategory != 'All') {
        final category = (entry['category'] ?? '').toString().toLowerCase();

        if (category != _filterCategory.toLowerCase()) {
          return false;
        }
      }

      if (query.isEmpty) return true;

      final question = (entry['question'] ?? '').toString().toLowerCase();
      final answer = (entry['answer'] ?? '').toString().toLowerCase();

      return question.contains(query) || answer.contains(query);
    }).toList();

    if (!mounted) return;

    setState(() {
      _filtered = results;
    });
  }

  // CATEGORY COUNT
  int _countCategory(String category) {
    if (category == 'All') return _entries.length;

    return _entries.where((entry) {
      return (entry['category'] ?? '').toString().toLowerCase() ==
          category.toLowerCase();
    }).length;
  }

  // ACTIVE COUNT
  int get _activeCount {
    return _entries.where((entry) {
      return entry['active'] as bool? ?? true;
    }).length;
  }

  // INACTIVE COUNT
  int get _inactiveCount {
    return _entries.length - _activeCount;
  }

  // NOTIFICATION
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: isError ? Colors.red : primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      padding: const EdgeInsets.all(15),
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
            width: 38,
            height: 38,
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
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        const spacing = 12.0;

        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Total FAQs',
                value: _isLoading ? '...' : '${_entries.length}',
                icon: Icons.library_books_outlined,
                iconColor: primary,
                iconBackground: const Color(0xFFE4F2E9),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Active FAQs',
                value: _isLoading ? '...' : '$_activeCount',
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF2877B8),
                iconBackground: const Color(0xFFE7F1FA),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Inactive FAQs',
                value: _isLoading ? '...' : '$_inactiveCount',
                icon: Icons.visibility_off_outlined,
                iconColor: const Color(0xFFB17A24),
                iconBackground: const Color(0xFFFFF3DD),
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
        hintText: 'Search questions or answers...',
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

  // CATEGORY FILTERS
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final selected = _filterCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : textDark,
                ),
              ),
              selected: selected,
              selectedColor: primary,
              backgroundColor: const Color(0xFFF0F4F1),
              side: BorderSide.none,
              onSelected: (value) {
                if (!value) return;

                setState(() {
                  _filterCategory = category;
                });

                _applyFilter();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // CATEGORY BADGE
  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        category,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }

  // ADD / EDIT FAQ DIALOG
  Future<void> _showEditor({Map<String, dynamic>? existing}) async {
    final questionCtrl = TextEditingController(
      text: existing?['question'] as String? ?? '',
    );

    final answerCtrl = TextEditingController(
      text: existing?['answer'] as String? ?? '',
    );

    String category = existing?['category'] as String? ?? 'General';

    bool saving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                existing == null ? 'Add FAQ' : 'Edit FAQ',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _categories
                                .where((c) => c != 'All')
                                .contains(category)
                            ? category
                            : 'General',
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _categories
                            .where((c) => c != 'All')
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  category = value ?? category;
                                });
                              },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Question',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: questionCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'e.g. What are the requirements for TOR?',
                          hintStyle: GoogleFonts.poppins(fontSize: 11),
                          filled: true,
                          fillColor: background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Answer',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: answerCtrl,
                        maxLines: 6,
                        style: GoogleFonts.poppins(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter the official response...',
                          hintStyle: GoogleFonts.poppins(fontSize: 11),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final question = questionCtrl.text.trim();
                          final answer = answerCtrl.text.trim();

                          if (question.isEmpty || answer.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter both a question and an answer.',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            if (existing == null) {
                              await _client.from('chatbot_knowledge').insert({
                                'category': category,
                                'question': question,
                                'answer': answer,
                                'source': 'manual',
                                'active': true,
                              });
                            } else {
                              await _client
                                  .from('chatbot_knowledge')
                                  .update({
                                    'category': category,
                                    'question': question,
                                    'answer': answer,
                                    'updated_at': DateTime.now()
                                        .toIso8601String(),
                                  })
                                  .eq('id', existing['id']);
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: $e',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          existing == null ? 'Add FAQ' : 'Save Changes',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      );

      if (saved == true) {
        await _load();
        _showMessage(
          existing == null
              ? 'FAQ added successfully.'
              : 'FAQ updated successfully.',
        );
      }
    } finally {
      questionCtrl.dispose();
      answerCtrl.dispose();
    }
  }

  // DELETE FAQ
  Future<void> _delete(Map<String, dynamic> entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete FAQ?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this FAQ?\n\n'
          '"${entry['question']}"',
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
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
      await _client.from('chatbot_knowledge').delete().eq('id', entry['id']);

      await _load();
      _showMessage('FAQ deleted successfully.');
    } catch (e) {
      _showMessage('Failed to delete FAQ: $e', isError: true);
    }
  }

  // ACTIVATE / DEACTIVATE FAQ
  Future<void> _toggleActive(Map<String, dynamic> entry) async {
    final current = entry['active'] as bool? ?? true;

    try {
      await _client
          .from('chatbot_knowledge')
          .update({
            'active': !current,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', entry['id']);

      await _load();

      _showMessage(
        current
            ? 'FAQ deactivated successfully.'
            : 'FAQ activated successfully.',
      );
    } catch (e) {
      _showMessage('Failed to update FAQ: $e', isError: true);
    }
  }

  // FAQ CARD
  Widget _buildFAQCard(Map<String, dynamic> entry) {
    final isActive = entry['active'] as bool? ?? true;
    final question = (entry['question'] ?? '').toString();
    final answer = (entry['answer'] ?? '').toString();
    final category = (entry['category'] ?? 'General').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isActive ? primary : Colors.grey).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: isActive ? primary : Colors.grey,
              size: 21,
            ),
          ),
          title: Text(
            question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? textDark : Colors.grey,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _categoryBadge(category),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANSWER',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      answer,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleActive(entry),
                        icon: Icon(
                          isActive
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isActive ? 'Deactivate' : 'Activate',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditor(existing: entry),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _delete(entry),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FAQ LIST
  Widget _buildFAQList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(45),
        child: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 45),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
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
      );
    }

    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 55),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'No FAQs found.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              Text(
                'Try another search or category.',
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

    return Column(children: _filtered.map(_buildFAQCard).toList());
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
          'Knowledge Base',
          style: GoogleFonts.poppins(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.adminDashboard),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh knowledge base',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EFEA), height: 1),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add FAQ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _load,
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
                    'Chatbot Knowledge Base',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Manage the questions and answers used by the SmartSchool chatbot.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SUMMARY
                  _buildSummaryCards(),

                  const SizedBox(height: 26),

                  // KNOWLEDGE DIRECTORY
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
                          'Knowledge Entries',
                          'Add, update, and organize chatbot responses',
                          Icons.psychology_outlined,
                        ),

                        const SizedBox(height: 22),

                        _buildSearchBar(),

                        const SizedBox(height: 16),

                        _buildCategoryFilters(),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'FAQ Directory',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${_filtered.length} entries',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        _buildFAQList(),
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

                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
