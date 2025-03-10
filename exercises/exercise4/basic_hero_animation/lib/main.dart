import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: BasicHeroAnimation(),
    ),
  );
}


class BasicHeroAnimation extends StatelessWidget {
  const BasicHeroAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Hero Animation'),
      ),
      body: Center(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Flippers Page'),
                    ),
                    body: Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.topLeft,
                      color: Colors.lightBlueAccent,
                      child: Hero(
                        tag: 'flippers',
                        child: SizedBox(
                          width: 100,
                          child: Image.asset(
                            'images/flippers-alpha.png',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: 'flippers',
            child: Image.asset(
              'images/flippers-alpha.png',
            ),
          ),
        ),
      ),
    );
  }
}