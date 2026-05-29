import '../models/calendar_event.dart';

enum CommandType {
  addEvent,
  deleteEvent,
  viewEvents,
  viewToday,
  viewWeek,
  setReminder,
  unknown,
}

class ParsedCommand {
  final CommandType type;
  final String? title;
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final String? description;
  final String? location;
  final int? reminderMinutes;

  ParsedCommand({
    required this.type,
    this.title,
    this.dateTime,
    this.endDateTime,
    this.description,
    this.location,
    this.reminderMinutes,
  });
}

class VoiceCommandParser {
  ParsedCommand parse(String input) {
    final lowerInput = input.toLowerCase().trim();
    
    if (lowerInput.contains('添加') || lowerInput.contains('创建') || lowerInput.contains('新建')) {
      return _parseAddEvent(lowerInput);
    }
    
    if (lowerInput.contains('删除') || lowerInput.contains('取消')) {
      return _parseDeleteEvent(lowerInput);
    }
    
    if (lowerInput.contains('查看') || lowerInput.contains('查询') || lowerInput.contains('有什么')) {
      return _parseViewEvent(lowerInput);
    }
    
    if (lowerInput.contains('提醒') || lowerInput.contains('闹钟')) {
      return _parseReminder(lowerInput);
    }
    
    return ParsedCommand(type: CommandType.unknown);
  }

  ParsedCommand _parseAddEvent(String input) {
    String? title;
    DateTime? dateTime;
    DateTime? endDateTime;
    String? description;
    String? location;

    final titleMatch = RegExp(r'(添加|创建|新建)\s*(.*?)\s*(在|于|今天|明天|后天|本周|下周)').firstMatch(input);
    if (titleMatch != null && titleMatch.groupCount >= 2) {
      title = titleMatch.group(2)?.trim();
    }

    if (title == null || title.isEmpty) {
      final titleMatch2 = RegExp(r'(会议|约会|日程|事项|事件|活动)\s*([^\s]+)').firstMatch(input);
      if (titleMatch2 != null) {
        title = titleMatch2.group(2)?.trim();
      }
    }

    if (title == null || title.isEmpty) {
      final titleMatch3 = RegExp(r'(添加|创建|新建)\s*([^\s]+)').firstMatch(input);
      if (titleMatch3 != null) {
        title = titleMatch3.group(2)?.trim();
      }
    }

    dateTime = _parseDateTime(input);
    if (dateTime != null) {
      endDateTime = dateTime.add(const Duration(hours: 1));
    }

    final locationMatch = RegExp(r'(在|于)\s*([^\s，,]+)').firstMatch(input);
    if (locationMatch != null) {
      location = locationMatch.group(2)?.trim();
    }

    return ParsedCommand(
      type: CommandType.addEvent,
      title: title ?? '未命名事件',
      dateTime: dateTime,
      endDateTime: endDateTime,
      description: description,
      location: location,
    );
  }

  ParsedCommand _parseDeleteEvent(String input) {
    String? title;
    
    final titleMatch = RegExp(r'(删除|取消)\s*(.*?)\s*(会议|约会|日程)').firstMatch(input);
    if (titleMatch != null) {
      title = titleMatch.group(2)?.trim();
    }
    
    if (title == null) {
      final titleMatch2 = RegExp(r'(删除|取消)\s*([^\s]+)').firstMatch(input);
      if (titleMatch2 != null) {
        title = titleMatch2.group(2)?.trim();
      }
    }

    return ParsedCommand(
      type: CommandType.deleteEvent,
      title: title,
    );
  }

  ParsedCommand _parseViewEvent(String input) {
    if (input.contains('今天') || input.contains('今日')) {
      return ParsedCommand(type: CommandType.viewToday);
    }
    
    if (input.contains('周') || input.contains('星期')) {
      return ParsedCommand(type: CommandType.viewWeek);
    }
    
    return ParsedCommand(type: CommandType.viewEvents);
  }

  ParsedCommand _parseReminder(String input) {
    String? title;
    DateTime? dateTime;
    int? reminderMinutes;

    final titleMatch = RegExp(r'(提醒|闹钟)\s*(.*?)\s*(在|于|今天|明天|后天|时间|点|分)').firstMatch(input);
    if (titleMatch != null) {
      title = titleMatch.group(2)?.trim();
    }

    dateTime = _parseDateTime(input);

    final reminderMatch = RegExp(r'(提前)\s*(\d+)\s*(分钟|小时)').firstMatch(input);
    if (reminderMatch != null) {
      final num = int.tryParse(reminderMatch.group(2) ?? '');
      if (num != null) {
        reminderMinutes = reminderMatch.group(3) == '小时' ? num * 60 : num;
      }
    }

    return ParsedCommand(
      type: CommandType.setReminder,
      title: title ?? '提醒',
      dateTime: dateTime,
      reminderMinutes: reminderMinutes ?? 15,
    );
  }

  DateTime? _parseDateTime(String input) {
    final now = DateTime.now();
    
    if (input.contains('今天')) {
      return _parseTime(input, now);
    }
    
    if (input.contains('明天')) {
      return _parseTime(input, now.add(const Duration(days: 1)));
    }
    
    if (input.contains('后天')) {
      return _parseTime(input, now.add(const Duration(days: 2)));
    }
    
    if (input.contains('本周') || input.contains('这周末')) {
      final daysUntilWeekend = DateTime.saturday - now.weekday + 1;
      return _parseTime(input, now.add(Duration(days: daysUntilWeekend)));
    }
    
    if (input.contains('下周')) {
      final daysUntilNextWeek = 8 - now.weekday;
      return _parseTime(input, now.add(Duration(days: daysUntilNextWeek)));
    }
    
    final dayMatch = RegExp(r'(\d+)号').firstMatch(input);
    if (dayMatch != null) {
      final day = int.tryParse(dayMatch.group(1) ?? '');
      if (day != null && day > 0 && day <= 31) {
        return _parseTime(input, DateTime(now.year, now.month, day));
      }
    }
    
    return null;
  }

  DateTime? _parseTime(String input, DateTime baseDate) {
    final timeMatch = RegExp(r'(\d+)\s*[:：]\s*(\d+)').firstMatch(input);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '');
      final minute = int.tryParse(timeMatch.group(2) ?? '');
      if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }
    }
    
    final hourMatch = RegExp(r'(\d+)\s*(点|点钟|时)').firstMatch(input);
    if (hourMatch != null) {
      final hour = int.tryParse(hourMatch.group(1) ?? '');
      if (hour != null && hour >= 0 && hour < 24) {
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, 0);
      }
    }
    
    return DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
  }
}