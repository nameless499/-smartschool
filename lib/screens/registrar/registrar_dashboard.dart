import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/notification_bell.dart';

class RegistrarDashboard extends StatefulWidget {
  const RegistrarDashboard({super.key});

  @override
  State<RegistrarDashboard> createState() => _RegistrarDashboardState();
}

class _RegistrarDashboardState extends State<RegistrarDashboard> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();

  bool _isLoading = true;
  List<DocumentRequest> _allRequests = [];

  // Filter State
  String _filterMode = 'Daily'; // 'Daily', 'Weekly', 'Monthly'

  // Chart Data
  List<FlSpot> _chartSpots = [];
  List<String> _xAxisLabels = [];
  double _maxY = 5;

  // Map to store requests for the tooltip and the side list
  final Map<int, List<DocumentRequest>> _bucketRequests = {};

  // Most Requested Data
  List<MapEntry<String, int>> _mostRequested = [];

  // Actionable Stats
  int _pendingCount = 0;
  int _processingCount = 0;
  int _completedCount = 0;

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final requests = await _repository.getAllRequests();

      int pending = 0;
      int processing = 0;
      int completed = 0;

      for (var req in requests) {
        final status = req.status.toLowerCase();
        if (status == 'pending') pending++;
        if (status == 'processing') processing++;
        if (status == 'completed') completed++;
      }

      if (mounted) {
        setState(() {
          _allRequests = requests;
          _pendingCount = pending;
          _processingCount = processing;
          _completedCount = completed;

          _calculateChartData();
          _calculateMostRequested();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
      }
    }
  }

  void _calculateChartData() {
    final now = DateTime.now();
    List<FlSpot> spots = [];
    List<String> labels = [];
    double maxVal = 5;

    _bucketRequests.clear();

    if (_filterMode == 'Daily') {
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final reqsForDay = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(date) && local.isBefore(nextDate);
        }).toList();

        _bucketRequests[6 - i] = reqsForDay;
        spots.add(FlSpot((6 - i).toDouble(), reqsForDay.length.toDouble()));
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        labels.add(days[date.weekday - 1]);
        if (reqsForDay.length > maxVal) maxVal = reqsForDay.length.toDouble();
      }
    } else if (_filterMode == 'Weekly') {
      for (int i = 3; i >= 0; i--) {
        final endDate = now.subtract(Duration(days: i * 7));
        final startDate = endDate.subtract(const Duration(days: 7));

        final reqsForWeek = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(startDate) && local.isBefore(endDate);
        }).toList();

        _bucketRequests[3 - i] = reqsForWeek;
        spots.add(FlSpot((3 - i).toDouble(), reqsForWeek.length.toDouble()));
        labels.add('Wk ${4 - i}');
        if (reqsForWeek.length > maxVal) maxVal = reqsForWeek.length.toDouble();
      }
    } else {
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final nextDate = DateTime(now.year, now.month - i + 1, 1);

        final reqsForMonth = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(date) && local.isBefore(nextDate);
        }).toList();

        _bucketRequests[5 - i] = reqsForMonth;
        spots.add(FlSpot((5 - i).toDouble(), reqsForMonth.length.toDouble()));
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
        labels.add(months[date.month - 1]);
        if (reqsForMonth.length > maxVal)
          maxVal = reqsForMonth.length.toDouble();
      }
    }

    _chartSpots = spots;
    _xAxisLabels = labels;
    _maxY = maxVal + 2;
  }

  void _calculateMostRequested() {
    final Map<String, int> counts = {};
    for (var req in _allRequests) {
      counts[req.documentName] = (counts[req.documentName] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _mostRequested = sortedEntries.take(5).toList();
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Registrar Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _brandGreenDark,
          ),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _brandGreenDark),
        actions: const [NotificationBell(), SizedBox(width: 16)],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _brandGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GREETING
                    Text(
                      'Welcome, ${profile?.fullName.split(' ').first ?? 'Registrar'}!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _brandGreenDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is the overview of student requests.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // QUICK STATS
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            _pendingCount.toString(),
                            Icons.pending_actions_rounded,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Processing',
                            _processingCount.toString(),
                            Icons.autorenew_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            _completedCount.toString(),
                            Icons.check_circle_rounded,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // CHART CARD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDesktop
                            ? [
                                BoxShadow(
                                  color: _brandGreen.withValues(alpha: 0.05),
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
                                    color: _brandGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.show_chart_rounded,
                                    color: _brandGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Request Volume',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _brandGreenDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['Daily', 'Weekly', 'Monthly'].map((
                                  mode,
                                ) {
                                  final isSelected = _filterMode == mode;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        mode,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: _brandGreen,
                                      backgroundColor: Colors.grey.shade100,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      side: BorderSide.none,
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() {
                                            _filterMode = mode;
                                            _calculateChartData();
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 👇 SIDE-BY-SIDE LAYOUT FOR CHART AND RECENT REQUESTS
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Get all requests from the current filter
                                List<DocumentRequest> visibleRequests = [];
                                for (var reqs in _bucketRequests.values) {
                                  visibleRequests.addAll(reqs);
                                }
                                visibleRequests.sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt),
                                );

                                if (constraints.maxWidth > 600) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: _buildChart()),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        flex: 2,
                                        child: _buildRecentRequestsList(
                                          visibleRequests,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildChart(),
                                      const SizedBox(height: 24),
                                      _buildRecentRequestsList(visibleRequests),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MOST REQUESTED CARD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDesktop
                            ? [
                                BoxShadow(
                                  color: _brandGreen.withValues(alpha: 0.05),
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
                                    color: _brandGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: _brandGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Most Requested Documents',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _brandGreenDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: _brandGreen,
                                ),
                              )
                            else if (_mostRequested.isEmpty)
                              Center(
                                child: Text(
                                  'No requests yet.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              ..._mostRequested.map((entry) {
                                final totalReqs = _allRequests.length;
                                final percentage =
                                    (entry.value / totalReqs) * 100;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${entry.value} reqs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey.shade100,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(_brandGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 👇 The Chart Widget
  Widget _buildChart() {
    return SizedBox(
      height: 250,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGreen))
          : LineChart(
              LineChartData(
                lineTouchData: _buildLineTouchData(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: _buildTitlesData(),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_xAxisLabels.length - 1).toDouble(),
                minY: 0,
                maxY: _maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartSpots,
                    isCurved: true,
                    color: _brandGreen,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: _brandGreen,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _brandGreen.withValues(alpha: 0.2),
                          _brandGreen.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 👇 The Recent Requests List Widget
  Widget _buildRecentRequestsList(List<DocumentRequest> requests) {
    if (requests.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'No requests found.',
          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Requests in this Period',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _brandGreenDark,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: requests.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white),
              itemBuilder: (context, index) {
                final req = requests[index];
                final name = req.studentName;
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _brandGreen.withValues(alpha: 0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _brandGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    req.documentName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDate(req.createdAt.toLocal()),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            final index = barSpot.x.toInt();
            final reqs = _bucketRequests[index] ?? [];

            String title = '';
            if (_filterMode == 'Daily') {
              final date = DateTime.now().subtract(Duration(days: 6 - index));
              title = _formatDate(date);
            } else if (_filterMode == 'Weekly') {
              final endDate = DateTime.now().subtract(
                Duration(days: (3 - index) * 7),
              );
              final startDate = endDate.subtract(const Duration(days: 7));
              title = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
            } else {
              final date = DateTime(
                DateTime.now().year,
                DateTime.now().month - (5 - index),
                1,
              );
              title = '${_formatMonth(date.month)} ${date.year}';
            }

            String tooltipText = '📅 $title\n';

            if (reqs.isEmpty) {
              tooltipText += 'No requests';
            } else {
              tooltipText += '─────────────\n';
              final displayLimit = 4;
              for (int i = 0; i < reqs.length && i < displayLimit; i++) {
                final req = reqs[i];
                String docName = req.documentName;
                if (docName.length > 15)
                  docName = '${docName.substring(0, 13)}...';
                tooltipText +=
                    '• ${req.studentName.split(' ').first} - $docName\n';
              }
              if (reqs.length > displayLimit) {
                tooltipText += '...and ${reqs.length - displayLimit} more';
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
            final index = value.toInt();
            if (index >= 0 && index < _xAxisLabels.length) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _xAxisLabels[index],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
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
