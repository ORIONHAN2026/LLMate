import 'dart:convert';

import 'package:shelf/shelf.dart';

const jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> openAiErrorBody({
  required String message,
  required String type,
  dynamic code,
  dynamic param,
  Map<String, dynamic>? extra,
}) {
  return {
    'error': {
      'message': message,
      'type': type,
      'param': param,
      if (code != null) 'code': code,
      if (extra != null) ...extra,
    },
  };
}

Response openAiErrorResponse({
  required int statusCode,
  required String message,
  required String type,
  dynamic code,
  dynamic param,
  Map<String, dynamic>? extra,
}) {
  return Response(
    statusCode,
    body: jsonEncode(
      openAiErrorBody(
        message: message,
        type: type,
        code: code,
        param: param,
        extra: extra,
      ),
    ),
    headers: jsonHeaders,
  );
}

({Map<String, dynamic>? body, Response? error}) parseJsonObjectBody(
  String body,
) {
  if (body.trim().isEmpty) {
    return (body: null, error: null);
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return (body: decoded, error: null);
    }
  } catch (_) {
    return (
      body: null,
      error: openAiErrorResponse(
        statusCode: 400,
        message: 'Request body must be valid JSON.',
        type: 'invalid_request_error',
        code: 'invalid_json',
      ),
    );
  }

  return (
    body: null,
    error: openAiErrorResponse(
      statusCode: 400,
      message: 'Request body must be a JSON object.',
      type: 'invalid_request_error',
      code: 'invalid_request_body',
    ),
  );
}

String redactSecret(String? value) {
  if (value == null || value.isEmpty) return '';
  if (value.length <= 8) return '****';
  return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
}

String safeFileNameSegment(String value) {
  final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return safe.isEmpty ? 'unknown' : safe;
}
