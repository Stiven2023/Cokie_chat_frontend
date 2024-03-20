import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'chat_data_provider.dart';

import 'chat_details.dart';
import 'statistics.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatDataProvider()),
        FutureProvider<List<Map<String, dynamic>>>(
          create: (context) => _fetchChats(context),
          initialData: const [],
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _connectToWebSocket();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      title: 'Chat App',
      home: const HomePage(),
      routes: {
        '/chatDetails': (context) => const ChatDetailsPage(
              chatId: "",
            ),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> loadedChats =
        Provider.of<List<Map<String, dynamic>>>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StatisticsPage(loadedChats: loadedChats),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: loadedChats.length,
          itemBuilder: (BuildContext ctx, index) {
            List<dynamic> messages = loadedChats[index]['messages'];
            String lastMessageContent =
                messages.isNotEmpty ? messages.last['content'] : 'No messages';

            return ListTile(
              title:
                  Text('${loadedChats[index]["participantNames"].join(", ")}'),
              subtitle: Text(lastMessageContent),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailsPage(
                      chatId: loadedChats[index]["_id"],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> _fetchChats(BuildContext context) async {
  final response =
      await http.get(Uri.parse('https://cokie-chat-api.onrender.com/chats'));
  if (response.statusCode == 200) {
    final List<dynamic> decodedData = json.decode(response.body);
    print(decodedData);
    Provider.of<ChatDataProvider>(context, listen: false)
        .updateChats(decodedData.cast<Map<String, dynamic>>());
    return decodedData.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load chats');
  }
}

void _connectToWebSocket() {
  try {
    final chatChannel = IOWebSocketChannel.connect(
        'wss://cokie-chat-api.onrender.com/messages');
    final messageChannel =
        IOWebSocketChannel.connect('wss://cokie-chat-api.onrender.com/chats');
    print('WebSocket connected successfully.');
  } catch (e) {
    print('Error connecting to WebSocket: $e');
  }
}
