import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/condition_report.dart';
import 'condition_report_repository.dart';

/// REST-API-backed implementation of [ConditionReportRepository].
///
/// Not wired up yet — `main.dart` currently injects
/// [LocalConditionReportRepository] into [ConditionReportService]. Once a
/// backend endpoint exists, point [baseUrl] at it and swap that one line
/// in `main.dart`; no screen, widget, or provider code needs to change.
///
/// Expected endpoints (adjust paths to match your actual API):
/// - `GET    {baseUrl}/reports`              → list of report JSON objects
/// - `POST   {baseUrl}/reports`               → create; body = report JSON, returns created report JSON
/// - `PATCH  {baseUrl}/reports/{id}/status`    → admin verification; body = { "status": ..., "adminVerification": ... }
/// - `DELETE {baseUrl}/reports/{id}`           → delete
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
  Future<List<ConditionReport>> fetchAll() async {
    final response = await _client.get(_uri('/reports'), headers: _headers);
    _throwIfError(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ConditionReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConditionReport> create(ConditionReport report) async {
    final response = await _client.post(
      _uri('/reports'),
      headers: _headers,
      body: jsonEncode(report.toJson()),
    );
    _throwIfError(response);
    return ConditionReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<ConditionReport> updateStatus({
    required String reportId,
    required ReportStatus status,
    AdminVerification? adminVerification,
  }) async {
    final response = await _client.patch(
      _uri('/reports/$reportId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status.name,
        'adminVerification': adminVerification?.toJson(),
      }),
    );
    _throwIfError(response);
    return ConditionReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String reportId) async {
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
