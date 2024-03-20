import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class StatisticsPage extends StatelessWidget {
  final List<Map<String, dynamic>> loadedChats;

  const StatisticsPage({Key? key, required this.loadedChats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: charts.PieChart(
              _getMessageCountByChatData(loadedChats),
              animate: true,
              defaultRenderer: charts.ArcRendererConfig(
                arcRendererDecorators: [charts.ArcLabelDecorator()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<charts.Series<MessageCount, String>> _getMessageCountByChatData(
      List<Map<String, dynamic>> chats) {
    List<MessageCount> messageCounts = [];

    chats.forEach((chat) {
      String chatId = chat['_id'];
      int messageCount = chat['messages'].length;
      messageCounts.add(MessageCount(chatId, messageCount));
    });

    return [
      charts.Series<MessageCount, String>(
        id: 'Message Count',
        domainFn: (MessageCount messageCount, _) => messageCount.chatId,
        measureFn: (MessageCount messageCount, _) => messageCount.count,
        data: messageCounts,
        labelAccessorFn: (MessageCount row, _) => '${row.chatId}: ${row.count}',
      )
    ];
  }
}

class MessageCount {
  final String chatId;
  final int count;

  MessageCount(this.chatId, this.count);
}
