import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = SupabaseService();
  final _excelService = ExcelService();
  final _pdfService = PdfService();
  final _searchController = TextEditingController();

  List<ClassModel> _allClasses = [];
  List<BrahmachariModel> _brahmacharis = [];
  List<AttendanceModel> _allAttendance = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _filter = 'All Classes';
  String? _selectedSpeaker;
  List<String> _speakerNames = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  DateTime _exportFromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _exportToDate = DateTime.now();
  bool _isExporting = false;
  String? _exportError;

  int _reportYear = DateTime.now().year;
  int _reportMonth = DateTime.now().month;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getClasses(),
        _service.getBrahmacharis(),
        _service.getAllAttendance(),
        _service.getSpeakerNames(),
      ]);

      setState(() {
        _allClasses = results[0] as List<ClassModel>;
        _brahmacharis = results[1] as List<BrahmachariModel>;
        _allAttendance = results[2] as List<AttendanceModel>;
        _speakerNames = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<ClassModel> get _filteredClasses {
    var classes = _allClasses;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (_filter == 'Today\'s Classes') {
      classes = classes.where((c) => c.classDate == todayStr).toList();
    } else if (_filter == 'This Month') {
      final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      classes = classes.where((c) => c.classDate.startsWith(prefix)).toList();
    }

    if (_selectedSpeaker != null && _selectedSpeaker!.isNotEmpty) {
      classes = classes
          .where((c) =>
              c.speakerName.toLowerCase() == _selectedSpeaker!.toLowerCase())
          .toList();
    }

    if (_fromDate != null) {
      final fromStr =
          '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
      classes = classes.where((c) => c.classDate.compareTo(fromStr) >= 0).toList();
    }
    if (_toDate != null) {
      final toStr =
          '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
      classes = classes.where((c) => c.classDate.compareTo(toStr) <= 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      classes = classes.where((c) {
        return c.speakerName.toLowerCase().contains(query) ||
            c.classDate.contains(query);
      }).toList();
    }

    return classes;
  }

  int get _totalAttendanceInFiltered {
    final classIds = _filteredClasses.map((c) => c.id).toSet();
    return _allAttendance.where((a) => classIds.contains(a.classId)).length;
  }

  int get _totalBrahmacharisInFiltered {
    return _brahmacharis.length;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: isFrom ? 'Select From Date' : 'Select To Date',
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickExportDate({required bool isFrom}) async {
    final initial = isFrom ? _exportFromDate : _exportToDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _exportFromDate = picked;
        } else {
          _exportToDate = picked;
        }
        _exportError = null;
      });
    }
  }

  Future<void> _generateExcel() async {
    if (_exportFromDate.isAfter(_exportToDate)) {
      setState(() => _exportError = 'From Date cannot be later than To Date.');
      return;
    }

    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      final classes = await _service.getClassesBetweenDates(
        _formatDate(_exportFromDate),
        _formatDate(_exportToDate),
      );

      if (classes.isEmpty) {
        if (mounted) {
          setState(() => _exportError = 'No records found for selected dates.');
        }
        return;
      }

      await _excelService.generateAndSaveReport(
        classes: classes,
        brahmacharis: _brahmacharis,
        allAttendance: _allAttendance,
        fromDate: _exportFromDate,
        toDate: _exportToDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _exportError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Export'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatistics(),
                  _buildSearchBar(),
                  _buildFilterChips(),
                  _buildAdvancedFilters(),
                  _buildClassList(),
                  const Divider(height: 32, thickness: 2),
                  _buildMonthlyReportSection(),
                  const Divider(height: 32, thickness: 2),
                  _buildExportSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatistics() {
    final filtered = _filteredClasses;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.purple.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total Classes',
            value: '${filtered.length}',
            icon: Icons.class_,
            color: Colors.purple.shade700,
          ),
          _StatItem(
            label: 'Brahmacharis',
            value: '$_totalBrahmacharisInFiltered',
            icon: Icons.people,
            color: Colors.teal.shade700,
          ),
          _StatItem(
            label: 'Attendance',
            value: '$_totalAttendanceInFiltered',
            icon: Icons.assignment,
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by speaker name or date...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All Classes', 'Today\'s Classes', 'This Month'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filter = f);
              },
              selectedColor: Colors.purple.shade100,
              checkmarkColor: Colors.purple.shade700,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Speaker',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSpeaker,
                  isDense: true,
                  isExpanded: true,
                  hint: Text('All Speakers',
                      style: TextStyle(color: Colors.grey.shade600)),
                  items: _speakerNames.map((name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSpeaker = value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _pickDate(isFrom: true),
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              _fromDate != null
                  ? '${_fromDate!.day}/${_fromDate!.month}'
                  : 'From',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: () => _pickDate(isFrom: false),
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              _toDate != null
                  ? '${_toDate!.day}/${_toDate!.month}'
                  : 'To',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_fromDate != null || _toDate != null || _selectedSpeaker != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                  _selectedSpeaker = null;
                });
              },
              tooltip: 'Clear filters',
            ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final filtered = _filteredClasses;
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No records match your search.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final count =
            _allAttendance.where((a) => a.classId == c.id).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child:
                  Icon(Icons.class_, color: Colors.purple.shade700, size: 20),
            ),
            title: Text(c.speakerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${c.classDate}  |  ${c.startTime}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            trailing: Text(
              '$count present',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyReportSection() {
    final monthClasses = _allClasses.where((c) {
      final parts = c.classDate.split('-');
      return int.parse(parts[0]) == _reportYear && int.parse(parts[1]) == _reportMonth;
    }).toList();
    final totalClasses = monthClasses.length;
    final classIds = monthClasses.map((c) => c.id).toSet();
    final monthAttendance =
        _allAttendance.where((a) => classIds.contains(a.classId)).toList();
    final totalBrahmacharis = _brahmacharis.length;
    final totalPossible = totalClasses * totalBrahmacharis;
    final greenCount =
        monthAttendance.where((a) => a.status == 'green').length;
    final lateCount =
        monthAttendance.where((a) => a.status == 'red').length;
    final absentCount = totalPossible - monthAttendance.length;
    final attendancePercent =
        totalPossible > 0 ? ((monthAttendance.length / totalPossible) * 100) : 0.0;

    final monthName = DateFormat('MMMM yyyy').format(DateTime(_reportYear, _reportMonth));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.calendar_month, size: 48, color: Colors.blue.shade300),
          const SizedBox(height: 12),
          const Text(
            'Monthly Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _reportMonth--;
                      if (_reportMonth < 1) {
                        _reportMonth = 12;
                        _reportYear--;
                      }
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Prev'),
                ),
              ),
              const SizedBox(width: 12),
              Text(monthName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _reportMonth++;
                      if (_reportMonth > 12) {
                        _reportMonth = 1;
                        _reportYear++;
                      }
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _reportStat('Classes', '$totalClasses', Colors.blue),
                      _reportStat('Green', '$greenCount', Colors.green),
                      _reportStat('Late', '$lateCount', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _reportStat('Absent', '$absentCount', Colors.grey),
                      _reportStat('Attendance %',
                          '${attendancePercent.toStringAsFixed(1)}%',
                          Colors.deepPurple),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPdf ? null : _generatePdfReport,
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                _isGeneratingPdf
                    ? 'Generating...'
                    : 'Generate PDF Report',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _pdfService.generateMonthlyReport(
        classes: _allClasses,
        brahmacharis: _brahmacharis,
        allAttendance: _allAttendance,
        year: _reportYear,
        month: _reportMonth,
      );

      final result = await FilePicker.saveFile(
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        fileName:
            'monthly_report_${_reportYear}_${_reportMonth.toString().padLeft(2, '0')}.pdf',
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _buildExportSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.file_download_outlined,
              size: 48, color: Colors.purple.shade300),
          const SizedBox(height: 12),
          const Text(
            'Export to Excel',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From Date',
                  value: _displayDate(_exportFromDate),
                  onTap: () => _pickExportDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'To Date',
                  value: _displayDate(_exportToDate),
                  onTap: () => _pickExportDate(isFrom: false),
                ),
              ),
            ],
          ),
          if (_exportError != null) ...[
            const SizedBox(height: 12),
            Text(
              _exportError!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _generateExcel,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? 'Generating...' : 'Generate Excel',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
