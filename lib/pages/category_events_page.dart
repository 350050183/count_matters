import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'event_logs_page.dart';

class CategoryEventsPage extends StatefulWidget {
  final Category category;
  final EventService eventService;

  const CategoryEventsPage({
    super.key,
    required this.category,
    required this.eventService,
  });

  @override
  State<CategoryEventsPage> createState() => _CategoryEventsPageState();
}

class _CategoryEventsPageState extends State<CategoryEventsPage> {
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMoreEvents = true;
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await widget.eventService.getEvents();
    if (mounted) {
      setState(() {
        _events = events
            .where((event) => event.categoryId == widget.category.id)
            .toList();
        _hasMoreEvents = events.length == _pageSize;
      });
    }
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).addEvent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventName,
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventDescription,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final event = await widget.eventService.addEvent(
                  nameController.text,
                  widget.category.id,
                );
                if (descriptionController.text.isNotEmpty) {
                  event.description = descriptionController.text;
                  await widget.eventService.updateEvent(event);
                }
                _loadEvents();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    final nameController = TextEditingController(text: event.name);
    final descriptionController =
        TextEditingController(text: event.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).editEvent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventName,
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventDescription,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                event.name = nameController.text;
                event.description = descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text;
                await widget.eventService.updateEvent(event);
                _loadEvents();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.category.name} - ${AppLocalizations.of(context).eventTitle}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _events.length + (_hasMoreEvents ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _events.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                          _loadEvents();
                        });
                      },
                      child: Text(AppLocalizations.of(context).loadMore),
                    ),
                  );
                }

                final event = _events[index];
                return ListTile(
                  title: Text(event.name),
                  subtitle: event.description != null
                      ? Text(event.description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await widget.eventService.logEventClick(event.id);
                          _loadEvents();
                        },
                        child: Text(
                          '${AppLocalizations.of(context).clickCount}: ${event.clickCount}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventLogsPage(
                                event: event,
                                eventService: widget.eventService,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditEventDialog(event),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      Text(AppLocalizations.of(context).hint),
                                  content: Text(
                                      '${AppLocalizations.of(context).deleteEvent}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                          AppLocalizations.of(context).cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        AppLocalizations.of(context).confirm,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (confirm) {
                            await widget.eventService.deleteEvent(event.id);
                            _loadEvents();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
