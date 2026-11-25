import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/app_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();

  static const Color primary = Color(0xFF176B3A);
  static const Color chartGreen = Color(0xFF006633);
  static const Color chartGreenDark = Color(0xFF004D26);
  static const Color secondary = Color(0xFF2E9B61);
  static const Color background = Color(0xFFF5F8F6);
  static const Color textDark = Color(0xFF1D3025);

  bool _isLoading = true;
  List<DocumentRequest> _allRequests = [];

  String _filterMode = 'Daily';

  List<FlSpot> _chartSpots = [];
  List<String> _xAxisLabels = [];
  double _maxY = 5;

  final Map<int, List<DocumentRequest>> _bucketRequests = {};

  List<MapEntry<String, int>> _mostRequested = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final requests = await _repository.getAllRequests();

      if (!mounted) return;

      setState(() {
        _allRequests = requests;
        _isLoading = false;
      });

      _processData();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load statistics: $e')));
    }
  }

  void _processData() {
    _calculateChartData();
    _calculateMostRequested();
  }

  void _calculateChartData() {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <String>[];
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

        final requests = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(date) && local.isBefore(nextDate);
        }).toList();

        final index = 6 - i;

        _bucketRequests[index] = requests;
        spots.add(FlSpot(index.toDouble(), requests.length.toDouble()));

        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        labels.add(days[date.weekday - 1]);

        if (requests.length > maxVal) {
          maxVal = requests.length.toDouble();
        }
      }
    } else if (_filterMode == 'Weekly') {
      for (int i = 3; i >= 0; i--) {
        final endDate = now.subtract(Duration(days: i * 7));
        final startDate = endDate.subtract(const Duration(days: 7));

        final requests = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(startDate) && local.isBefore(endDate);
        }).toList();

        final index = 3 - i;

        _bucketRequests[index] = requests;
        spots.add(FlSpot(index.toDouble(), requests.length.toDouble()));
        labels.add('Wk ${4 - i}');

        if (requests.length > maxVal) {
          maxVal = requests.length.toDouble();
        }
      }
    } else {
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final nextDate = DateTime(now.year, now.month - i + 1, 1);

        final requests = _allRequests.where((r) {
          final local = r.createdAt.toLocal();
          return local.isAfter(date) && local.isBefore(nextDate);
        }).toList();

        final index = 5 - i;

        _bucketRequests[index] = requests;
        spots.add(FlSpot(index.toDouble(), requests.length.toDouble()));

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

        if (requests.length > maxVal) {
          maxVal = requests.length.toDouble();
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _chartSpots = spots;
      _xAxisLabels = labels;
      _maxY = maxVal + 2;
    });
  }

  void _calculateMostRequested() {
    final Map<String, int> counts = {};

    for (final request in _allRequests) {
      counts[request.documentName] = (counts[request.documentName] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) return;

    setState(() {
      _mostRequested = sorted.take(5).toList();
    });
  }

  int get _todayRequests {
    final now = DateTime.now();

    return _allRequests.where((request) {
      final date = request.createdAt.toLocal();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get _documentTypes =>
      _allRequests.map((request) => request.documentName).toSet().length;

  String get _firstName {
    final name = context.watch<AuthProvider>().profile?.fullName;

    if (name == null || name.trim().isEmpty) return 'Admin';

    return name.trim().split(' ').first;
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

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 25,
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

  Widget _buildFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((mode) {
          final selected = _filterMode == mode;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                mode,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              selected: selected,
              selectedColor: chartGreen,
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
              onSelected: (value) {
                if (value) {
                  setState(() {
                    _filterMode = mode;
                  });
                  _calculateChartData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 250,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: chartGreen))
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
                    color: chartGreen,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: chartGreen,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          chartGreen.withValues(alpha: 0.2),
                          chartGreen.withValues(alpha: 0.0),
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

  Widget _buildRecentRequestsList(List<DocumentRequest> requests) {
    if (requests.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F5),
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
        color: const Color(0xFFF3F7F5),
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
                color: chartGreenDark,
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
                final request = requests[index];
                final name = request.studentName;
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: chartGreen.withValues(alpha: 0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 12,
                        color: chartGreen,
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
                    request.documentName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDate(request.createdAt.toLocal()),
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

  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: chartGreenDark,
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.all(12),
        maxContentWidth: 250,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final index = barSpot.x.toInt();
            final requests = _bucketRequests[index] ?? [];

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

            if (requests.isEmpty) {
              tooltipText += 'No requests';
            } else {
              tooltipText += '─────────────\n';

              const displayLimit = 4;

              for (int i = 0; i < requests.length && i < displayLimit; i++) {
                final request = requests[i];

                String documentName = request.documentName;

                if (documentName.length > 15) {
                  documentName = '${documentName.substring(0, 13)}...';
                }

                final firstName = request.studentName.split(' ').first;

                tooltipText += '• $firstName - $documentName\n';
              }

              if (requests.length > displayLimit) {
                tooltipText += '...and ${requests.length - displayLimit} more';
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

  Widget _buildMostRequested() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (_mostRequested.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Center(
          child: Text(
            'No document requests yet.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final total = _allRequests.length;

    return Column(
      children: _mostRequested.asMap().entries.map((item) {
        final index = item.key;
        final entry = item.value;
        final percentage = total == 0 ? 0.0 : entry.value / total;

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} requests',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE9F0EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(secondary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

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
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh dashboard',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EFEA), height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                    'Welcome back, $_firstName!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Here is an overview of your registrar activity.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // SUMMARY CARDS
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard(
                        title: 'Total Requests',
                        value: _isLoading ? '...' : '${_allRequests.length}',
                        icon: Icons.description_outlined,
                        iconColor: primary,
                        iconBackground: const Color(0xFFE4F2E9),
                      ),
                      _statCard(
                        title: "Today's Requests",
                        value: _isLoading ? '...' : '$_todayRequests',
                        icon: Icons.today_outlined,
                        iconColor: const Color(0xFF2877B8),
                        iconBackground: const Color(0xFFE7F1FA),
                      ),
                      _statCard(
                        title: 'Document Types',
                        value: _isLoading ? '...' : '$_documentTypes',
                        icon: Icons.folder_open_outlined,
                        iconColor: const Color(0xFFB17A24),
                        iconBackground: const Color(0xFFFFF3DD),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // REQUEST VOLUME
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: screenWidth > 800
                          ? [
                              BoxShadow(
                                color: chartGreen.withValues(alpha: 0.05),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 15),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Request Volume',
                          'Track incoming document requests',
                          Icons.show_chart_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildFilter(),
                        const SizedBox(height: 24),

                        // CHART AND RECENT REQUESTS
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final visibleRequests = <DocumentRequest>[];

                            for (final requests in _bucketRequests.values) {
                              visibleRequests.addAll(requests);
                            }

                            visibleRequests.sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            );

                            if (constraints.maxWidth > 600) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            }

                            return Column(
                              children: [
                                _buildChart(),
                                const SizedBox(height: 24),
                                _buildRecentRequestsList(visibleRequests),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // MOST REQUESTED DOCUMENTS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8EFEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Most Requested Documents',
                          'Top five requested document types',
                          Icons.bar_chart_rounded,
                        ),
                        _buildMostRequested(),
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
