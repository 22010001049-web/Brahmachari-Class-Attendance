import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/speaker_model.dart';
import '../services/supabase_service.dart';
import '../services/data_import_service.dart';

class ManageSpeakersScreen extends StatefulWidget {
  const ManageSpeakersScreen({super.key});

  @override
  State<ManageSpeakersScreen> createState() => _ManageSpeakersScreenState();
}

class _ManageSpeakersScreenState extends State<ManageSpeakersScreen> {
  final _service = SupabaseService();
  final _importService = DataImportService();
  final _searchController = TextEditingController();
  List<SpeakerModel> _speakers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSpeakers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpeakers() async {
    setState(() => _isLoading = true);
    try {
      final speakers = await _service.getSpeakers();
      setState(() {
        _speakers = speakers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading speakers: $e')),
        );
      }
    }
  }

  List<SpeakerModel> get _filteredSpeakers {
    if (_searchQuery.isEmpty) return _speakers;
    final query = _searchQuery.toLowerCase();
    return _speakers
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
  }

  Future<bool> _speakerHasClasses(String name) async {
    try {
      final classes = await _service.getClasses();
      return classes.any((c) =>
          c.speakerName.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return false;
    }
  }

  Future<void> _addSpeaker() async {
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
      await _service.createSpeaker(SpeakerModel(name: trimmed));
      await _loadSpeakers();
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

  Future<void> _editSpeaker(SpeakerModel speaker) async {
    final nameController = TextEditingController(text: speaker.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Speaker'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || result == speaker.name) return;

    final trimmed = result.trim();

    if (_speakers.any((s) =>
        s.id != speaker.id &&
        s.name.toLowerCase() == trimmed.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speaker name already exists')),
        );
      }
      return;
    }

    try {
      await _service.updateSpeaker(speaker.copyWith(name: trimmed));
      await _loadSpeakers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speaker updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating speaker: $e')),
        );
      }
    }
  }

  Future<void> _deleteSpeaker(SpeakerModel speaker) async {
    final hasClasses = await _speakerHasClasses(speaker.name);
    if (!mounted) return;
    final message = hasClasses
        ? 'Delete "${speaker.name}"?\n\nThis speaker has existing class records. All associated classes and attendance data will also be deleted.'
        : 'Delete "${speaker.name}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Speaker'),
        content: Text(message),
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
      await _service.deleteSpeaker(speaker.id!, speakerName: speaker.name);
      await _loadSpeakers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speaker deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting speaker: $e')),
        );
      }
    }
  }

  Future<void> _importSpeakers() async {
      final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    try {
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file')),
          );
        }
        return;
      }

      final importResult = _importService.parseSpeakersFromBytes(
        Uint8List.fromList(bytes),
        _speakers,
      );

      if (importResult.failed > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to parse Excel file')),
          );
        }
        return;
      }

      final existingNames =
          _speakers.map((s) => s.name.trim().toLowerCase()).toSet();
      final names = _importService.extractNamesFromExcel(
        Uint8List.fromList(bytes),
      );
      int imported = 0;
      for (final name in names) {
        final lower = name.trim().toLowerCase();
        if (!existingNames.contains(lower)) {
          try {
            await _service.createSpeaker(SpeakerModel(name: name.trim()));
            imported++;
          } catch (_) {}
        }
      }

      await _loadSpeakers();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Imported: $imported\nSkipped: ${importResult.skipped}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  Future<void> _exportSpeakers() async {
    try {
      final path = await _importService.exportSpeakersToExcel(_speakers);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Speakers'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') _importSpeakers();
              if (value == 'export') _exportSpeakers();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'import', child: Text('Import from Excel')),
              const PopupMenuItem(value: 'export', child: Text('Export to Excel')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSpeaker,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _speakers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No speakers added yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a speaker',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search speakers...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
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
                    ),
                    Expanded(
                      child: _filteredSpeakers.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No speakers match your search.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _filteredSpeakers.length,
                              itemBuilder: (context, index) {
                                final speaker = _filteredSpeakers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.deepPurple.shade100,
                                      child: Text(
                                        speaker.name.isNotEmpty
                                            ? speaker.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      speaker.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _editSpeaker(speaker),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteSpeaker(speaker),
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
