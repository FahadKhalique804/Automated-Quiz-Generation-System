import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({Key? key}) : super(key: key);

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  bool _isLoading = false;
  List<dynamic> _myCourses = [];
  List<dynamic> _lectureNotes = [];
  int? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getInt('userId');
      if (teacherId == null) throw Exception("User ID not found");

      final allocations = await ApiService.getAllocations();
      final myAllocations =
          allocations.where((a) => a['teacher_id'] == teacherId).toList();
      final allCourses = await ApiService.getCourses();

      final myCourses = <dynamic>[];
      for (var alloc in myAllocations) {
        final course = allCourses.firstWhere(
            (c) => c['id'] == alloc['course_id'],
            orElse: () => null);
        if (course != null) {
          myCourses.add(course);
        }
      }

      setState(() {
        _myCourses = myCourses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading courses: $e')));
      }
    }
  }

  Future<void> _fetchNotes(int courseId) async {
    setState(() => _isLoading = true);
    try {
      final notes = await ApiService.getLectureNotesByCourse(courseId);
      setState(() {
        _lectureNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
      }
    }
  }

  Future<void> _uploadNote() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a course first')));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('userId') ?? 1;

        await ApiService.uploadLectureNote(
            result.files.single.path!, _selectedCourseId!, userId);

        await _fetchNotes(_selectedCourseId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note uploaded successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteNote(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteLectureNote(id);
        if (_selectedCourseId != null) {
          await _fetchNotes(_selectedCourseId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Note deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            const Text('Upload Notes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Selection
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Course',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      hint: const Text('Choose a course'),
                      value: _selectedCourseId,
                      items: _myCourses.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text('${c['code']} - ${c['title']}',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCourseId = val);
                          _fetchNotes(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Upload Button
            ElevatedButton.icon(
              onPressed: (_isLoading || _selectedCourseId == null)
                  ? null
                  : _uploadNote,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload New Note (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33495F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Notes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedCourseId == null
                      ? const Center(
                          child: Text("Select a course to view notes",
                              style: TextStyle(color: Colors.grey)))
                      : _lectureNotes.isEmpty
                          ? const Center(
                              child: Text("No notes uploaded for this course"))
                          : ListView.builder(
                              itemCount: _lectureNotes.length,
                              itemBuilder: (context, index) {
                                final note = _lectureNotes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    leading: const Icon(Icons.picture_as_pdf,
                                        color: Colors.redAccent),
                                    title: Text(
                                        note['original_name'] ?? 'Untitled',
                                        overflow: TextOverflow.ellipsis),
                                    subtitle:
                                        Text('Uploaded ID: ${note['id']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.grey),
                                      onPressed: () => _deleteNote(note['id']),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
