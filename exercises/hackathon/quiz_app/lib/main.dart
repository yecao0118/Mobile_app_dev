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
    _timer?.cancel(); // Cancel timer when the widget is disposed
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    String data = await rootBundle.loadString('assets/quiz_data.json');
    final List<dynamic> jsonResult = json.decode(data);

    jsonResult.shuffle(); // Shuffle questions for random order

    setState(() {
      _questions = jsonResult;
      _currentQuestionIndex = 0; // Reset index
      _userSelections.clear(); // Clear previous answers
      _score = 0; // Reset score
      _quizTimedOut = false;
      _timeRemaining = 60; // Reset time
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        _timer?.cancel(); // Stop timer if widget is no longer mounted
        return;
      }

      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
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

      if (Set.from(correctAnswers).containsAll(userAnswers) &&
          Set.from(userAnswers).containsAll(correctAnswers)) {
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
          onRestart: _loadQuestions, // Pass restart function
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _goToNextQuestion,
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
    final selectedIndices = _userSelections[_currentQuestionIndex] ?? [];

    if (questionType == 'true_false' || questionType == 'single') {
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
  final VoidCallback onRestart;

  const ResultPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.onRestart, // Function to restart quiz
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your score: $score / $totalQuestions',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onRestart(); // Restart quiz
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPage()),
                );
              },
              child: const Text('Restart Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}