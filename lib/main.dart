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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateChatPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
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

            String avatarUrl = loadedChats[index]['Avatar'] ?? '';

            return ListTile(
              title:
                  Text('${loadedChats[index]["participantNames"].join(", ")}'),
              subtitle: Text(lastMessageContent),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child; // La imagen se ha cargado correctamente
                            } else {
                              return CircularProgressIndicator(); // Muestra un indicador de carga mientras se descarga la imagen
                            }
                          },
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Icon(Icons
                                .error); // Muestra un icono de error si ocurre algún problema al cargar la imagen
                          },
                        )
                      : Icon(Icons
                          .error), // Mostrar un ícono de error si la URL de la imagen está vacía
                ),
              ),
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
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Edit'),
                    value: 'edit',
                  ),
                  PopupMenuItem(
                    child: Text('Delete'),
                    value: 'delete',
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditChatPage(
                          chatId: loadedChats[index]["_id"],
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _deleteChat(context, loadedChats[index]["_id"]);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _deleteChat(BuildContext context, String chatId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://cokie-chat-api.onrender.com/chats/$chatId'),
      );
      if (response.statusCode == 200) {
        Provider.of<ChatDataProvider>(context, listen: false)
            .removeChat(chatId);
      } else {
        throw Exception('Failed to delete chat');
      }
    } catch (error) {
      print('Error deleting chat: $error');
    }
  }
}

class CreateChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Chat'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Lógica para crear un nuevo chat
          },
          child: Text('Create Chat'),
        ),
      ),
    );
  }
}

class EditChatPage extends StatelessWidget {
  final String chatId;

  const EditChatPage({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Chat'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Lógica para editar el chat con el ID `chatId`
          },
          child: Text('Edit Chat'),
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
