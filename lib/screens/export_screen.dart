import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _service = SupabaseService();
  final _excelService = ExcelService();

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _errorMessage = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _validateDates() {
    if (_fromDate.isAfter(_toDate)) {
      setState(() => _errorMessage = 'From Date cannot be later than To Date.');
      return false;
    }
    return true;
  }

  Future<void> _generateExcel() async {
    if (!_validateDates()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final classes = await _service.getClassesBetweenDates(
        _formatDate(_fromDate),
        _formatDate(_toDate),
      );

      if (classes.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage = 'No records found for selected dates.');
        }
        return;
      }

      final brahmacharis = await _service.getBrahmacharis();
      final allAttendance = await _service.getAllAttendance();

      await _excelService.generateAndSaveReport(
        classes: classes,
        brahmacharis: brahmacharis,
        allAttendance: allAttendance,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.file_download_outlined,
                size: 64, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Export Attendance Report',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select date range and generate Excel report.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            _DateField(
              label: 'From Date',
              value: _displayDate(_fromDate),
              onTap: () => _pickDate(isFrom: true),
            ),
            const SizedBox(height: 16),

            _DateField(
              label: 'To Date',
              value: _displayDate(_toDate),
              onTap: () => _pickDate(isFrom: false),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateExcel,
                icon: _isLoading
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
                  _isLoading ? 'Generating...' : 'Generate Excel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      ),
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
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
