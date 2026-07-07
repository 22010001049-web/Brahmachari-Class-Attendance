import 'package:flutter/material.dart';
import 'class_details_screen.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<ClassModel> _allClasses = [];
  Map<String, int> _attendanceCounts = {};
  int _totalBrahmacharis = 0;
  int _totalAttendanceRecords = 0;
  bool _isLoading = true;

  String _searchQuery = '';
  String _filter = 'All Classes';
  String? _selectedSpeaker;
  List<String> _speakerNames = [];

  DateTime? _fromDate;
  DateTime? _toDate;

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
        _service.getAllAttendance(),
        _service.getBrahmacharis(),
        _service.getSpeakerNames(),
      ]);

      final classes = results[0] as List<ClassModel>;
      final attendance = results[1] as List<AttendanceModel>;
      final brahmacharis = results[2] as List;
      _speakerNames = results[3] as List<String>;

      final counts = <String, int>{};
      for (final att in attendance) {
        counts[att.classId] = (counts[att.classId] ?? 0) + 1;
      }

      setState(() {
        _allClasses = classes;
        _attendanceCounts = counts;
        _totalAttendanceRecords = attendance.length;
        _totalBrahmacharis = brahmacharis.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
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
      final prefix =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
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
      classes =
          classes.where((c) => c.classDate.compareTo(fromStr) >= 0).toList();
    }
    if (_toDate != null) {
      final toStr =
          '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
      classes =
          classes.where((c) => c.classDate.compareTo(toStr) <= 0).toList();
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

  Future<void> _pickDateRange() async {
    final from = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select From Date',
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select To Date',
    );
    if (to == null) return;
    setState(() {
      _fromDate = from;
      _toDate = to;
    });
  }

  Future<void> _editClass(ClassModel classModel) async {
    final speakerController = TextEditingController(text: classModel.speakerName);
    DateTime classDate = DateTime.parse(classModel.classDate);
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(classModel.startTime.split(':')[0]),
      minute: int.parse(classModel.startTime.split(':')[1]),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Class'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: speakerController,
                    decoration: const InputDecoration(
                      labelText: 'Speaker Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      '${classDate.day}/${classDate.month}/${classDate.year}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: classDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            classDate = picked;
                          });
                        }
                      },
                      child: const Text('Select'),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Start Time'),
                    subtitle: Text(startTime.format(ctx)),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startTime = picked;
                          });
                        }
                      },
                      child: const Text('Select'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, {
                  'speakerName': speakerController.text.trim(),
                  'classDate':
                      '${classDate.year}-${classDate.month.toString().padLeft(2, '0')}-${classDate.day.toString().padLeft(2, '0')}',
                  'startTime':
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                }),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    try {
      await _service.updateClass(classModel.copyWith(
        speakerName: result['speakerName'] as String,
        classDate: result['classDate'] as String,
        startTime: result['startTime'] as String,
      ));
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating class: $e')),
        );
      }
    }
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
            'Delete the class on ${classModel.classDate} by ${classModel.speakerName}?\n\nAll attendance records for this class will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteClass(classModel.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allClasses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No attendance records found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildStatistics(),
                    _buildSearchBar(),
                    _buildFilterChips(),
                    _buildAdvancedFilters(),
                    Expanded(
                      child: _filteredClasses.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No records match your search.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _filteredClasses.length,
                              itemBuilder: (context, index) {
                                final c = _filteredClasses[index];
                                final count =
                                    _attendanceCounts[c.id] ?? 0;
                                return _ClassCard(
                                  classModel: c,
                                  attendeeCount: count,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClassAttendanceDetailView(
                                                classModel: c),
                                      ),
                                    );
                                  },
                                  onEdit: () => _editClass(c),
                                  onDelete: () => _deleteClass(c),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total Classes',
            value: '${_allClasses.length}',
            icon: Icons.class_,
            color: Colors.blue.shade700,
          ),
          _StatItem(
            label: 'Total Brahmacharis',
            value: '$_totalBrahmacharis',
            icon: Icons.people,
            color: Colors.teal.shade700,
          ),
          _StatItem(
            label: 'Total Records',
            value: '$_totalAttendanceRecords',
            icon: Icons.assignment,
            color: Colors.purple.shade700,
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
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade700,
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
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              _fromDate != null && _toDate != null
                  ? '${_fromDate!.day}/${_fromDate!.month} - ${_toDate!.day}/${_toDate!.month}'
                  : 'Date Range',
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

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final int attendeeCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.classModel,
    required this.attendeeCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.class_, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.speakerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${classModel.classDate}  |  ${classModel.startTime}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$attendeeCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Edit class',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete class',
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
