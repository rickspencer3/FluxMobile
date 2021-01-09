import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flux_mobile/src/api/variables.dart';

import '../api/api.dart';
import './table.dart';

/// InfluxDB 2.0 query, using the Flux language as query language.
/// Construct with an [InfluxDBAPI] object, and Flux query string.
/// execute() will return the tables, and also the tables property
/// will be available like: myInfluxDBQuery.tables
class InfluxDBQuery {
  /// Instance of [InfluxDBAPI] object for running the InfluxDB API calls.
  final InfluxDBAPI api;

  /// Query string to run.
  final String queryString;

  /// Platform Variables
  final List<InfluxDBVariable> variables;

  /// Tables with the result, only available after `execute` has been called.
  List<InfluxDBTable> tables = [];

  /// Creates a new instance of [InfluxDBQuery] using [InfluxDBAPI] for running the InfluxDB API and the query to run.
  InfluxDBQuery(
      {@required this.api, @required this.queryString, this.variables});

  CsvToListConverter converter = CsvToListConverter();

  /// Executes the query and returns a [Future] to [List] of [InfluxDBTable] objects.
  Future<List<InfluxDBTable>> execute() async {
    // clear out the tables from previous runs
    tables = [];

    //First get back the csv for the query
    String body = await api.postFluxQuery(queryString, variables: variables);

    // Track the current set of keys for the columns of each table
    List<String> currentKeys = [];

    // Keep a list of rows for each table encountered
    List<List<dynamic>> currentDataRows = [];
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

            // The first thing positions in the row are not needed, as they are:
            // [0] blank
            // [1] the yield name
            // [2] the table incriment
            currentKeys = List<String>.from(row.sublist(3));
          }
        } else {
          if (row[2].runtimeType == int) {
            // ignore: unrelated_type_equality_checks
            if (row[2] == currentTable) {
              // when the third position is an integer, it means it is the able id
              // if the row's id matches the currentTable, then it is part of that table
              currentDataRows.add(row.sublist(3));
            } else {
              // if the table id is different, then that means a new table has started, but
              // with the same schema

              // create a mew table with the accumulated rows
              tables.add(InfluxDBTable.fromCSV(currentDataRows, currentKeys));

              // flush and start accumulating again for the next table
              currentTable = row[2]; // increment the table id
              currentDataRows.clear();
              currentDataRows.add(row.sublist(3));
            }
          }
        }
      }
    });
    if (currentDataRows.length > 0) {
      tables.add(InfluxDBTable.fromCSV(currentDataRows, currentKeys));
    }
    return tables;
  }
}
