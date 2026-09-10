import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/condition_report.dart';
import 'condition_report_repository.dart';

/// Generic REST-API-backed implementation of [ConditionReportRepository].
///
/// Not wired up — `main.dart` injects [FirebaseConditionReportRepository]
/// by default. This is kept as an alternative for teams that end up on a
/// custom REST backend instead of Firebase; point [baseUrl] at it and
/// swap the one line in `main.dart` — no screen, widget, or provider
/// code needs to change either way.
///
/// Expected endpoints (adjust paths to match your actual API):
/// - `POST   {baseUrl}/reports`                     → create; body = report JSON, returns created report JSON
/// - `GET    {baseUrl}/users/{userId}/reports`       → list of report JSON objects for that user
/// - `PATCH  {baseUrl}/reports/{id}/status`           → body = { "status": ..., "adminComment": ... }
/// - `DELETE {baseUrl}/reports/{id}`                  → delete
///
/// Every request/response body uses exactly the shape produced by
/// [ConditionReport.toJson] / consumed by [ConditionReport.fromJson].
class RemoteConditionReportRepository implements ConditionReportRepository {
  final String baseUrl;
  final http.Client _client;

  /// Optional callback to attach auth headers (e.g. a bearer token) to
  /// every request. Left null until an auth strategy is decided.
  final Map<String, String> Function()? authHeaders;

  RemoteConditionReportRepository({
    required this.baseUrl,
    http.Client? client,
    this.authHeaders,
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        ...?authHeaders?.call(),
      };

  @override
  Future<ConditionReport> createReport(ConditionReport report) async {
    final response = await _client.post(
      _uri('/reports'),
      headers: _headers,
      body: jsonEncode(report.toJson()),
    );
    _throwIfError(response);
    return ConditionReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<ConditionReport>> getUserReports(String userId) async {
    final response =
        await _client.get(_uri('/users/$userId/reports'), headers: _headers);
    _throwIfError(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ConditionReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConditionReport> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminComment,
  }) async {
    final response = await _client.patch(
      _uri('/reports/$reportId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status.name,
        'adminComment': adminComment,
      }),
    );
    _throwIfError(response);
    return ConditionReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    final response =
        await _client.delete(_uri('/reports/$reportId'), headers: _headers);
    _throwIfError(response);
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteRepositoryException(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class RemoteRepositoryException implements Exception {
  final String message;
  RemoteRepositoryException(this.message);

  @override
  String toString() => message;
}
