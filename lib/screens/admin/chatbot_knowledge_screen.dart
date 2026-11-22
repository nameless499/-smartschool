import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Aesthetic Font
import '../../widgets/app_drawer.dart';
import '../../widgets/blurred_background.dart'; // ✅ Blurred Background
import '../../routes/app_routes.dart';

class ChatbotKnowledgeScreen extends StatefulWidget {
  const ChatbotKnowledgeScreen({super.key});

  @override
  State<ChatbotKnowledgeScreen> createState() => _ChatbotKnowledgeScreenState();
}

class _ChatbotKnowledgeScreenState extends State<ChatbotKnowledgeScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
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
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client
          .from('chatbot_knowledge')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _entries = List<Map<String, dynamic>>.from(response);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load knowledge base: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _entries.where((e) {
        if (_filterCategory != 'All') {
          final category = (e['category'] as String? ?? '').toLowerCase();
          if (category != _filterCategory.toLowerCase()) return false;
        }
        if (query.isEmpty) return true;
        final q = (e['question'] as String? ?? '').toLowerCase();
        final a = (e['answer'] as String? ?? '').toLowerCase();
        return q.contains(query) || a.contains(query);
      }).toList();
    });
  }

  Future<void> _showEditor({Map<String, dynamic>? existing}) async {
    final questionCtrl = TextEditingController(
      text: existing?['question'] as String? ?? '',
    );
    final answerCtrl = TextEditingController(
      text: existing?['answer'] as String? ?? '',
    );
    String category = existing?['category'] as String? ?? 'General';

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            existing == null ? 'Add FAQ' : 'Edit FAQ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _categories
                        .where((c) => c != 'All')
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: GoogleFonts.poppins()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: questionCtrl,
                    style: GoogleFonts.poppins(),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      hintText: 'e.g., What are the requirements for TOR?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: answerCtrl,
                    style: GoogleFonts.poppins(),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Answer',
                      hintText: 'Enter the official response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final question = questionCtrl.text.trim();
                final answer = answerCtrl.text.trim();
                if (question.isEmpty || answer.isEmpty) return;

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
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', existing['id']);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: $e',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                existing == null ? 'Add' : 'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null ? '✅ FAQ added' : '✅ FAQ updated',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete FAQ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete this FAQ?\n\n"${entry['question']}"',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('chatbot_knowledge').delete().eq('id', entry['id']);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FAQ deleted', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> entry) async {
    try {
      await _client
          .from('chatbot_knowledge')
          .update({
            'active': !(entry['active'] as bool? ?? true),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', entry['id']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Knowledge Base',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go(AppRoutes.adminDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add FAQ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlurredBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.85),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final selected = cat == _filterCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _filterCategory = cat);
                          _applyFilter();
                        },
                        selectedColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.white.withOpacity(0.85),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      )
                    : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.help_outline,
                              size: 48,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No FAQs found.',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1B5E20),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) =>
                              _buildFAQCard(_filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> entry) {
    final isActive = entry['active'] as bool? ?? true;

    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.85),
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          Icons.help_outline_rounded,
          color: isActive ? const Color(0xFF1B5E20) : Colors.grey,
        ),
        title: Text(
          entry['question'] as String? ?? '',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry['category'] as String? ?? 'General',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isActive)
              Text(
                'INACTIVE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry['answer'] as String? ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditor(existing: entry),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _delete(entry),
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
