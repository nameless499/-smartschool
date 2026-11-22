import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/blurred_background.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();

  bool _isLoading = true;
  List<DocumentRequest> _allRequests = [];

  // Filter State
  String _filterMode = 'Daily'; // 'Daily', 'Weekly', 'Monthly'

  // Chart Data
  List<FlSpot> _chartSpots = [];
  List<String> _xAxisLabels = [];
  double _maxY = 5;

  // Map to store requests for the tooltip
  final Map<int, List<DocumentRequest>> _bucketRequests = {};

  // Most Requested Data
  List<MapEntry<String, int>> _mostRequested = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final requests = await _repository.getAllRequests();
      setState(() {
        _allRequests = requests;
        _isLoading = false;
      });
      _processData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
      }
    }
  }

  void _processData() {
    _calculateChartData();
    _calculateMostRequested();
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

    setState(() {
      _chartSpots = spots;
      _xAxisLabels = labels;
      _maxY = maxVal + 2;
    });
  }

  void _calculateMostRequested() {
    final Map<String, int> counts = {};
    for (var req in _allRequests) {
      counts[req.documentName] = (counts[req.documentName] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _mostRequested = sortedEntries.take(5).toList();
    });
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: BlurredBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF1B5E20),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Welcome, ${profile?.fullName.split(' ').first ?? 'Admin'}!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 24),

                  // Filter Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Daily', 'Weekly', 'Monthly'].map((mode) {
                      final isSelected = _filterMode == mode;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                          selectedColor: const Color(0xFF1B5E20),
                          backgroundColor: Colors.white.withValues(alpha: 0.85),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _filterMode = mode);
                              _calculateChartData();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Chart Card
                  Card(
                    elevation: 8,
                    color: Colors.white.withValues(alpha: 0.85),
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.show_chart_rounded,
                                color: Color(0xFF1B5E20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Request Volume',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1B5E20),
                                    ),
                                  )
                                : LineChart(
                                    LineChartData(
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        handleBuiltInTouches: true,
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipBgColor: const Color(
                                            0xFF1B5E20,
                                          ),
                                          tooltipRoundedRadius: 12,
                                          tooltipPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          maxContentWidth: 250,
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                            return touchedBarSpots.map((
                                              barSpot,
                                            ) {
                                              final index = barSpot.x.toInt();
                                              final reqs =
                                                  _bucketRequests[index] ?? [];

                                              String title = '';
                                              if (_filterMode == 'Daily') {
                                                final date = DateTime.now()
                                                    .subtract(
                                                      Duration(days: 6 - index),
                                                    );
                                                title = _formatDate(date);
                                              } else if (_filterMode ==
                                                  'Weekly') {
                                                final endDate = DateTime.now()
                                                    .subtract(
                                                      Duration(
                                                        days: (3 - index) * 7,
                                                      ),
                                                    );
                                                final startDate = endDate
                                                    .subtract(
                                                      const Duration(days: 7),
                                                    );
                                                title =
                                                    '${_formatDate(startDate)} - ${_formatDate(endDate)}';
                                              } else {
                                                final date = DateTime(
                                                  DateTime.now().year,
                                                  DateTime.now().month -
                                                      (5 - index),
                                                  1,
                                                );
                                                title =
                                                    '${_formatMonth(date.month)} ${date.year}';
                                              }

                                              String tooltipText =
                                                  '📅 $title\n';

                                              if (reqs.isEmpty) {
                                                tooltipText += 'No requests';
                                              } else {
                                                tooltipText +=
                                                    '─────────────\n';
                                                final displayLimit = 4;
                                                for (
                                                  int i = 0;
                                                  i < reqs.length &&
                                                      i < displayLimit;
                                                  i++
                                                ) {
                                                  final req = reqs[i];
                                                  String docName =
                                                      req.documentName;
                                                  if (docName.length > 15) {
                                                    docName =
                                                        '${docName.substring(0, 13)}...';
                                                  }
                                                  tooltipText +=
                                                      '• ${req.studentName.split(' ').first} - $docName\n';
                                                }
                                                if (reqs.length >
                                                    displayLimit) {
                                                  tooltipText +=
                                                      '...and ${reqs.length - displayLimit} more';
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
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 1,
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                              strokeWidth: 1,
                                              dashArray: [5, 5],
                                            ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index >= 0 &&
                                                  index < _xAxisLabels.length) {
                                                return SideTitleWidget(
                                                  axisSide: meta.axisSide,
                                                  child: Text(
                                                    _xAxisLabels[index],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: Colors.grey[700],
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
                                              if (value ==
                                                  value.roundToDouble()) {
                                                return Text(
                                                  value.toInt().toString(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.grey[700],
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX: (_xAxisLabels.length - 1)
                                          .toDouble(),
                                      minY: 0,
                                      maxY: _maxY,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _chartSpots,
                                          isCurved: true,
                                          color: const Color(0xFF1B5E20),
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
                                                ) => FlDotCirclePainter(
                                                  radius: 4,
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                  strokeColor: const Color(
                                                    0xFF1B5E20,
                                                  ),
                                                ),
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(
                                                  0xFF1B5E20,
                                                ).withValues(alpha: 0.3),
                                                const Color(
                                                  0xFF1B5E20,
                                                ).withValues(alpha: 0.0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
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
                  const SizedBox(height: 24),

                  // Most Requested Card
                  Card(
                    elevation: 8,
                    color: Colors.white.withValues(alpha: 0.85),
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF1B5E20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Most Requested Documents',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1B5E20),
                              ),
                            )
                          else if (_mostRequested.isEmpty)
                            Center(
                              child: Text(
                                'No requests yet.',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            )
                          else
                            ..._mostRequested.map((entry) {
                              final totalReqs = _allRequests.length;
                              final percentage =
                                  (entry.value / totalReqs) * 100;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${entry.value} reqs',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF43A047),
                                            ),
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
    );
  }
}
