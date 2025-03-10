import 'package:flutter/material.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _currentInput = "";
  double _num1 = 0;
  double _num2 = 0;
  String _operation = "";

  void _buttonPressed(String value) {
    setState(() {
      if (value == "C") {
        _output = "0";
        _currentInput = "";
        _num1 = 0;
        _num2 = 0;
        _operation = "";
      } else if (value == "+" || value == "-" || value == "×" || value == "÷") {
        if (_currentInput.isNotEmpty) {
          _num1 = double.parse(_currentInput);
          _operation = value;
          _currentInput = "";
          _output += " $value ";
        }
      } else if (value == "=") {
        if (_currentInput.isNotEmpty && _operation.isNotEmpty) {
          _num2 = double.parse(_currentInput);
          switch (_operation) {
            case "+":
              _output = (_num1 + _num2).toString();
              break;
            case "-":
              _output = (_num1 - _num2).toString();
              break;
            case "×":
              _output = (_num1 * _num2).toString();
              break;
            case "÷":
              _output = _num2 != 0 ? (_num1 / _num2).toString() : "Error";
              break;
          }
          _currentInput = _output;
          _operation = "";
        }
      } else {
        if (_output == "0") {
          _output = value;
          _currentInput = value;
        } else {
          _currentInput += value;
          _output += value;
        }
      }
    });
  }

  Widget _buildButton(String text, Color color) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 24),
            backgroundColor: color,
            textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<Map<String, Color>> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((button) {
        String text = button.keys.first;
        Color color = button.values.first;
        return _buildButton(text, color);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Calculator")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.all(24),
                child: Text(
                  _output,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: 10),
                _buildButtonRow([
                  {"7": Colors.grey}, {"8": Colors.grey}, {"9": Colors.grey}, {"÷": Colors.orange}
                ]),
                SizedBox(height: 10),
                _buildButtonRow([
                  {"4": Colors.grey}, {"5": Colors.grey}, {"6": Colors.grey}, {"×": Colors.orange}
                ]),
                SizedBox(height: 10),
                _buildButtonRow([
                  {"1": Colors.grey}, {"2": Colors.grey}, {"3": Colors.grey}, {"-": Colors.orange}
                ]),
                SizedBox(height: 10),
                _buildButtonRow([
                  {"C":  Colors.orange}, {"0": Colors.grey}, {"=":  Colors.orange}, {"+": Colors.orange}
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
