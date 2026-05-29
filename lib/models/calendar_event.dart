import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 0)
class CalendarEvent {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final DateTime startDateTime;
  
  @HiveField(4)
  final DateTime endDateTime;
  
  @HiveField(5)
  final bool isAllDay;
  
  @HiveField(6)
  final String? location;
  
  @HiveField(7)
  final bool hasReminder;
  
  @HiveField(8)
  final DateTime? reminderTime;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    this.location,
    this.hasReminder = false,
    this.reminderTime,
  });

  String get formattedDate {
    return DateFormat('yyyy年MM月dd日').format(startDateTime);
  }

  String get formattedTime {
    if (isAllDay) {
      return '全天';
    }
    return DateFormat('HH:mm').format(startDateTime);
  }

  String get formattedEndTime {
    if (isAllDay) {
      return '';
    }
    return DateFormat('HH:mm').format(endDateTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'isAllDay': isAllDay,
      'location': location,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'],
      hasReminder: json['hasReminder'] ?? false,
      reminderTime: json['reminderTime'] != null 
          ? DateTime.parse(json['reminderTime']) 
          : null,
    );
  }
}