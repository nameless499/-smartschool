import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../routes/app_routes.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/student_bottom_nav_bar.dart';
import '../chatbot/floating_chatbot.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Offset _position = const Offset(20, 400);
  bool _isInitialized = false;

  final DocumentRequestRepository _repository = DocumentRequestRepository();
  bool _isLoading = true;

  // Chart Data
  List<FlSpot> _weeklyData = [];
  bool _hasData = false;
  final Map<int, List<DocumentRequest>> _dailyRequests = {};

  // Quick Stats
  int _totalRequests = 0;
  int _pendingRequests = 0;
  int _completedRequests = 0;

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final email = context.read<AuthProvider>().profile?.email;
      if (email == null) return;

      final requests = await _repository.getStudentRequests(email);

      int pending = 0;
      int completed = 0;
      for (var req in requests) {
        if (req.status.toLowerCase() == 'pending') pending++;
        if (req.status.toLowerCase() == 'completed') completed++;
      }

      final now = DateTime.now();
      final List<FlSpot> spots = [];
      bool hasData = false;

      for (int i = 6; i >= 0; i--) {
        final targetDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final nextDate = targetDate.add(const Duration(days: 1));

        final reqsForDay = requests.where((r) {
          final localCreatedAt = r.createdAt.toLocal();
          return localCreatedAt.isAfter(targetDate) &&
              localCreatedAt.isBefore(nextDate);
        }).toList();

        if (reqsForDay.isNotEmpty) hasData = true;
        _dailyRequests[6 - i] = reqsForDay;
        spots.add(FlSpot((6 - i).toDouble(), reqsForDay.length.toDouble()));
      }

      setState(() {
        _totalRequests = requests.length;
        _pendingRequests = pending;
        _completedRequests = completed;
        _weeklyData = spots;
        _hasData = hasData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 85, size.height - 250);
      _isInitialized = true;
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SmartSchool',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _brandGreenDark,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _brandGreenDark),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.studentProfile),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _brandGreen.withValues(alpha: 0.1),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _brandGreenDark,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          profile?.fullName.isNotEmpty == true
                              ? profile!.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StudentBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _brandGreen,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${profile?.fullName.split(' ').first ?? 'Student'}!',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _brandGreenDark,
                              ),
                            ),
                            const SizedBox(height: 4),

                            const SizedBox(height: 32),

                            // 👇 Quick Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total',
                                    _totalRequests.toString(),
                                    Icons.folder_open_rounded,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Pending',
                                    _pendingRequests.toString(),
                                    Icons.hourglass_top_rounded,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Completed',
                                    _completedRequests.toString(),
                                    Icons.check_circle_rounded,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 👇 Quick Action (My Requests removed, New Request now full width)
                            _buildActionCard(
                              title: 'New Request',
                              icon: Icons.add_circle_outline_rounded,
                              onTap: () =>
                                  context.go(AppRoutes.documentRequest),
                              isPrimary: true,
                            ),
                            const SizedBox(height: 32),

                            // 👇 Chart Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isDesktop
                                    ? [
                                        BoxShadow(
                                          color: _brandGreen.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 15),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _brandGreen.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.show_chart_rounded,
                                            color: _brandGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Weekly Request Activity',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _brandGreenDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      height: 200,
                                      child: !_hasData
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.inbox_rounded,
                                                    size: 48,
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'No requests this week.',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : LineChart(
                                              LineChartData(
                                                lineTouchData:
                                                    _buildLineTouchData(),
                                                gridData: FlGridData(
                                                  show: true,
                                                  drawVerticalLine: false,
                                                  horizontalInterval: 1,
                                                  getDrawingHorizontalLine:
                                                      (value) => FlLine(
                                                        color: Colors.grey
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        strokeWidth: 1,
                                                        dashArray: [5, 5],
                                                      ),
                                                ),
                                                titlesData: _buildTitlesData(),
                                                borderData: FlBorderData(
                                                  show: false,
                                                ),
                                                minX: 0,
                                                maxX: 6,
                                                minY: 0,
                                                maxY: max(
                                                  _weeklyData
                                                          .map((e) => e.y)
                                                          .reduce(max) +
                                                      2,
                                                  5,
                                                ),
                                                lineBarsData: [
                                                  LineChartBarData(
                                                    spots: _weeklyData,
                                                    isCurved: true,
                                                    color: _brandGreen,
                                                    barWidth: 4,
                                                    isStrokeCapRound: true,
                                                    dotData: FlDotData(
                                                      show: true,
                                                      getDotPainter:
                                                          (
                                                            spot,
                                                            percent,
                                                            barData,
                                                            index,
                                                          ) =>
                                                              FlDotCirclePainter(
                                                                radius: 4,
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 2,
                                                                strokeColor:
                                                                    _brandGreen,
                                                              ),
                                                    ),
                                                    belowBarData: BarAreaData(
                                                      show: true,
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          _brandGreen
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          _brandGreen
                                                              .withValues(
                                                                alpha: 0.0,
                                                              ),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // 👇 CHATBOT WIDGET
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final size = MediaQuery.of(context).size;
                    double newX = _position.dx + details.delta.dx;
                    double newY = _position.dy + details.delta.dy;
                    newX = newX.clamp(0.0, size.width - 65);
                    newY = newY.clamp(0.0, size.height - 250);
                    _position = Offset(newX, newY);
                  });
                },
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.5),
                    builder: (context) => const FloatingChatbot(),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A86B), _brandGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandGreen.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _brandGreenDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? _brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? _brandGreen : Colors.grey.shade200,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _brandGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the text
          children: [
            Icon(icon, color: isPrimary ? Colors.white : _brandGreen, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : _brandGreenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: _brandGreenDark,
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.all(12),
        maxContentWidth: 250,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final dayIndex = barSpot.x.toInt();
            final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
            final reqs = _dailyRequests[dayIndex] ?? [];

            String tooltipText = '📅 ${_formatDate(date)}\n';

            if (reqs.isEmpty) {
              tooltipText += 'No requests';
            } else {
              tooltipText += '─────────────\n';
              for (var req in reqs) {
                final time = req.createdAt.toLocal();
                final timeStr =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                String docName = req.documentName;
                if (docName.length > 25)
                  docName = '${docName.substring(0, 22)}...';
                tooltipText += '• $timeStr - $docName\n';
              }
            }

            return LineTooltipItem(
              tooltipText.trim(),
              GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            );
          }).toList();
        },
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final date = DateTime.now().subtract(
              Duration(days: 6 - value.toInt()),
            );
            final dayStr = days[date.weekday - 1];
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                dayStr,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            if (value == value.roundToDouble()) {
              return Text(
                value.toInt().toString(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
