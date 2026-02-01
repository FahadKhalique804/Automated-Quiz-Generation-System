import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssessmentScoresScreen extends StatefulWidget {
  const AssessmentScoresScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentScoresScreen> createState() => _AssessmentScoresScreenState();
}

class _AssessmentScoresScreenState extends State<AssessmentScoresScreen> {
  bool _isLoading = false;
  List<dynamic> _myCourses = [];
  List<dynamic> _quizzes = [];
  List<dynamic> _attempts = [];
  List<dynamic> _students = [];

  int? _selectedCourseId;
  int? _selectedQuizId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
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
        if (course != null) myCourses.add(course);
      }

      final students = await ApiService.getStudents();

      setState(() {
        _myCourses = myCourses;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _fetchQuizzes(int courseId) async {
    setState(() {
      _isLoading = true;
      _selectedQuizId = null;
      _attempts = [];
    });
    try {
      final notes = await ApiService.getLectureNotesByCourse(courseId);
      final noteIds = notes.map((n) => n['id']).toSet();

      final allQuizzes = await ApiService.getQuizzes();
      // CORRECTION: Backend field is lecture_notes_id, NOT lecture_note_id
      final courseQuizzes = allQuizzes
          .where((q) => noteIds.contains(q['lecture_notes_id']))
          .toList();

      setState(() {
        _quizzes = courseQuizzes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading quizzes: $e')));
      }
    }
  }

  Future<void> _fetchAttempts(int quizId) async {
    setState(() => _isLoading = true);
    try {
      final attempts = await ApiService.getAttemptsByQuiz(quizId);
      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading scores: $e')));
      }
    }
  }

  String _getStudentName(int studentId) {
    final student =
        _students.firstWhere((s) => s['id'] == studentId, orElse: () => null);
    return student != null ? student['name'] : 'Student #$studentId';
  }

  Future<void> _showEditDialog(Map<String, dynamic> attempt) async {
    final _scoreController =
        TextEditingController(text: attempt['percentage']?.toString() ?? '0');
    final _feedbackController =
        TextEditingController(text: attempt['teacher_feedback'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Score for ${_getStudentName(attempt['student_id'])}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _scoreController,
              decoration:
                  const InputDecoration(labelText: 'Score Percentage (%)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                try {
                  final newScore = double.tryParse(_scoreController.text);
                  final feedback = _feedbackController.text;

                  await ApiService.updateAttempt(attempt['id'], {
                    if (newScore != null) 'percentage': newScore,
                    'teacher_feedback': feedback,
                  });

                  if (mounted) Navigator.pop(context);
                  if (_selectedQuizId != null) _fetchAttempts(_selectedQuizId!);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Score updated')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Assessment Scores',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder()),
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
                          _fetchQuizzes(val);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    if (_quizzes.isNotEmpty || _selectedCourseId != null)
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Select Quiz',
                            border: OutlineInputBorder()),
                        value: _selectedQuizId,
                        items: _quizzes.map<DropdownMenuItem<int>>((q) {
                          return DropdownMenuItem<int>(
                            value: q['id'],
                            // CORRECTION: Backend field is title, NOT topic
                            child: Text(q['title'] ?? 'Untitled Quiz',
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedQuizId = val);
                            _fetchAttempts(val);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedQuizId == null
                      ? const Center(
                          child: Text("Select a quiz to view scores"))
                      : _attempts.isEmpty
                          ? const Center(
                              child: Text("No attempts found for this quiz"))
                          : ListView.builder(
                              itemCount: _attempts.length,
                              itemBuilder: (context, index) {
                                final attempt = _attempts[index];
                                final score = attempt['percentage'] ?? 0;
                                final isPass = score >= 50;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPass
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      child: Text(
                                        '${score.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: isPass
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                        _getStudentName(attempt['student_id']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'Correct: ${attempt['total_correct']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blueAccent),
                                      onPressed: () => _showEditDialog(attempt),
                                    ),
                                    onTap: () => _showEditDialog(attempt),
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
