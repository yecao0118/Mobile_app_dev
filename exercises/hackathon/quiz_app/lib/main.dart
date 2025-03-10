import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, List<int>> _userSelections = {};
  int _score = 0;
  bool _quizTimedOut = false;
  int _timeRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    String data = await rootBundle.loadString('assets/quiz_data.json');
    final List<dynamic> jsonResult = json.decode(data);

    // Shuffle the questions for random order
    jsonResult.shuffle();

    setState(() {
      _questions = jsonResult;
    });

    // Start the timer after questions are loaded
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        // Time is up, user gets 0 score
        setState(() {
          _quizTimedOut = true;
        });
        _timer?.cancel();
        _goToResultPage();
      }
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Finished all questions
      _calculateScore();
      _goToResultPage();
    }
  }

  void _calculateScore() {
    int tempScore = 0;

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final correctAnswers = List<int>.from(question['correctAnswers']);
      final userAnswers = _userSelections[i] ?? [];

      // Compare sets
      final correctSet = correctAnswers.toSet();
      final userSet = userAnswers.toSet();
      if (correctSet.length == userSet.length && correctSet.containsAll(userSet)) {
        tempScore++;
      }
    }
    _score = tempScore;
  }

  void _goToResultPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          score: _quizTimedOut ? 0 : _score,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If questions are not loaded yet
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz App')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final questionText = question['question'];
    final questionType = question['type'];
    final options = List<String>.from(question['options']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text('Time: $_timeRemaining s',
                  style: const TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              questionText,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildOptions(questionType, options),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Move to next question
                _goToNextQuestion();
              },
              child: Text(
                _currentQuestionIndex < _questions.length - 1
                    ? 'Next'
                    : 'Submit',
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(String questionType, List<String> options) {
    // If haven't selected anything for this question, default to empty list
    final selectedIndices = _userSelections[_currentQuestionIndex] ?? [];

    if (questionType == 'true_false' || questionType == 'single') {
      // Render Radio Buttons (since there's only one correct answer)
      return Column(
        children: options.asMap().entries.map((entry) {
          int index = entry.key;
          String optionText = entry.value;
          return RadioListTile<int>(
            title: Text(optionText),
            value: index,
            groupValue: selectedIndices.isNotEmpty ? selectedIndices.first : -1,
            onChanged: (val) {
              setState(() {
                _userSelections[_currentQuestionIndex] = [val ?? 0];
              });
            },
          );
        }).toList(),
      );
    } else {
      // questionType == 'multiple': Render Checkboxes
      return Column(
        children: options.asMap().entries.map((entry) {
          int index = entry.key;
          String optionText = entry.value;
          bool checked = selectedIndices.contains(index);
          return CheckboxListTile(
            title: Text(optionText),
            value: checked,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedIndices.add(index);
                } else {
                  selectedIndices.remove(index);
                }
                _userSelections[_currentQuestionIndex] = selectedIndices;
              });
            },
          );
        }).toList(),
      );
    }
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
      body: Center(
        child: Text(
          'Your score: $score / $totalQuestions',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
