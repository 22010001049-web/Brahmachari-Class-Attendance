import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';

/// Screen for marking daily attendance.
///
/// Displays a list of brahmacharis. Tapping a card allows picking
/// an arrival time and saving to Supabase.
class AttendanceScreen extends StatefulWidget {
  final ClassModel classModel;

  const AttendanceScreen({super.key, required this.classModel});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<BrahmachariModel> _brahmacharis = [];
  Map<String, AttendanceModel> _attendanceMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
          SnackBar(content: Text('Error loading attendance data: $e')),
        );
      }
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  Future<void> _saveSingleAttendance(
      String brahmachariId, TimeOfDay time) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final arrivalTimeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

      final prefs = await SharedPreferences.getInstance();
      final graceMinutes = prefs.getInt('graceMinutes') ?? 15;

      final startMinutes = _parseTimeToMinutes(widget.classModel.startTime);
      final arrivalMinutes = time.hour * 60 + time.minute;
      final isGreen = arrivalMinutes <= startMinutes + graceMinutes;
      final status = isGreen ? 'green' : 'red';

      final existingAttendance = _attendanceMap[brahmachariId];
      final attendance = AttendanceModel(
        id: existingAttendance?.id,
        classId: widget.classModel.id!,
        brahmachariId: brahmachariId,
        arrivalTime: arrivalTimeStr,
        status: status,
      );

      final service = SupabaseService();
      await service.saveAttendance([attendance]);

      // Reload data to reflect changes
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e')),
        );
      }
    }
  }

  Future<void> _deleteAttendance(AttendanceModel att) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text('Remove this attendance record?'),
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
      final service = SupabaseService();
      await service.deleteAttendance(att.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await service.saveAttendance([att]);
                await _loadData();
              },
            ),
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting attendance: $e')),
        );
      }
    }
  }

  void _showMarkAttendanceDialog(BrahmachariModel brahmachari) {
    final existingAttendance = _attendanceMap[brahmachari.id];
    TimeOfDay initialTime = TimeOfDay.now();
    if (existingAttendance != null && existingAttendance.arrivalTime != null) {
      final parts = existingAttendance.arrivalTime!.split(':');
      initialTime = TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    TimeOfDay pickedTime = initialTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isEditing = existingAttendance != null;
            return AlertDialog(
              title: Text(isEditing ? 'Edit Attendance: ${brahmachari.name}' : 'Mark Attendance: ${brahmachari.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Arrival Time'),
                    subtitle: Text(
                        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: pickedTime,
                        );
                        if (time != null) {
                          setDialogState(() {
                            pickedTime = time;
                          });
                        }
                      },
                      child: const Text('Select'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveSingleAttendance(brahmachari.id!, pickedTime);
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
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
              children: [
                // Class Session Info Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple.shade50,
                  child: Column(
                    children: [
                      Text(
                        'Speaker: ${widget.classModel.speakerName}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${widget.classModel.classDate} | Start: ${widget.classModel.startTime}',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Attendance list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _brahmacharis.length,
                    itemBuilder: (context, index) {
                      final b = _brahmacharis[index];
                      final att = _attendanceMap[b.id];

                      Color statusColor = Colors.grey;
                      String statusText = 'Absent';
                      String? arrivalTime = att?.arrivalTime;

                      if (att != null) {
                        if (att.status == 'green') {
                          statusColor = Colors.green.shade700;
                          statusText = 'On Time';
                        } else {
                          statusColor = Colors.red.shade700;
                          statusText = 'Late';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showMarkAttendanceDialog(b),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: att == null
                                      ? Colors.grey.shade200
                                      : (att.status == 'green'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100),
                                  child: Text(
                                    b.name.isNotEmpty
                                        ? b.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: att == null
                                          ? Colors.grey.shade800
                                          : (att.status == 'green'
                                              ? Colors.green.shade800
                                              : Colors.red.shade800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (arrivalTime != null)
                                        Text(
                                          'Arrival: $arrivalTime',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                if (att != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () =>
                                        _deleteAttendance(att),
                                    tooltip: 'Delete attendance',
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Done button to return
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 24),
                      label: const Text(
                        'Finish Session',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
