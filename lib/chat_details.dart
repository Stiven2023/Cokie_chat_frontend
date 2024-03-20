import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class ChatDetailsPage extends StatefulWidget {
  final String chatId;

  const ChatDetailsPage({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  late IO.Socket socket;
  late TextEditingController _messageController;
  late List<Map<String, dynamic>> messages;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    messages = [];
    _connectToSocket();
    _fetchChatMessages();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void _connectToSocket() {
    socket = IO.io('https://cokie-chat-api.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Connected to socket');
    });

    socket.onReconnect((_) {
      print('Reconnected to socket');
      _fetchChatMessages();
    });

    socket.onReconnecting((_) {
      print('Reconnecting...');
    });

    socket.on('newMessage', (message) {
      print('Received message from server: $message');
      setState(() {
        messages.add(message);
      });
      _scrollToBottom();
    });

    socket.connect();
  }

  void _fetchChatMessages() async {
    final url =
        Uri.parse('https://cokie-chat-api.onrender.com/chats/${widget.chatId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> chatWithMessages =
            json.decode(response.body);
        setState(() {
          messages =
              List<Map<String, dynamic>>.from(chatWithMessages["messages"]);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        print(
            'Failed to fetch chat messages. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching chat messages: $error');
    }
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) {
      return;
    }

    final messageData = {
      'user_id': '65f34f195da2ba0e7c8d5d86',
      'contentMessage': message,
      'chatId': widget.chatId,
    };

    final jsonData = jsonEncode(messageData);

    final url = Uri.parse('https://cokie-chat-api.onrender.com/messages');
    http
        .post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonData,
    )
        .then((response) {
      if (response.statusCode == 201) {
        print('Message sent successfully: $message');
        _messageController.clear();
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
      }
    }).catchError((error) {
      print('Error sending message: $error');
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (BuildContext ctx, index) {
                final message = messages[index];
                final isSender2 =
                    message['sender'] == '65f34f195da2ba0e7c8d5d86';
                final messageAlign = isSender2
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start;
                final messageColor =
                    isSender2 ? Colors.lightGreen : Colors.grey;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: messageAlign,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: messageColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${message["content"]}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                            const SizedBox(height: 8.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${_getFormattedDate(message["createdAt"])}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }
}
