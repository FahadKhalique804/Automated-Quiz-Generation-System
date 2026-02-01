import 'package:flutter/material.dart';
import 'quiz_review_screen.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizGenerationScreen extends StatefulWidget {
  const QuizGenerationScreen({Key? key}) : super(key: key);

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  bool _isLoading = false;
  List<dynamic> _myCourses = [];
  List<dynamic> _lectureNotes = [];

  int? _selectedCourseId;
  int? _selectedNoteId;
  String _topic = '';

  int _easyCount = 3;
  int _mediumCount = 2;
  int _hardCount = 0;

  List<int> _selectedLibraryQuestionIds = [];

  int get _totalQuestions => _easyCount  + _mediumCount + _hardCount;

  // final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Logged in Teacher ID
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getInt('userId');
      if (teacherId == null) throw Exception("User ID not found");

      // 2. Fetch Allocations (Teacher -> Courses)
      final allocations = await ApiService.getAllocations();

      // 3. Filter allocations for this teacher
      final myAllocations =
          allocations.where((a) => a['teacher_id'] == teacherId).toList();

      // 4. Fetch All Courses to map IDs to Names
      final allCourses = await ApiService.getCourses();

      // 5. Build My Courses List
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
    setState(() {
      _isLoading = true;
      _selectedNoteId = null; // Reset note selection
      _selectedLibraryQuestionIds = []; // Reset library selection
    });
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

  Future<void> _generateQuiz() async {
    if (_selectedNoteId == null || _topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a note and enter a topic')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final difficultyDict = {
        'Easy': _easyCount,
        'Medium': _mediumCount,
        'Hard': _hardCount,
      };

      // Determine dominant difficulty for metadata (simple heuristic)
      String mainDiff = 'Medium';
      if (_easyCount >= _mediumCount && _easyCount >= _hardCount)
        mainDiff = 'Easy';
      if (_hardCount >= _mediumCount && _hardCount >= _easyCount)
        mainDiff = 'Hard';
      if (_mediumCount >= _easyCount && _mediumCount >= _hardCount)
        mainDiff = 'Medium';

      final questions = await ApiService.generateQuizPreview(
        _selectedNoteId!,
        _topic,
        mainDiff,
        _totalQuestions,
        difficultyDict,
        selectedLibraryQuestionIds: _selectedLibraryQuestionIds,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizReviewScreen(
              noteId: _selectedNoteId!,
              topic: _topic,
              mainDifficulty: mainDiff,
              targetCounts: difficultyDict,
              initialQuestions: questions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            const Text('Generate Quiz', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a New Quiz',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F)),
            ),
            const SizedBox(height: 20),

            // Step 1: Select Course
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Select Course',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      ),
                      hint: const Text('Choose a course you teach'),
                      value: _selectedCourseId,
                      items: _myCourses.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(
                            '${c['code']} - ${c['title']}',
                            overflow: TextOverflow.ellipsis,
                          ),
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
            const SizedBox(height: 15),

            // Step 2: Select Note
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Select Lecture Note',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (_selectedCourseId == null)
                      const Text('Please select a course first.',
                          style: TextStyle(color: Colors.grey))
                    else if (_lectureNotes.isEmpty && !_isLoading)
                      const Text('No notes found for this course.',
                          style: TextStyle(color: Colors.orange))
                    else
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        hint: const Text('Choose a lecture note'),
                        value: _selectedNoteId,
                        items: _lectureNotes.map<DropdownMenuItem<int>>((n) {
                          return DropdownMenuItem<int>(
                            value: n['id'],
                            child: Text(
                              n['original_name'] ?? 'Untitled Note',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedNoteId = val),
                      ),
                    if (_selectedNoteId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton.icon(
                          onPressed: () => _showLibraryDialog(_selectedNoteId!),
                          icon: const Icon(Icons.history_edu),
                          label: const Text('View Question Library'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF33495F),
                          ),
                        ),
                      ),
                    if (_selectedLibraryQuestionIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '${_selectedLibraryQuestionIds.length} questions selected from library',
                          style: const TextStyle(
                              color: Color(0xFF33495F),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Step 3: Configure
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. Configure Quiz',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    TextField(
                      onChanged: (val) => _topic = val,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Introduction to AI',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text('Difficulty Distribution (Total: $_totalQuestions)',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    const SizedBox(height: 10),
                    _buildCounterRow('Easy', _easyCount,
                        (val) => setState(() => _easyCount = val)),
                    _buildCounterRow('Medium', _mediumCount,
                        (val) => setState(() => _mediumCount = val)),
                    _buildCounterRow('Hard', _hardCount,
                        (val) => setState(() => _hardCount = val)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateQuiz,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Generating...' : 'Generate Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33495F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 16))),
          IconButton(
            onPressed: () {
              if (value > 0) onChanged(value - 1);
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          ),
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _showLibraryDialog(int noteId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final questions = await ApiService.getLibraryQuestions(noteId);
      Navigator.pop(context); // Pop loading

      if (!mounted) return;

      // Local state for selection in dialog
      List<int> tempSelectedIds = List.from(_selectedLibraryQuestionIds);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Questions from Library'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // Limit height
                child: questions.isEmpty
                    ? const Center(child: Text('No questions found.'))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                                '${tempSelectedIds.length} selected / ${questions.length} available'),
                          ),
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: questions.length,
                              separatorBuilder: (c, i) => const Divider(),
                              itemBuilder: (c, i) {
                                final q = questions[i];
                                final isSelected =
                                    tempSelectedIds.contains(q['id']);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        tempSelectedIds.add(q['id']);
                                      } else {
                                        tempSelectedIds.remove(q['id']);
                                      }
                                    });
                                  },
                                  title: Text(q['question_text']),
                                  subtitle: Text(
                                      'Diff: ${q['difficulty']} | Quality: ${q['question_quality']}'),
                                  secondary: CircleAvatar(
                                    backgroundColor:
                                        q['question_quality'] == 'poor_question'
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.2),
                                    child: Text(q['correct_option']),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLibraryQuestionIds = tempSelectedIds;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirm Selection'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Pop loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching library: $e')),
        );
      }
    }
  }
}
