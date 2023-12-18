import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future <void> main() async{

  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI ChatGPT Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatGPTPage(),
    );
  }
}

class ChatGPTPage extends StatefulWidget {
  ChatGPTPage({Key? key}) : super(key: key);
  @override
  _ChatGPTPageState createState() => _ChatGPTPageState();
}

class _ChatGPTPageState extends State<ChatGPTPage> {
  final TextEditingController _controller = TextEditingController();
  String _output = '';

  Future<void> getChatGPTResponse() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _output = 'Please enter a message.';
      });
      return;
    }

    var url = Uri.parse('https://api.openai.com/v1/chat/completions');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.env['ChatGPT_API']}',
    };

    var body = jsonEncode({
      'model': 'gpt-3.5-turbo-1106',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful assistant designed to output JSON.'
        },
        {'role': 'user', 'content': _controller.text},
      ],
    });

    int retries = 3; // Set a maximum number of retries
    int delay = 1000; // Initial delay in milliseconds


        while (retries > 0) {
          try {
            var response = await http.post(url, headers: headers, body: body);

            if (response.statusCode == 200) {
              var data = jsonDecode(response.body);
              setState(() {
                _output = data['choices'][0]['message']['content'];
              });
              return; // Break out of the retry loop if successful
            } else if (response.statusCode == 429) {
              // If 429 Too Many Requests, apply exponential backoff and retry
              await Future.delayed(Duration(milliseconds: delay));
              delay *= 2; // Exponential backoff
              retries--;
            } else {
              setState(() {
                _output =
                'Error: Failed to get response from ChatGPT (${response
                    .statusCode})';
              });
              return;
            }
          } catch (e) {
            setState(() {
              _output = 'Error: $e';
            });
            return;
          }
        }

        setState(() {
          _output = 'Error: Maximum retries exceeded.';
        });
      }




      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('OpenAI ChatGPT Example'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter your message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    getChatGPTResponse();
                  },
                  child: const Text('Get ChatGPT Response'),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _output,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }


