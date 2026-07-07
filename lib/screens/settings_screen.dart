import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SupabaseService();
  final _backupService = BackupService();
  final _orgController = TextEditingController();
  final _backupController = TextEditingController();
  int _graceMinutes = 15;
  bool _isDarkMode = false;
  String _backupFolder = '';
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _orgController.dispose();
    _backupController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _graceMinutes = prefs.getInt('graceMinutes') ?? 15;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _orgController.text = prefs.getString('organizationName') ?? '';
      _backupFolder = prefs.getString('backupFolder') ?? '';
      _backupController.text = _backupFolder;
    });
  }

  Future<void> _saveGraceMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('graceMinutes', value);
  }

  Future<void> _saveOrganizationName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('organizationName', name);
  }

  Future<void> _saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);
    try {
      final speakers = await _service.getSpeakers();
      final brahmacharis = await _service.getBrahmacharis();
      final classes = await _service.getClasses();
      final attendance = await _service.getAllAttendance();

      final bytes = await _backupService.createBackup(
        speakers: speakers,
        brahmacharis: brahmacharis,
        classes: classes,
        attendance: attendance,
      );

      final result = await FilePicker.saveFile(
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        fileName: 'backup_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      if (result == null) {
        setState(() => _isBackingUp = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup error: $e')),
        );
      }
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreData() async {
    setState(() => _isRestoring = true);
    try {
      final pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (pickResult == null || pickResult.files.isEmpty) {
        setState(() => _isRestoring = false);
        return;
      }

      final bytes = pickResult.files.first.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file')),
          );
        }
        setState(() => _isRestoring = false);
        return;
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text(
            'This will overwrite all existing speakers and brahmacharis with the backup data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isRestoring = false);
        return;
      }

      await _backupService.restoreFromBackup(Uint8List.fromList(bytes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: $e')),
        );
      }
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _orgController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    onChanged: _saveOrganizationName,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined),
                      const SizedBox(width: 12),
                      const Text('Class Grace Time (minutes)',
                          style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '$_graceMinutes',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed >= 0) {
                              setState(() => _graceMinutes = parsed);
                              _saveGraceMinutes(parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle dark theme'),
                    secondary: Icon(
                        _isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      _saveThemeMode(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _backupController,
                    decoration: const InputDecoration(
                      labelText: 'Backup Folder Path',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                      hintText: 'Leave empty for default location',
                    ),
                    onChanged: (value) async {
                      _backupFolder = value;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('backupFolder', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isBackingUp ? null : _backupData,
                            icon: _isBackingUp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.backup),
                            label: Text(
                              _isBackingUp ? 'Backing up...' : 'Backup',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isRestoring ? null : _restoreData,
                            icon: _isRestoring
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.restore),
                            label: Text(
                              _isRestoring ? 'Restoring...' : 'Restore',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
