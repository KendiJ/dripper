import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This initializes Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DripCheckApp());
}

class DripCheckApp extends StatelessWidget {
  const DripCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DripCheck AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFA3E635),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA3E635), // Lime green
            foregroundColor: const Color(0xFF0A0A0A), // Black text
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Hides the debug banner
      home: const DripCheckHomePage(),
    );
  }
}

class DripCheckHomePage extends StatefulWidget {
  const DripCheckHomePage({super.key});

  @override
  State<DripCheckHomePage> createState() => _DripCheckHomePageState();
}

class _DripCheckHomePageState extends State<DripCheckHomePage> {
  final _textController = TextEditingController();
  String _aiResponse = '';
  bool _isLoading = false;

  // This is our function to call the AI
  Future<void> _checkMyDrip() async {
    if (_textController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = '';
    });

    try {
      // 1. Initialize the Gemini AI model
      final model = FirebaseVertexAI.instance
          .generativeModel(model: 'gemini-1.5-flash');

      // 2. NEW: Load our prompt template from the assets
      final promptTemplate =
          await rootBundle.loadString('assets/prompt.md');

      // 3. NEW: Inject the user's text into our template
      final finalPrompt = promptTemplate.replaceAll(
          '{{OUTFIT}}', _textController.text);

      // 4. Send the *final* prompt to the AI
      final response = await model.generateContent([Content.text(finalPrompt)]);

      // 5. Update our app with the AI's response
      setState(() {
        _aiResponse = response.text ?? 'Error: No response from AI.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '💧 DripCheck AI',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., white tee, denim jeans, white sneakers',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkMyDrip,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        )
                      : const Text('Check My Drip'),
                ),
                const SizedBox(height: 30),
                if (_aiResponse.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // We use Markdown to get nice formatting!
                    child: MarkdownBody(
                      data: _aiResponse,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, height: 1.4),
                        h1: const TextStyle(fontSize: 24, color: Color(0xFFA3E635)),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}