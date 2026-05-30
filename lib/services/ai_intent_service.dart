import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter/services.dart';
import 'word_embedding.dart';

enum IntentType {
  addEvent,
  deleteEvent,
  viewToday,
  viewWeek,
  viewEvents,
  setReminder,
  unknown,
}

class IntentResult {
  final IntentType type;
  final String? title;
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final String? location;
  final int? reminderMinutes;

  IntentResult({
    required this.type,
    this.title,
    this.dateTime,
    this.endDateTime,
    this.location,
    this.reminderMinutes,
  });
}

class AIIntentService {
  OnnxRuntime? _ort;
  OrtSession? _session;
  WordEmbedding? _wordEmbedding;
  bool _isInitialized = false;
  bool _useFallback = true;

  static const List<String> _intentLabels = [
    'addEvent',
    'deleteEvent',
    'viewToday',
    'viewWeek',
    'viewEvents',
    'setReminder',
    'unknown',
  ];

  Future<void> initialize() async {
    _wordEmbedding = WordEmbedding.createDefault();
    
    if (_isInitialized) {
      dispose();
    }
    
    try {
      _ort = OnnxRuntime();
      await rootBundle.load('assets/models/intent_model.onnx');
      _session = await _ort!.createSessionFromAsset('assets/models/intent_model.onnx');
      _useFallback = false;
    } catch (e) {
      _useFallback = true;
    }
    
    _isInitialized = true;
  }

  Future<IntentResult> recognize(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_useFallback) {
      return _recognizeWithRules(text);
    }

    try {
      return await _recognizeWithModel(text);
    } catch (e) {
      return _recognizeWithRules(text);
    }
  }

  Future<IntentResult> _recognizeWithModel(String text) async {
    if (_session == null || _wordEmbedding == null) {
      return _recognizeWithRules(text);
    }

    final inputVector = _wordEmbedding!.sentenceToVector(text, maxLength: 32);
    final inputShape = [1, 160];
    
    final inputs = {
      'input': await OrtValue.fromList(inputVector, inputShape),
    };

    final outputs = await _session!.run(inputs);
    final output = await outputs['output']!.asList() as List<double>;

    int maxIndex = 0;
    double maxScore = output[0];
    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxScore) {
        maxScore = output[i];
        maxIndex = i;
      }
    }

    final intentLabel = _intentLabels[maxIndex];
    return _buildIntentResult(intentLabel, text);
  }

  IntentResult _recognizeWithRules(String text) {
    final lowerInput = text.toLowerCase().trim();

    if (lowerInput.contains('添加') || lowerInput.contains('创建') || 
        lowerInput.contains('新建') || lowerInput.contains('安排')) {
      return _parseAddEvent(lowerInput);
    }

    if (lowerInput.contains('删除') || lowerInput.contains('取消') || 
        lowerInput.contains('移除')) {
      return _parseDeleteEvent(lowerInput);
    }

    if (lowerInput.contains('查看') || lowerInput.contains('查询') || 
        lowerInput.contains('有什么')) {
      return _parseViewEvent(lowerInput);
    }

    if (lowerInput.contains('提醒') || lowerInput.contains('闹钟')) {
      return _parseReminder(lowerInput);
    }

    return IntentResult(type: IntentType.unknown);
  }

  IntentResult _parseAddEvent(String input) {
    String? title;
    DateTime? dateTime;
    String? location;

    final titlePatterns = [
      RegExp(r'(添加|创建|新建|安排)\s*(.*?)\s*(在|于|今天|明天|后天|本周|下周|会议|日程)'),
      RegExp(r'(会议|约会|日程|事项|活动)\s*([^\s，,]+)'),
      RegExp(r'(添加|创建|新建|安排)\s*([^\s]+)'),
    ];

    for (var pattern in titlePatterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.groupCount >= 2) {
        title = match.group(2)?.trim();
        break;
      }
    }

    dateTime = _parseDateTime(input);
    location = _parseLocation(input);

    return IntentResult(
      type: IntentType.addEvent,
      title: title ?? '未命名事件',
      dateTime: dateTime,
      endDateTime: dateTime?.add(const Duration(hours: 1)),
      location: location,
    );
  }

  IntentResult _parseDeleteEvent(String input) {
    String? title;

    final patterns = [
      RegExp(r'(删除|取消|移除)\s*(.*?)\s*(会议|约会|日程)'),
      RegExp(r'(删除|取消|移除)\s*([^\s]+)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        title = match.group(2)?.trim();
        break;
      }
    }

    return IntentResult(
      type: IntentType.deleteEvent,
      title: title,
    );
  }

  IntentResult _parseViewEvent(String input) {
    if (input.contains('今天') || input.contains('今日')) {
      return IntentResult(type: IntentType.viewToday);
    }

    if (input.contains('周') || input.contains('星期')) {
      return IntentResult(type: IntentType.viewWeek);
    }

    return IntentResult(type: IntentType.viewEvents);
  }

  IntentResult _parseReminder(String input) {
    String? title;
    DateTime? dateTime;
    int? reminderMinutes;

    final titleMatch = RegExp(r'(提醒|闹钟)\s*(.*?)\s*(在|于|今天|明天|后天|时间|点|分)')
        .firstMatch(input);
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

    return IntentResult(
      type: IntentType.setReminder,
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
      if (hour != null && minute != null && hour >= 0 && hour < 24 && 
          minute >= 0 && minute < 60) {
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

  String? _parseLocation(String input) {
    final locationMatch = RegExp(r'(在|于)\s*([^\s，,。]+)').firstMatch(input);
    return locationMatch?.group(2)?.trim();
  }

  IntentResult _buildIntentResult(String label, String text) {
    switch (label) {
      case 'addEvent':
        return _parseAddEvent(text);
      case 'deleteEvent':
        return _parseDeleteEvent(text);
      case 'viewToday':
        return IntentResult(type: IntentType.viewToday);
      case 'viewWeek':
        return IntentResult(type: IntentType.viewWeek);
      case 'viewEvents':
        return IntentResult(type: IntentType.viewEvents);
      case 'setReminder':
        return _parseReminder(text);
      default:
        return IntentResult(type: IntentType.unknown);
    }
  }

  void dispose() {
    _session?.close();
  }

  bool get useFallback => _useFallback;
}