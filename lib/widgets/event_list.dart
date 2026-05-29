import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class EventList extends StatelessWidget {
  final List<CalendarEvent> events;
  final void Function(CalendarEvent) onEventTapped;
  final void Function(CalendarEvent) onDeleteEvent;

  const EventList({
    super.key,
    required this.events,
    required this.onEventTapped,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无日程安排',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => onEventTapped(event),
          onDelete: () => onDeleteEvent(event),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          event.formattedTime,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (event.formattedEndTime.isNotEmpty)
                          Text(
                            ' - ${event.formattedEndTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (event.location != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            event.location!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}