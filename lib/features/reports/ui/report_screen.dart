import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../requests/data/request_model.dart';
import '../logic/report_controller.dart';
import '../logic/reports_service.dart';

class ScopeReportScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final List<RequestModel> requests;

  const ScopeReportScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.requests,
  });

  @override
  State<ScopeReportScreen> createState() => _ScopeReportScreenState();
}

class _ScopeReportScreenState extends State<ScopeReportScreen> {
  Uint8List? _pdf;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final bytes = await ReportService.instance.generateScopeReport(
      clientName: widget.clientName,
      requests: widget.requests,
    );
    final outOfScope = widget.requests.where((r) => !r.inScope).toList();
    final total = outOfScope.fold<int>(
      0,
      (sum, r) => sum + (r.estimatedCost ?? 0),
    );
    await ReportsService.instance.addReport(
      clientId: widget.clientId,
      title: 'Scope report for ${widget.clientName}',
      outOfScopeCount: outOfScope.length,
      totalExtra: total,
    );
    if (!mounted) return;
    setState(() {
      _pdf = bytes;
      _loading = false;
    });
  }

  void _downloadWeb() {
    if (_pdf == null) return;
    final blob = html.Blob([_pdf!], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'scope-report-${widget.clientName}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final outOfScope = widget.requests.where((r) => !r.inScope).toList();
    final total = outOfScope.fold<int>(
      0,
      (sum, r) => sum + (r.estimatedCost ?? 0),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Scope Report')),
      body: Responsive.centeredContent(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.clientName, style: AppText.h2(context)),
            const SizedBox(height: 6),
            Text(
              '${outOfScope.length} out-of-scope requests · '
              '${Formatters.currency(total)} extra',
              style: AppText.bodyMuted(context),
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Responsive.radius(context)),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: kIsWeb ? _downloadWeb : null,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download PDF'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 240.ms).slideY(begin: .04, end: 0),
      ),
    );
  }
}
