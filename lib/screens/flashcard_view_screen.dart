import 'package:bookmark/models/flashcard_model.dart';
import 'package:flutter/material.dart';

class FlashcardPracticeScreen extends StatefulWidget {
  final SetModel set;

  const FlashcardPracticeScreen({super.key, required this.set});

  @override
  State<FlashcardPracticeScreen> createState() =>
      _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState extends State<FlashcardPracticeScreen> {
  int currentIndex = 0;
  bool answer = false;
  @override
  Widget build(BuildContext context) {
    List<Flashcard> cards = widget.set.cards;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_sharp),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                answer = !answer;
              });
            },
            child: answer
                ? Text(
                    cards[currentIndex].answer,
                    style: TextStyle(fontSize: 18),
                  )
                : Text(
                    cards[currentIndex].question,
                    style: TextStyle(fontSize: 20),
                  ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (currentIndex > 0) {
                      currentIndex--;
                    }
                  });
                },
                icon: Icon(Icons.arrow_back_ios),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (currentIndex < cards.length - 1) {
                      currentIndex++;
                    }
                  });
                },
                icon: Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
