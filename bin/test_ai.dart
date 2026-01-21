// Test script for AI flashcard generation
// Run with: dart run bin/test_ai.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:bookmark/firebase_options.dart';
import 'package:bookmark/services/prompt_service.dart';

void main() async {
  print('🔥 Initializing Firebase...');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('✅ Firebase initialized\n');

  final promptService = PromptService();

  // Test content - a short paragraph about photosynthesis
  const testContent = '''
Photosynthesis is the process by which plants convert light energy into chemical energy.
It occurs primarily in the leaves, where chlorophyll absorbs sunlight.
The process takes in carbon dioxide from the air and water from the soil,
producing glucose and releasing oxygen as a byproduct.
The chemical equation is: 6CO2 + 6H2O + light energy → C6H12O6 + 6O2.
Photosynthesis is essential for life on Earth as it produces oxygen and forms
the base of most food chains.
''';

  print('📝 Test content:');
  print('-' * 50);
  print(testContent);
  print('-' * 50);
  print('\n🤖 Generating flashcards...\n');

  try {
    final flashcards = await promptService.generateFromText(
      testContent,
      cardCount: 5,
    );

    print('✅ Generated ${flashcards.length} flashcards:\n');

    for (var i = 0; i < flashcards.length; i++) {
      print('Card ${i + 1}:');
      print('  Q: ${flashcards[i].front}');
      print('  A: ${flashcards[i].back}');
      print('');
    }

    print('🎉 Test completed successfully!');
  } catch (e, stack) {
    print('❌ Error generating flashcards: $e');
    print('\nStack trace:');
    print(stack);
  }
}
