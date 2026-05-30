import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import 'event_detail_dialog.dart';

class ScheduleView extends StatelessWidget {
  final List<CalendarEvent> allEvents;
  final void Function(CalendarEvent) onEventTapped;
  final void Function(CalendarEvent) onDeleteEvent;

  const ScheduleView({
    super.key,
    required this.allEvents,
    required this.onEventTapped,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<CalendarEvent>.from(allEvents)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: _buildEventList(context, sortedEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '所有日程',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '共 ${allEvents.length} 个日程',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventList(BuildContext context, List<CalendarEvent> events) {
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
        return ScheduleEventCard(
          event: event,
          onTap: () => onEventTapped(event),
          onDelete: () => onDeleteEvent(event),
        );
      },
    );
  }
}

class ScheduleEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ScheduleEventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy年MM月dd日').format(event.startDateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        event.location!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              if (event.hasReminder && event.reminderTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '提醒：${DateFormat('HH:mm').format(event.reminderTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}