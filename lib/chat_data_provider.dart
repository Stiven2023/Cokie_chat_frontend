import 'package:flutter/material.dart';

class ChatDataProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _chats = [];
  Map<String, dynamic> _selectedChat = {};

  List<Map<String, dynamic>> get chats => _chats;
  Map<String, dynamic> get selectedChat => _selectedChat;

  void updateChats(List<Map<String, dynamic>> chats) {
    _chats = chats;
    notifyListeners();
  }

  void updateSingleChat(Map<String, dynamic> chat) {
    _selectedChat = chat;
    notifyListeners();
  }
}
