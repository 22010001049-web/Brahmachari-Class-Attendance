import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import '../models/speaker_model.dart';

/// Service responsible for all Supabase interactions.
///
/// Implements CRUD operations for classes, brahmacharis, and attendance tables.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // CLASSES CRUD OPERATIONS
  // ==========================================

  /// Inserts a new class record into the database.
  Future<ClassModel> createClass(ClassModel classModel) async {
    final response = await _client
        .from('classes')
        .insert(classModel.toJson())
        .select()
        .single();
    return ClassModel.fromJson(response);
  }

  /// Retrieves all class records, ordered by date descending.
  Future<List<ClassModel>> getClasses({
    int? limit,
    int? offset,
  }) async {
    dynamic query = _client.from('classes').select().order('class_date', ascending: false);
    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + (limit ?? 100) - 1);
    final response = await query;
    return (response as List)
        .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Updates an existing class record.
  Future<ClassModel> updateClass(ClassModel classModel) async {
    final id = classModel.id;
    if (id == null) throw Exception('Class ID is required for update');
    final response = await _client
        .from('classes')
        .update({
          'speaker_name': classModel.speakerName,
          'class_date': classModel.classDate,
          'start_time': classModel.startTime,
        })
        .eq('id', id)
        .select()
        .single();
    return ClassModel.fromJson(response);
  }

  /// Deletes a class record and all associated attendance (via cascade).
  Future<void> deleteClass(String id) async {
    await _client.from('classes').delete().eq('id', id);
  }

  // ==========================================
  // SPEAKERS CRUD OPERATIONS
  // ==========================================

  /// Inserts a new speaker record into the database.
  Future<SpeakerModel> createSpeaker(SpeakerModel speakerModel) async {
    final response = await _client
        .from('speakers')
        .insert(speakerModel.toJson())
        .select()
        .single();
    return SpeakerModel.fromJson(response);
  }

  /// Retrieves all speaker records, ordered by name alphabetically.
  Future<List<SpeakerModel>> getSpeakers() async {
    final response = await _client
        .from('speakers')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((json) => SpeakerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Updates an existing speaker record.
  Future<SpeakerModel> updateSpeaker(SpeakerModel speakerModel) async {
    final id = speakerModel.id;
    if (id == null) throw Exception('Speaker ID is required for update');
    final response = await _client
        .from('speakers')
        .update({'name': speakerModel.name})
        .eq('id', id)
        .select()
        .single();
    return SpeakerModel.fromJson(response);
  }

  /// Deletes a speaker and all associated classes (attendance cascades via FK).
  Future<void> deleteSpeaker(String id, {String? speakerName}) async {
    if (speakerName != null) {
      await _client
          .from('classes')
          .delete()
          .eq('speaker_name', speakerName);
    }
    await _client.from('speakers').delete().eq('id', id);
  }

  // ==========================================
  // BRAHMACHARIS CRUD OPERATIONS
  // ==========================================

  /// Inserts a new brahmachari record into the database.
  Future<BrahmachariModel> createBrahmachari(
      BrahmachariModel brahmachariModel) async {
    final response = await _client
        .from('brahmacharis')
        .insert(brahmachariModel.toJson())
        .select()
        .single();
    return BrahmachariModel.fromJson(response);
  }

  /// Retrieves all brahmachari records, ordered by name alphabetically.
  Future<List<BrahmachariModel>> getBrahmacharis() async {
    final response = await _client
        .from('brahmacharis')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((json) => BrahmachariModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Updates an existing brahmachari record.
  Future<BrahmachariModel> updateBrahmachari(
      BrahmachariModel brahmachariModel) async {
    final id = brahmachariModel.id;
    if (id == null) throw Exception('Brahmachari ID is required for update');
    final response = await _client
        .from('brahmacharis')
        .update({'name': brahmachariModel.name})
        .eq('id', id)
        .select()
        .single();
    return BrahmachariModel.fromJson(response);
  }

  /// Deletes a brahmachari by ID.
  Future<void> deleteBrahmachari(String id) async {
    await _client.from('brahmacharis').delete().eq('id', id);
  }

  // ==========================================
  // ATTENDANCE CRUD OPERATIONS
  // ==========================================

  /// Saves or updates a list of attendance records (upsert).
  Future<void> saveAttendance(List<AttendanceModel> attendanceList) async {
    final listJson = attendanceList.map((a) => a.toJson()).toList();
    await _client.from('attendance').upsert(listJson);
  }

  /// Retrieves all attendance records for a specific class ID.
  Future<List<AttendanceModel>> getAttendanceByClass(String classId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('class_id', classId);
    return (response as List)
        .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves all attendance records across all classes.
  Future<List<AttendanceModel>> getAllAttendance({
    int? limit,
    int? offset,
  }) async {
    dynamic query = _client.from('attendance').select();
    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + (limit ?? 100) - 1);
    final response = await query;
    return (response as List)
        .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a single attendance record by ID.
  Future<void> deleteAttendance(String id) async {
    await _client.from('attendance').delete().eq('id', id);
  }

  /// Batch creates multiple speakers at once.
  Future<void> createSpeakers(List<SpeakerModel> speakers) async {
    final listJson = speakers.map((s) => s.toJson()).toList();
    await _client.from('speakers').upsert(listJson);
  }

  /// Batch creates multiple brahmacharis at once.
  Future<void> createBrahmacharis(List<BrahmachariModel> list) async {
    final listJson = list.map((b) => b.toJson()).toList();
    await _client.from('brahmacharis').upsert(listJson);
  }

  /// Retrieves all speaker names from the speakers table.
  Future<List<String>> getSpeakerNames() async {
    final speakers = await getSpeakers();
    return speakers.map((s) => s.name).toList();
  }

  /// Retrieves classes whose [classDate] falls between [fromDate] and [toDate]
  /// (both in 'YYYY-MM-DD' format), sorted by date ascending.
  Future<List<ClassModel>> getClassesBetweenDates(
      String fromDate, String toDate) async {
    final response = await _client
        .from('classes')
        .select()
        .gte('class_date', fromDate)
        .lte('class_date', toDate)
        .order('class_date', ascending: true);
    return (response as List)
        .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
