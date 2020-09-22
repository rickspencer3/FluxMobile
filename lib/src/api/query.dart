import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';

import '../api/api.dart';
import './table.dart';

/// InfluxDB 2.0 query, using the Flux language as query syntax.
class InfluxDBQuery {
  /// Instance of [InfluxDBAPI] object for running the InfluxDB API calls.
  final InfluxDBAPI api;

  /// Query string to run.
  final String queryString;

  /// Tables with the result, only available after `execute` has been called.
  List<InfluxDBTable> tables = [];

  /// Creates a new instance of [InfluxDBQuery] using [InfluxDBAPI] for running the InfluxDB API and the query to run.
  InfluxDBQuery({@required this.api, @required this.queryString});

  CsvToListConverter converter = CsvToListConverter();

  /// Executes the query and returns a [Future] to [List] of [InfluxDBTable] objects.
  Future<List<InfluxDBTable>> execute() async {

    //First get back the csv for the query
    String body = await api.postFluxQuery(queryString);

    // Track the current set of keys for the columns of each table
    List<String> currentKeys = List<String>();

    // Keep a list of rows for each table encountered
    List<List<dynamic>> currentDataRows = List<List<dynamic>>();
    int currentTable = 0; // counter to track the current table

    // use the csv library to convert each row into a List (a list of lists)
    List<List<dynamic>> allRows = converter.convert(body);

    allRows.forEach((List<dynamic> row) {
      if (row.length == 1) { 
        // The row length is 1 when changine between tables in different yield 
        // statements from a query, so this is always between tables
        tables.add(InfluxDBTable.fromCSV(currentDataRows, currentKeys));
        currentDataRows.clear();
      } else {
        if (row[2].runtimeType == String) {
          // ignore: unrelated_type_equality_checks
          if (row[2] == "table") {
            // when the third position is the string "table" it means
            // we are encountering a new table schema
            currentKeys = List<String>.from(row);
          }
        } else {
          if (row[2].runtimeType == int) {
            // ignore: unrelated_type_equality_checks
            if (row[2] == currentTable) {
              // when the third position is an integer, it means it is the able id
              // if the row's id matches the currentTable, then it is part of that table
              currentDataRows.add(row);
            } else {
              // if the table id is different, then that means a new table has started, but
              // with the same schema

              currentTable = row[2]; // increment the table id

              // add the existing rows to a table
              tables.add(InfluxDBTable.fromCSV(currentDataRows, currentKeys));
              currentDataRows.clear();
            }
          }
        }
      }
    });
    return tables;
  }
}
