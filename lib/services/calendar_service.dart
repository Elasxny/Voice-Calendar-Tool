import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';

class CalendarService {
  late Box<CalendarEvent> _eventsBox;

  Future<void> initialize() async {
    _eventsBox = await Hive.openBox<CalendarEvent>('calendar_events');
  }

  Future<void> addEvent(CalendarEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsBox.delete(eventId);
  }

  List<CalendarEvent> getAllEvents() {
    return _eventsBox.values.toList();
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _eventsBox.values
        .where((event) => 
            event.startDateTime.isAfter(startOfDay) && 
            event.startDateTime.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  List<CalendarEvent> getEventsForToday() {
    return getEventsForDate(DateTime.now());
  }

  List<CalendarEvent> getEventsForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return _eventsBox.values
        .where((event) => 
            event.startDateTime.isAfter(startOfWeek) && 
            event.startDateTime.isBefore(endOfWeek))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  CalendarEvent? getEventById(String id) {
    return _eventsBox.get(id);
  }

  Map<DateTime, List<CalendarEvent>> getEventsMap() {
    final map = <DateTime, List<CalendarEvent>>{};
    
    for (var event in _eventsBox.values) {
      final dateKey = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(event);
    }
    
    return map;
  }

  Future<void> clearAllEvents() async {
    await _eventsBox.clear();
  }

  void dispose() {
    _eventsBox.close();
  }
}