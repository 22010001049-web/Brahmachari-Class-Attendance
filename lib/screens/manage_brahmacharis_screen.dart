import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/brahmachari_model.dart';
import '../services/supabase_service.dart';
import '../services/data_import_service.dart';

class ManageBrahmacharisScreen extends StatefulWidget {
  const ManageBrahmacharisScreen({super.key});

  @override
  State<ManageBrahmacharisScreen> createState() =>
      _ManageBrahmacharisScreenState();
}

class _ManageBrahmacharisScreenState extends State<ManageBrahmacharisScreen> {
  final _service = SupabaseService();
  final _importService = DataImportService();
  final _searchController = TextEditingController();
  List<BrahmachariModel> _brahmacharis = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortAscending = true;
  @override
  void initState() {
    super.initState();
    _loadBrahmacharis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrahmacharis() async {
    setState(() => _isLoading = true);
    try {
      final brahmacharis = await _service.getBrahmacharis();
      setState(() {
        _brahmacharis = brahmacharis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading brahmacharis: $e')),
        );
      }
    }
  }

  List<BrahmachariModel> get _filteredBrahmacharis {
    var list = _brahmacharis;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where((b) => b.name.toLowerCase().contains(query))
          .toList();
    }
    list.sort((a, b) => _sortAscending
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    return list;
  }

  Future<bool> _brahmachariHasAttendance(String id) async {
    try {
      final attendance = await _service.getAllAttendance();
      return attendance.any((a) => a.brahmachariId == id);
    } catch (_) {
      return false;
    }
  }

  Future<void> _addBrahmachari() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Brahmachari'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brahmachari Name',
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

    if (_brahmacharis
        .any((b) => b.name.toLowerCase() == trimmed.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brahmachari already exists')),
        );
      }
      return;
    }

    try {
      await _service.createBrahmachari(BrahmachariModel(name: trimmed));
      await _loadBrahmacharis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brahmachari added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding brahmachari: $e')),
        );
      }
    }
  }

  Future<void> _editBrahmachari(BrahmachariModel brahmachari) async {
    final nameController = TextEditingController(text: brahmachari.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Brahmachari'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brahmachari Name',
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

    if (result == null || result.isEmpty || result == brahmachari.name) return;

    final trimmed = result.trim();

    if (_brahmacharis.any((b) =>
        b.id != brahmachari.id &&
        b.name.toLowerCase() == trimmed.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brahmachari name already exists')),
        );
      }
      return;
    }

    try {
      await _service.updateBrahmachari(brahmachari.copyWith(name: trimmed));
      await _loadBrahmacharis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brahmachari updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating brahmachari: $e')),
        );
      }
    }
  }

  Future<void> _deleteBrahmachari(BrahmachariModel brahmachari) async {
    final hasAttendance =
        await _brahmachariHasAttendance(brahmachari.id!);
    if (!mounted) return;
    final message = hasAttendance
        ? 'Delete "${brahmachari.name}"?\n\nThis brahmachari has attendance records. All associated attendance data will also be deleted (cascade).'
        : 'Delete "${brahmachari.name}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Brahmachari'),
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
      await _service.deleteBrahmachari(brahmachari.id!);
      await _loadBrahmacharis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brahmachari deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting brahmachari: $e')),
        );
      }
    }
  }

  Future<void> _importBrahmacharis() async {
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

      final importResult = _importService.parseBrahmacharisFromBytes(
        Uint8List.fromList(bytes),
        _brahmacharis,
      );

      if (importResult.failed > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to parse Excel file')),
          );
        }
        return;
      }

      final names = _importService.extractNamesFromExcel(
        Uint8List.fromList(bytes),
      );
      final existingNames =
          _brahmacharis.map((b) => b.name.trim().toLowerCase()).toSet();
      int imported = 0;
      for (final name in names) {
        final lower = name.trim().toLowerCase();
        if (!existingNames.contains(lower)) {
          try {
            await _service.createBrahmachari(BrahmachariModel(name: name.trim()));
            imported++;
          } catch (_) {}
        }
      }

      await _loadBrahmacharis();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Imported: $imported\nSkipped: ${importResult.skipped}\nFailed: ${importResult.failed}',
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
    } finally {
    }
  }

  Future<void> _exportBrahmacharis() async {
    try {
      final path = await _importService.exportBrahmacharisToExcel(_brahmacharis);
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
        title: const Text('Manage Brahmacharis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortAscending ? 'Sort Z-A' : 'Sort A-Z',
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') _importBrahmacharis();
              if (value == 'export') _exportBrahmacharis();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'import', child: Text('Import from Excel')),
              const PopupMenuItem(value: 'export', child: Text('Export to Excel')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBrahmachari,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _brahmacharis.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No brahmacharis added yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a brahmachari',
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
                          hintText: 'Search brahmacharis...',
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
                      child: _filteredBrahmacharis.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No brahmacharis match your search.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _filteredBrahmacharis.length,
                              itemBuilder: (context, index) {
                                final brahmachari =
                                    _filteredBrahmacharis[index];
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
                                      backgroundColor: Colors.teal.shade100,
                                      child: Text(
                                        brahmachari.name.isNotEmpty
                                            ? brahmachari.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      brahmachari.name,
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
                                              _editBrahmachari(brahmachari),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteBrahmachari(brahmachari),
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
