import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/speaker_model.dart';
import '../services/supabase_service.dart';
import 'attendance_screen.dart';

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speakerController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  List<SpeakerModel> _speakers = [];

  @override
  void initState() {
    super.initState();
    _loadSpeakers();
  }

  @override
  void dispose() {
    _speakerController.dispose();
    super.dispose();
  }

  Future<void> _loadSpeakers() async {
    try {
      final service = SupabaseService();
      final speakers = await service.getSpeakers();
      if (mounted) {
        setState(() {
          _speakers = speakers;
        });
      }
    } catch (_) {}
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _addSpeakerFromSession() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Speaker'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Speaker Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final trimmed = result.trim();

    if (_speakers.any((s) => s.name.toLowerCase() == trimmed.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speaker already exists')),
        );
      }
      return;
    }

    try {
      final service = SupabaseService();
      await service.createSpeaker(SpeakerModel(name: trimmed));
      await _loadSpeakers();
      _speakerController.text = trimmed;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speaker added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding speaker: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _startAttendance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final service = SupabaseService();
        final classModel = ClassModel(
          speakerName: _speakerController.text.trim(),
          classDate: _formatDate(_selectedDate),
          startTime: _formatTime(_selectedTime),
        );

        final createdClass = await service.createClass(classModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class created successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceScreen(classModel: createdClass),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating class: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start New Session'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.play_circle_outline,
                  size: 64, color: Colors.deepPurple.shade300),
              const SizedBox(height: 16),
              Text(
                'Create a new attendance session',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Autocomplete<SpeakerModel>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _speakers;
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return _speakers
                      .where((s) => s.name.toLowerCase().contains(query));
                },
                displayStringForOption: (s) => s.name,
                onSelected: (s) => _speakerController.text = s.name,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Speaker',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter speaker name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _speakerController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addSpeakerFromSession,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Add Speaker'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Class Date'),
                  subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _selectDate,
                    child: const Text('Select'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Class Start Time'),
                  subtitle: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _selectTime,
                    child: const Text('Select'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startAttendance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text(
                    'Start Attendance',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
