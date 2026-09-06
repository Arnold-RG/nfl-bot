import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';

enum _ExportFormat { json, csv }

/// Lets the user take everything the app knows about them with them, and
/// erase it. Health data should never be locked inside one app.
class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  _ExportFormat _format = _ExportFormat.json;

  String get _payload {
    final data = AppServices.storage.exportAll();
    return _format == _ExportFormat.json
        ? const JsonEncoder.withIndent('  ').convert(data)
        : _toCsv(data);
  }

  /// Flattens the nested export into `section,metric,value` rows, with the
  /// history series expanded one sample per row.
  String _toCsv(Map<String, dynamic> data) {
    final rows = <String>['section,metric,value'];

    String escape(Object? v) {
      final s = '$v';
      return s.contains(',') || s.contains('"')
          ? '"${s.replaceAll('"', '""')}"'
          : s;
    }

    void writeMap(String section, Map<String, dynamic> map) {
      for (final entry in map.entries) {
        final value = entry.value;
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            rows.add('$section,${entry.key}[$i],${escape(value[i])}');
          }
        } else if (value is Map) {
          writeMap('$section/${entry.key}', value.cast<String, dynamic>());
        } else {
          rows.add('$section,${entry.key},${escape(value)}');
        }
      }
    }

    rows.add('meta,exported_at,${escape(data['exported_at'])}');
    writeMap('profile', (data['profile'] as Map).cast<String, dynamic>());
    writeMap('today', (data['today'] as Map).cast<String, dynamic>());
    writeMap('totals', (data['totals'] as Map).cast<String, dynamic>());
    writeMap('history', (data['history'] as Map).cast<String, dynamic>());

    return rows.join('\n');
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_format.name.toUpperCase()} copied to clipboard'),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmErase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all health data?'),
        content: const Text(
          'This permanently deletes your profile, food logs, sleep logs, '
          'workout history and every vitals baseline stored on this device. '
          'It cannot be undone.\n\n'
          'Export a copy first if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AppServices.storage.eraseAll();
    if (!mounted) return;
    context.read<AppState>().loadFromStorage();
    AppServices.intelligence.recompute();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All local health data erased')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final lineCount = payload.split('\n').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Your data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const Text(
              'Export or erase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Everything below is stored only on this device. Copy it out in '
              'a format you can open in a spreadsheet or hand to a clinician.',
              style: TextStyle(color: Color(0xFF5F6F72), height: 1.4),
            ),
            const SizedBox(height: 20),
            SegmentedButton<_ExportFormat>(
              segments: const [
                ButtonSegment(
                  value: _ExportFormat.json,
                  label: Text('JSON'),
                  icon: Icon(Icons.data_object_rounded, size: 16),
                ),
                ButtonSegment(
                  value: _ExportFormat.csv,
                  label: Text('CSV'),
                  icon: Icon(Icons.table_rows_rounded, size: 16),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (s) => setState(() => _format = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_all_rounded),
                label: Text('Copy ${_format.name.toUpperCase()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Preview · $lineCount lines',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 320),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1512),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  payload,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF9FE8C8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Danger zone',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Erasing wipes your local store completely. Your AI key is kept '
              'separately in secure storage and is removed from Settings.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF5F6F72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmErase,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Erase all health data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
