import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'influxdb_dashboard.dart';
import 'influxdb_query.dart';

class InfluxDBApi {
  final String influxDBUrl;
  final String org;
  final String token;

  InfluxDBApi(
      {@required this.influxDBUrl,
      @required this.org,
      @required this.token});

  InfluxDBQuery query(String queryString) {
    return InfluxDBQuery(api: this, queryString: queryString);
  }

  Future<List<InfluxDBDashboard>> dashboards() async {
    dynamic body = await _getJSONData("/api/v2/dashboards");
    return InfluxDBDashboard.fromAPIList(api: this, objects: body["dashboards"]);
  }

  Future<InfluxDBDashboardCell> dashboardCell(InfluxDBDashboardCellInfo cell) async {
    dynamic body = await _getJSONData("/api/v2/dashboards/${cell.dashboard.id}/cells/${cell.id}/view");
    return InfluxDBDashboardCell.fromAPI(dashboard: cell.dashboard, object: body);
  }

  Future<String> postFluxQuery(String queryString) async {
    Response response = await post(
      _getURL("/api/v2/query"),
      headers: {
        "Authorization": "Token $token",
        "Accept": "application/csv",
        "Content-type": "application/vnd.flux",
      },
      body: queryString,
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      _handleError(response);
    }
  }

  String _getURL(urlSuffix) {
    String url = influxDBUrl;
    if (url[url.length - 1] == "/") {
      url = url.substring(0, url.length - 1);
    }

    url += urlSuffix;

    if (url.indexOf("?") >= 0) {
      url = url + "&org=$org";
    } else {
      url = url + "?org=$org";
    }
    return url;
  }

  Future<dynamic> _getJSONData(urlSuffix) async {
    Response response = await get(
      _getURL(urlSuffix),
      headers: {
        "Authorization": "Token $token",
        "Content-type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      dynamic body = json.decode(response.body);
      return body;
    } else {
      _handleError(response);
    }
  }

  _handleError(Response response) {
    // TODO: provide real error handling and possibly multiple classes for convenient catching
    throw("HTTP ERROR - TODO - IMPROVE");
  }
}
