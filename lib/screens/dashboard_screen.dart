import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import '../models/speaker_model.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService();
  bool _isLoading = true;

  int _totalSpeakers = 0;
  int _totalBrahmacharis = 0;
  int _totalClasses = 0;
  int _totalAttendance = 0;
  int _greenCount = 0;
  int _lateCount = 0;

  List<_MonthlyStat> _monthlyStats = [];
  List<_WeeklyStat> _weeklyStats = [];
  List<_MonthlyLateStat> _monthlyLateStats = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getSpeakers(),
        _service.getBrahmacharis(),
        _service.getClasses(),
        _service.getAllAttendance(),
      ]);

      final speakers = results[0] as List<SpeakerModel>;
      final brahmacharis = results[1] as List<BrahmachariModel>;
      final classes = results[2] as List<ClassModel>;
      final attendance = results[3] as List<AttendanceModel>;

      _totalSpeakers = speakers.length;
      _totalBrahmacharis = brahmacharis.length;
      _totalClasses = classes.length;
      _totalAttendance = attendance.length;
      _greenCount = attendance.where((a) => a.status == 'green').length;
      _lateCount = attendance.where((a) => a.status == 'red').length;

      _computeMonthlyStats(classes, attendance);
      _computeWeeklyStats(classes, attendance);
      _computeMonthlyLateStats(classes, attendance);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _computeMonthlyStats(
      List<ClassModel> classes, List<AttendanceModel> attendance) {
    final Map<String, int> monthCount = {};
    for (final c in classes) {
      final key = c.classDate.substring(0, 7);
      monthCount[key] = (monthCount[key] ?? 0) + 1;
    }
    final sorted = monthCount.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _monthlyStats = sorted
        .map((e) => _MonthlyStat(month: e.key, count: e.value))
        .toList();
  }

  void _computeWeeklyStats(
      List<ClassModel> classes, List<AttendanceModel> attendance) {
    final Map<String, int> weekCount = {};
    for (final att in attendance) {
      final classModel = classes.where((c) => c.id == att.classId).firstOrNull;
      if (classModel == null) continue;
      final date = DateTime.tryParse(classModel.classDate);
      if (date == null) continue;
      final weekStart =
          date.subtract(Duration(days: date.weekday - 1));
      final weekNum = ((weekStart.day - weekStart.weekday + 1) ~/ 7) + 1;
      final key =
          '${weekStart.year}-W$weekNum';
      weekCount[key] = (weekCount[key] ?? 0) + 1;
    }
    final sorted = weekCount.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _weeklyStats = sorted
        .map((e) => _WeeklyStat(week: e.key, count: e.value))
        .toList();
  }

  void _computeMonthlyLateStats(
      List<ClassModel> classes, List<AttendanceModel> attendance) {
    final Map<String, int> lateCount = {};
    final Map<String, int> totalCount = {};
    for (final att in attendance) {
      final classModel = classes.where((c) => c.id == att.classId).firstOrNull;
      if (classModel == null) continue;
      final key = classModel.classDate.substring(0, 7);
      totalCount[key] = (totalCount[key] ?? 0) + 1;
      if (att.status == 'red') {
        lateCount[key] = (lateCount[key] ?? 0) + 1;
      }
    }
    final allKeys = {...totalCount.keys};
    final sorted = allKeys.toList()..sort();
    _monthlyLateStats = sorted.map((key) {
      return _MonthlyLateStat(
        month: key,
        onTime: (totalCount[key] ?? 0) - (lateCount[key] ?? 0),
        late: lateCount[key] ?? 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Monthly Attendance'),
                    const SizedBox(height: 8),
                    _buildMonthlyChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Weekly Attendance'),
                    const SizedBox(height: 8),
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Late Arrival by Month'),
                    const SizedBox(height: 8),
                    _buildLateChart(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsRow() {
    final attendancePercent = _totalAttendance > 0 && _totalClasses > 0
        ? ((_greenCount / (_totalBrahmacharis * _totalClasses)) * 100)
            .toStringAsFixed(1)
        : '0.0';
    final latePercent = _totalAttendance > 0
        ? ((_lateCount / _totalAttendance) * 100).toStringAsFixed(1)
        : '0.0';
    final presentPercent = _totalAttendance > 0
        ? ((_greenCount / _totalAttendance) * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Speakers',
                    value: '$_totalSpeakers',
                    icon: Icons.person,
                    color: Colors.indigo)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Brahmacharis',
                    value: '$_totalBrahmacharis',
                    icon: Icons.people,
                    color: Colors.teal)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Classes',
                    value: '$_totalClasses',
                    icon: Icons.class_,
                    color: Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Attendance %',
                    value: '$attendancePercent%',
                    icon: Icons.assignment,
                    color: Colors.purple)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Present %',
                    value: '$presentPercent%',
                    icon: Icons.check_circle,
                    color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Late %',
                    value: '$latePercent%',
                    icon: Icons.warning,
                    color: Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _monthlyStats
                      .map((e) => e.count.toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                  1.2,
              barGroups: _monthlyStats.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: Colors.deepPurple,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _monthlyStats.length) {
                        return const Text('');
                      }
                      final month = _monthlyStats[idx].month;
                      final parts = month.split('-');
                      return Text(
                        _monthAbbr(int.parse(parts[1])),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final displayStats = _weeklyStats.length > 12
        ? _weeklyStats.sublist(_weeklyStats.length - 12)
        : _weeklyStats;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: displayStats
                      .map((e) => e.count.toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                  1.2,
              barGroups: displayStats.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: Colors.teal,
                      width: 14,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= displayStats.length) {
                        return const Text('');
                      }
                      return Text('W${idx + 1}',
                          style: const TextStyle(fontSize: 9));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLateChart() {
    if (_monthlyLateStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _monthlyLateStats
                      .map((e) => (e.onTime + e.late).toDouble())
                      .reduce((a, b) => a > b ? a : b) *
                  1.2,
              barGroups: _monthlyLateStats.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.onTime.toDouble(),
                      color: Colors.green,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: e.value.late.toDouble(),
                      color: Colors.red,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _monthlyLateStats.length) {
                        return const Text('');
                      }
                      final month = _monthlyLateStats[idx].month;
                      final parts = month.split('-');
                      return Text(_monthAbbr(int.parse(parts[1])),
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStat {
  final String month;
  final int count;
  _MonthlyStat({required this.month, required this.count});
}

class _WeeklyStat {
  final String week;
  final int count;
  _WeeklyStat({required this.week, required this.count});
}

class _MonthlyLateStat {
  final String month;
  final int onTime;
  final int late;
  _MonthlyLateStat({
    required this.month,
    required this.onTime,
    required this.late,
  });
}
