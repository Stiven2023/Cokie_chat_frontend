import 'package:flutter/material.dart';
import 'package:charts_flutter_new/flutter.dart' as charts;

class StatisticsPage extends StatelessWidget {
  final List<Map<String, dynamic>> loadedChats;

  const StatisticsPage({Key? key, required this.loadedChats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TimeSeriesSales> messageCounts =
        _getMessageCountByChatData(loadedChats);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BarChart(messageCounts),
          ),
        ),
      ),
    );
  }

  List<TimeSeriesSales> _getMessageCountByChatData(
      List<Map<String, dynamic>> chats) {
    final Map<String, int> messageCounts = {};

    for (int i = 1; i <= 12; i++) {
      messageCounts[i.toString()] = 0;
    }

    chats.forEach((chat) {
      final DateTime timestamp = DateTime.parse(chat['createdAt']);
      final month = timestamp.month.toString();
      // Verificar si chat['messages'] es nulo antes de acceder a su longitud
      final messages = chat['messages'] as List?;
      if (messages != null) {
        messageCounts[month] = (messageCounts[month] ?? 0) + messages.length;
      }
    });

    final List<TimeSeriesSales> seriesList = [];
    messageCounts.forEach((month, sales) {
      seriesList.add(TimeSeriesSales(month, sales));
    });

    return seriesList.reversed.take(5).toList();
  }
}

class TimeSeriesSales {
  final String month;
  final int sales;

  TimeSeriesSales(this.month, num sales) : sales = sales.toInt();
}

class BarChart extends StatelessWidget {
  final List<TimeSeriesSales> seriesList;

  const BarChart(this.seriesList, {Key? key});

  @override
  Widget build(BuildContext context) {
    seriesList.sort((a, b) => int.parse(a.month).compareTo(int.parse(b.month)));

    return charts.BarChart(
      [
        charts.Series<TimeSeriesSales, String>(
          id: 'Message Count',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.month,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: seriesList,
        )
      ],
      animate: true,
      animationDuration: const Duration(seconds: 2),
      behaviors: [
        charts.SlidingViewport(),
        charts.PanBehavior(),
        charts.SeriesLegend(),
      ],
      domainAxis: const charts.OrdinalAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
          labelRotation: -45,
        ),
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, getMaxSales(seriesList)),
        tickProviderSpec: const charts.BasicNumericTickProviderSpec(
          // Configurar el intervalo de las etiquetas del eje y
          desiredTickCount: 5,
        ),
      ),
    );
  }

  double getMaxSales(List<TimeSeriesSales> seriesList) {
    double maxSales = 0;
    for (final sale in seriesList) {
      if (sale.sales > maxSales) {
        maxSales = sale.sales.toDouble();
      }
    }
    return maxSales * 1.2;
  }
}
