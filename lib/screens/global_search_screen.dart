import 'package:flutter/material.dart';
import '../models/speaker_model.dart';
import '../models/brahmachari_model.dart';
import '../models/class_model.dart';
import '../services/supabase_service.dart';
import 'manage_speakers_screen.dart';
import 'manage_brahmacharis_screen.dart';
import 'class_details_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _service = SupabaseService();
  final _searchController = TextEditingController();
  bool _isLoading = false;

  List<SpeakerModel> _allSpeakers = [];
  List<BrahmachariModel> _allBrahmacharis = [];
  List<ClassModel> _allClasses = [];

  List<SpeakerModel> _speakerResults = [];
  List<BrahmachariModel> _brahmachariResults = [];
  List<ClassModel> _classResults = [];
  bool _hasSearched = false;

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
        _service.getSpeakers(),
        _service.getBrahmacharis(),
        _service.getClasses(),
      ]);
      setState(() {
        _allSpeakers = results[0] as List<SpeakerModel>;
        _allBrahmacharis = results[1] as List<BrahmachariModel>;
        _allClasses = results[2] as List<ClassModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _speakerResults = [];
        _brahmachariResults = [];
        _classResults = [];
        _hasSearched = false;
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _speakerResults = _allSpeakers
          .where((s) => s.name.toLowerCase().contains(q))
          .toList();
      _brahmachariResults = _allBrahmacharis
          .where((b) => b.name.toLowerCase().contains(q))
          .toList();
      _classResults = _allClasses
          .where((c) =>
              c.speakerName.toLowerCase().contains(q) ||
              c.classDate.contains(q))
          .toList();
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Search'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search speakers, brahmacharis, dates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _search,
                  ),
                ),
                Expanded(
                  child: _hasSearched ? _buildResults() : _buildInitial(),
                ),
              ],
            ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Search across $_totalRecords records',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Type to search speakers, brahmacharis, or class dates',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  int get _totalRecords =>
      _allSpeakers.length + _allBrahmacharis.length + _allClasses.length;

  Widget _buildResults() {
    final total = _speakerResults.length +
        _brahmachariResults.length +
        _classResults.length;

    if (total == 0) {
      return const Center(
        child: Text('No results found',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_speakerResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('Speakers (${_speakerResults.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._speakerResults.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(s.name[0].toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700)),
                  ),
                  title: Text(s.name),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageSpeakersScreen(),
                      ),
                    );
                  },
                ),
              )),
        ],
        if (_brahmachariResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text('Brahmacharis (${_brahmachariResults.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._brahmachariResults.map((b) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(b.name[0].toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700)),
                  ),
                  title: Text(b.name),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageBrahmacharisScreen(),
                      ),
                    );
                  },
                ),
              )),
        ],
        if (_classResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text('Classes (${_classResults.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ..._classResults.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.class_, color: Colors.blue.shade700),
                  ),
                  title: Text(c.speakerName),
                  subtitle: Text('${c.classDate}  |  ${c.startTime}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
