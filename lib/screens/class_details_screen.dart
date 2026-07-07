import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';

/// Screen for viewing class details and attendance reports.
class ClassDetailsScreen extends StatefulWidget {
  const ClassDetailsScreen({super.key});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final service = SupabaseService();
      final classes = await service.getClasses();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching classes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No classes found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final c = _classes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.class_,
                              color: Colors.orange.shade800),
                        ),
                        title: Text(
                          c.speakerName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Date: ${c.classDate} | Start Time: ${c.startTime}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClassAttendanceDetailView(classModel: c),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

/// Detailed attendance report for a specific class.
class ClassAttendanceDetailView extends StatefulWidget {
  final ClassModel classModel;

  const ClassAttendanceDetailView({super.key, required this.classModel});

  @override
  State<ClassAttendanceDetailView> createState() =>
      _ClassAttendanceDetailViewState();
}

class _ClassAttendanceDetailViewState extends State<ClassAttendanceDetailView> {
  List<BrahmachariModel> _brahmacharis = [];
  Map<String, AttendanceModel> _attendanceMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final service = SupabaseService();
      final brahmacharis = await service.getBrahmacharis();
      final attendanceList =
          await service.getAttendanceByClass(widget.classModel.id!);

      final Map<String, AttendanceModel> attendanceMap = {};
      for (final att in attendanceList) {
        attendanceMap[att.brahmachariId] = att;
      }

      setState(() {
        _brahmacharis = brahmacharis;
        _attendanceMap = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _brahmacharis.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No attendance records available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Class header details
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.orange.shade50,
                  child: Column(
                    children: [
                      Text(
                        widget.classModel.speakerName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${widget.classModel.classDate}  |  Start Time: ${widget.classModel.startTime}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Attendance status list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _brahmacharis.length,
                    itemBuilder: (context, index) {
                      final b = _brahmacharis[index];
                      final att = _attendanceMap[b.id];

                      String statusLabel;
                      Color statusColor;

                      if (att == null) {
                        statusLabel = 'Absent';
                        statusColor = Colors.grey;
                      } else if (att.status == 'green') {
                        statusLabel = 'On Time';
                        statusColor = Colors.green.shade700;
                      } else {
                        statusLabel = 'Late';
                        statusColor = Colors.red.shade700;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (att != null && att.arrivalTime != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Arrival: ${att.arrivalTime}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
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
}
