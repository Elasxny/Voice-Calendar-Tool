import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class EventDetailDialog extends StatelessWidget {
  final CalendarEvent event;
  final void Function() onClose;
  final void Function() onEdit;

  const EventDetailDialog({
    super.key,
    required this.event,
    required this.onClose,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(event.formattedDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(event.formattedTime),
                if (event.formattedEndTime.isNotEmpty)
                  Text(' - ${event.formattedEndTime}'),
              ],
            ),
            if (event.location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18),
                    const SizedBox(width: 8),
                    Text(event.location!),
                  ],
                ),
              ),
            if (event.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            if (event.hasReminder && event.reminderTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, size: 18),
                    const SizedBox(width: 8),
                    Text('提醒: ${event.reminderTime!.hour.toString().padLeft(2, '0')}:${event.reminderTime!.minute.toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('编辑'),
        ),
      ],
    );
  }
}