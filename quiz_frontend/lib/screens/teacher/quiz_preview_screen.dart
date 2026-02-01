import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class QuizPreviewScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;

  const QuizPreviewScreen({
    Key? key,
    required this.quizId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getQuizQuestions(widget.quizId);
      setState(() {
        _questions = data.map((q) {
          return {
            'id': q['id'],
            'q_order': q['q_order'],
            'question_text': q['question_text'],
            'option_a': q['option_a'],
            'option_b': q['option_b'],
            'option_c': q['option_c'],
            'option_d': q['option_d'],
            'correct_option': q['correct_option'],
            'difficulty': q['difficulty'] ?? 'Medium',
            'time_secs': q['time_secs'] ?? 60,
            'marks': q['marks'] ?? 1,
            'quiz_id': q['quiz_id'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(int id, String questionText) async {
    bool markAsPoor = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Question'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to delete this question?'),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Checkbox(
                      value: markAsPoor,
                      onChanged: (val) => setState(() => markAsPoor = val!),
                    ),
                    const Expanded(
                        child: Text('Mark as Poor Question (Feedback)')),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      try {
        if (markAsPoor) {
          await ApiService.markQuestionAsPoor(widget.quizId, questionText);
        }
        await ApiService.deleteQuestion(id);
        _fetchQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting question: $e')),
          );
        }
      }
    }
  }

  void _showQuestionDialog({Map<String, dynamic>? question}) {
    final isEditing = question != null;
    final _formKey = GlobalKey<FormState>();

    // Controllers
    final qTextCtrl =
        TextEditingController(text: isEditing ? question['question_text'] : '');
    final optACtrl =
        TextEditingController(text: isEditing ? question['option_a'] : '');
    final optBCtrl =
        TextEditingController(text: isEditing ? question['option_b'] : '');
    final optCCtrl =
        TextEditingController(text: isEditing ? question['option_c'] : '');
    final optDCtrl =
        TextEditingController(text: isEditing ? question['option_d'] : '');
    final timeCtrl = TextEditingController(
        text: isEditing ? question['time_secs'].toString() : '60');

    String selectedCorrect = isEditing ? question['correct_option'] : 'A';
    String selectedDifficulty = isEditing ? question['difficulty'] : 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Question' : 'Add Question'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: qTextCtrl,
                      decoration: const InputDecoration(labelText: 'Question'),
                      maxLines: 3,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter question text' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: optACtrl,
                            decoration:
                                const InputDecoration(labelText: 'Option A'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: optBCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Option B'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: optCCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Option C'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: optDCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Option D'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCorrect,
                      decoration:
                          const InputDecoration(labelText: 'Correct Option'),
                      items: ['A', 'B', 'C', 'D']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCorrect = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDifficulty,
                            decoration:
                                const InputDecoration(labelText: 'Difficulty'),
                            items: ['Easy', 'Medium', 'Hard']
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedDifficulty = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: timeCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Time (secs)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final payload = {
                      'quiz_id': widget.quizId,
                      'q_order': isEditing
                          ? question['q_order']
                          : _questions.length + 1,
                      'question_text': qTextCtrl.text,
                      'option_a': optACtrl.text,
                      'option_b': optBCtrl.text,
                      'option_c': optCCtrl.text,
                      'option_d': optDCtrl.text,
                      'correct_option': selectedCorrect,
                      'difficulty': selectedDifficulty,
                      'time_secs': int.tryParse(timeCtrl.text) ?? 60,
                      'marks': 1, // Default marks
                    };

                    try {
                      if (isEditing) {
                        await ApiService.updateQuestion(
                            question['id'], payload);
                      } else {
                        await ApiService.addQuestion(payload);
                      }
                      Navigator.pop(ctx);
                      _fetchQuestions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isEditing
                                ? 'Question updated'
                                : 'Question added')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            Text(widget.quizTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuestionDialog(),
        backgroundColor: const Color(0xFF33495F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text("No questions found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    final correctOption = question['correct_option'];
                    final options = [
                      question['option_a'],
                      question['option_b'],
                      question['option_c'],
                      question['option_d']
                    ];
                    final optionLabels = ['A', 'B', 'C', 'D'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Q${index + 1}: ${question['question_text']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF33495F),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showQuestionDialog(
                                          question: question),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteQuestion(
                                          question['id'],
                                          question['question_text']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text('${question['difficulty']}'),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                      color: Colors.blue[800], fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('${question['time_secs']}s'),
                                  backgroundColor:
                                      Colors.orange.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                      color: Colors.orange[800], fontSize: 12),
                                  avatar: const Icon(Icons.timer,
                                      size: 16, color: Colors.orange),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            ...List.generate(options.length, (optIndex) {
                              final isCorrect =
                                  correctOption == optionLabels[optIndex];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    width: isCorrect ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.grey.shade200,
                                      ),
                                      child: Text(
                                        optionLabels[optIndex],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect
                                              ? Colors.white
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        options[optIndex],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isCorrect
                                              ? Colors.green[800]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isCorrect)
                                      const Icon(Icons.check_circle,
                                          color: Colors.green),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
