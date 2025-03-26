import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../generated/app_localizations.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'event_stats_page.dart';

class EventLogsPage extends StatefulWidget {
  final Event event;
  final EventService eventService;

  const EventLogsPage({
    super.key,
    required this.event,
    required this.eventService,
  });

  @override
  State<EventLogsPage> createState() => _EventLogsPageState();
}

class _EventLogsPageState extends State<EventLogsPage> {
  List<DateTime> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 从数据库直接获取日志，而不是使用Event对象中的logs
        final logs = await widget.eventService.getEventLogs(widget.event.id);

        if (mounted) {
          setState(() {
            _logs = logs;
            _isLoading = false;
          });
        }

        debugPrint('加载到${logs.length}条日志记录');
      } catch (e) {
        debugPrint('加载日志时出错: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.event.name} - ${AppLocalizations.of(context).eventLogs}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: AppLocalizations.of(context).statistics,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventStatsPage(
                    event: widget.event,
                    eventService: widget.eventService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('暂无记录'))
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return ListTile(
                        title:
                            Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(log)),
                      );
                    },
                  ),
                ),
    );
  }
}
