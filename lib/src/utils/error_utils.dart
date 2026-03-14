/// A utility to handle and normalize responses from the host application.
/// It also translates technical exceptions into user-friendly messages.
class ErrorUtils {
  /// Normalizes a dynamic response from the host-app (e.g., from Dio/Http).
  ///
  /// - If the response is a 'Response' object (has statusCode), it checks for errors.
  /// - Extracts '.data' if available.
  /// - Throws a user-friendly message if statusCode >= 400.
  static dynamic handleResponse(dynamic response) {
    if (response == null) return null;

    // Check for common 'Response' patterns (like Dio or http.Response)
    try {
      // We use dynamic access to avoid direct dependency on Dio
      final dynamic res = response;
      final int? statusCode = _tryGetProperty(res, 'statusCode');

      if (statusCode != null && statusCode >= 400) {
        final String? statusMessage = _tryGetProperty(res, 'statusMessage');
        final dynamic data = _tryGetProperty(res, 'data');
        
        String errorMessage = 'Error $statusCode';
        if (statusMessage != null && statusMessage.isNotEmpty) {
          errorMessage = statusMessage;
        } else if (data != null && data is Map && data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else {
          errorMessage = _getFriendlyStatusMessage(statusCode);
        }
        
        throw errorMessage;
      }

      // If it looks like a Response object, try to extract the data part
      if (statusCode != null) {
        final dynamic data = _tryGetProperty(res, 'data');
        if (data != null) return data;
      }
    } catch (e) {
      if (e is String) rethrow; // Our custom error message
      // Otherwise, it might not be a 'Response' object, so we just proceed
    }

    return response;
  }

  /// Converts technical exceptions into readable strings.
  static String toFriendlyMessage(dynamic e) {
    final String errorStr = e.toString();

    if (errorStr.contains('DioException')) {
      if (errorStr.contains('connection timeout') || errorStr.contains('SocketException')) {
        return 'Connection failed. Please check your internet.';
      }
      if (errorStr.contains('400')) return 'Bad Request (400)';
      if (errorStr.contains('401')) return 'Unauthorized (401)';
      if (errorStr.contains('403')) return 'Access Forbidden (403)';
      if (errorStr.contains('404')) return 'Not Found (404)';
      if (errorStr.contains('500')) return 'Server Error (500)';
    }
    
    if (errorStr.contains('SqliteException')) {
      return 'Database error occurred.';
    }

    // Strip "Exception: " prefix if present
    return errorStr.replaceFirst('Exception: ', '').replaceFirst('error: ', '');
  }

  static dynamic _tryGetProperty(dynamic object, String propertyName) {
    try {
      // In Dart, we can't easily check for properties on 'dynamic' without reflection (mirrors),
      // except if it behaves like a Map or we just try-catch a call.
      // However, for typical Response objects, they are classes.
      if (object is Map) return object[propertyName];
      
      // Attempting to access property via dynamic
      switch (propertyName) {
        case 'statusCode': return object.statusCode;
        case 'statusMessage': return object.statusMessage;
        case 'data': return object.data;
        default: return null;
      }
    } catch (_) {
      return null;
    }
  }

  static String _getFriendlyStatusMessage(int code) {
    switch (code) {
      case 400: return 'Bad Request (400)';
      case 401: return 'Authentication Required (401)';
      case 403: return 'Access Denied (403)';
      case 404: return 'Resource Not Found (404)';
      case 405: return 'Method Not Allowed (405)';
      case 408: return 'Request Timeout (408)';
      case 500: return 'Internal Server Error (500)';
      case 502: return 'Bad Gateway (502)';
      case 503: return 'Service Unavailable (503)';
      default: return 'Request failed ($code)';
    }
  }
}
