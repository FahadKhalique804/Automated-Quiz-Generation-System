import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class QuizReviewScreen extends StatefulWidget {
  final int noteId;
  final String topic;
  final String mainDifficulty;
  final Map<String, int> targetCounts;
  final List<dynamic> initialQuestions;

  const QuizReviewScreen({
    Key? key,
    required this.noteId,
    required this.topic,
    required this.mainDifficulty,
    required this.targetCounts,
    required this.initialQuestions,
  }) : super(key: key);

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  late List<dynamic> _questions;
  late Set<int> _selectedIndices;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);

    _selectedIndices = Set.from(List.generate(_questions.length, (i) => i));
  }

  int get _totalTarget => widget.targetCounts.values.reduce((a, b) => a + b);
  int get _totalSelected => _selectedIndices.length;

  Map<String, int> get _currentSelectedCounts {
    final counts = {'Easy': 0, 'Medium': 0, 'Hard': 0};
    for (var i in _selectedIndices) {
      final q = _questions[i];
      final diff = q['difficulty'] ?? 'Medium';
      counts[diff] = (counts[diff] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _generateMore() async {
    final current = _currentSelectedCounts;
    final Map<String, int> missing = {};
    int totalMissing = 0;

    widget.targetCounts.forEach((diff, target) {
      final cur = current[diff] ?? 0;
      if (cur < target) {
        missing[diff] = target - cur;
        totalMissing += target - cur;
      }
    });

    if (totalMissing == 0) return;

    setState(() => _isLoading = true);
    try {
      final newQuestions = await ApiService.generateQuizPreview(
        widget.noteId,
        widget.topic,
        widget.mainDifficulty,
        totalMissing,
        missing,
        selectedLibraryQuestionIds: [],
      );

      setState(() {
        final startIndex = _questions.length;
        _questions.addAll(newQuestions);

        for (var i = 0; i < newQuestions.length; i++) {
          _selectedIndices.add(startIndex + i);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated $totalMissing more questions.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizeQuiz() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one question.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final selectedQuestions = <dynamic>[];
      for (var i in _selectedIndices) {
        selectedQuestions.add(_questions[i]);
      }

      await ApiService.finalizeQuiz(
        widget.noteId,
        widget.topic,
        widget.mainDifficulty,
        selectedQuestions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz Created Successfully!')),
        );
        // Navigate to Quiz History or Dashboard
        // For now, let's pop back to previous screen (Generation) then pop that?
        // Or just push replacement to QuizHistory
        Navigator.pop(context); // Pop Review
        Navigator.pop(context); // Pop Generation
        // Optionally navigate to history?
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizHistoryScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Finalization failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCounts = _currentSelectedCounts;
    final totalMissing = _totalTarget - _totalSelected;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Review Questions',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBadge(
                        'Target', _totalTarget.toString(), Colors.blueGrey),
                    _buildStatBadge(
                        'Selected',
                        _totalSelected.toString(),
                        _totalSelected == _totalTarget
                            ? Colors.green
                            : Colors.orange),
                    if (totalMissing > 0)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateMore,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text('+$totalMissing More'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF33495F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      )
                    else
                      const SizedBox(
                          width: 100, height: 36), // Spacer for alignment
                  ],
                ),
                const SizedBox(height: 10),
                // Detailed breakdown
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.targetCounts.entries.map((e) {
                      final diff = e.key;
                      final target = e.value;
                      final current = currentCounts[diff] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Text(
                          '$diff: $current/$target',
                          style: TextStyle(
                            color: current < target ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _questions.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final q = _questions[index];
                final isSelected = _selectedIndices.contains(index);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isSelected
                        ? const BorderSide(color: Colors.green, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIndices.remove(index);
                        } else {
                          _selectedIndices.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getDiffColor(q['difficulty']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        q['difficulty'] ?? 'Medium',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${q['time_secs'] ?? 60}s',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  q['question'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                // Options Preview (just simplified)
                                ...['A', 'B', 'C', 'D'].map((opt) {
                                  final txt = q['options'][opt];
                                  final isCorrect = q['correct'] == opt;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '$opt) $txt',
                                      style: TextStyle(
                                          color: isCorrect
                                              ? Colors.green
                                              : Colors.black87,
                                          fontWeight: isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.normal),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finalizeQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33495F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isLoading
                    ? 'Finalizing...'
                    : 'Create Quiz with $_totalSelected Questions'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Color _getDiffColor(String? diff) {
    switch (diff) {
      case 'Easy':
        return Colors.green;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
