import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/network/api_client.dart';

class ExportService {
  ExportService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> shareOutstanding(String format) async {
    final extension = format == 'excel' ? 'xlsx' : format;
    final response = await _apiClient.download('/reports/export/$format');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/outstanding-report.$extension');
    await file.writeAsBytes(response.bodyBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Outstanding customer report');
  }
}
