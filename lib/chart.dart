import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rapido/rapido.dart';

class Chart extends StatefulWidget {
  final Document userDoc;
  final List<dynamic> queries;

  const Chart({Key key, @required this.userDoc, @required this.queries})
      : super(key: key);
  @override
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  String responseString = "initalizing ...";
  List<List<FlSpot>> lineSpots = [];

  @override
  void initState() {
    super.initState();
    getDataSync();
  }

  getDataSync() async {
    String url = "https://us-west-2-1.aws.cloud2.influxdata.com/api/v2/query";
    url += "?org=${widget.userDoc["org"]}";

    widget.queries.forEach((dynamic queryObj) async {
      Response response = await post(
        url,
        headers: {
          "Authorization": "Token ${widget.userDoc["token"]}",
          "Accept": "application/csv",
          "Content-type": "application/vnd.flux",
        },
        body: queryObj["text"],
      );
      if (response.statusCode != 200) {
        print(
            "WARNING Failed to execute query: $url: ${response.statusCode}: ${response.body}");
        print(queryObj["text"]);
      }
      setState(() {
        CsvToListConverter converter = CsvToListConverter();
        List<List<dynamic>> rows = converter.convert(response.body);
        List<dynamic> keys = rows[0];

        rows.removeAt(0);
        print(keys);
        print("${rows[0]}");
        int valueColumn = keys.indexOf("_value");
        int timeColumn = keys.indexOf("_time");

        List<FlSpot> spots = [];
        rows.forEach((List<dynamic> row) {
          try {
            DateTime t = DateTime.parse(row[timeColumn]);
            double time = double.parse(t.millisecondsSinceEpoch.toString());
            double value = double.parse(row[valueColumn].toString());
            spots.add(
              FlSpot(time, value),
            );
          } catch (Exception) {}
        });
        lineSpots.add(spots);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (lineSpots.length == 0) {
      return Center(child: CircularProgressIndicator());
    }
    List<LineChartBarData> lineChartBarDataList = [];
    lineSpots.forEach((List<FlSpot> spots) {
      lineChartBarDataList.add(
        LineChartBarData(
          spots: spots,
          dotData: FlDotData(show: false),
          colors: [Colors.green],
          barWidth: 0.5,
          belowBarData: BarAreaData(
            show: true,
            colors: [
              Colors.green.withOpacity(.4),
            ],
          ),
        ),
      );
    });
    return Container(
      child: LineChart(
        LineChartData(
          lineBarsData: lineChartBarDataList,
          gridData: FlGridData(
            show: false,
          ),
          backgroundColor: Colors.black,
          
        ),
      ),
    );
  }
}