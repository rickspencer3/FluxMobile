import 'package:flutter/material.dart';
import 'package:flux_mobile/influxDB.dart';

class SimpleQueryGraphExample extends StatefulWidget {
  final String url;
  final String org;
  final String token;

  SimpleQueryGraphExample({this.url, this.org, this.token});

  @override
  _SimpleQueryGraphExampleState createState() =>
      _SimpleQueryGraphExampleState();
}

class _SimpleQueryGraphExampleState extends State<SimpleQueryGraphExample> {
  InfluxDBLineGraph graph;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10.0),
              child: graph == null
                  ? Center(
                      child:
                          Text("Enter a query below and click the run button"),
                    )
                  : Container(
                      padding: EdgeInsets.all(10.0),
                      constraints: BoxConstraints(maxHeight: 350.00),
                      child: graph),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                padding: EdgeInsets.all(5.0),
                child: TextField(
                  controller: textEditingController,
                  maxLines: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.play_arrow),
        onPressed: _executeQuery,
      ),
    );
  }

  // Below is the interesting bit
  // Creates an InfluxDBQueryObject, executes it,
  // and then greates an InfluxDBLineGraph
  void _executeQuery() async {
    setState(() {
      graph = null;
    });
    InfluxDBQuery query = InfluxDBQuery(
        queryString: textEditingController.text,
        influxDBUrl: widget.url,
        org: widget.org,
        token: widget.token);
    List<InfluxDBTable> tables = await query.execute();
    print(tables.length);
    setState(() {
      graph = InfluxDBLineGraph(
        tables: tables,
      );
    });
  }
}
