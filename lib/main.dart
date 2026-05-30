import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models/calendar_event.dart';
import 'services/speech_service.dart';
import 'services/calendar_service.dart';
import 'services/voice_command_parser.dart';
import 'services/ai_intent_service.dart';
import 'widgets/calendar_view.dart';
import 'widgets/event_list.dart';
import 'widgets/voice_command_button.dart';
import 'widgets/event_detail_dialog.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/agent_view.dart';
import 'widgets/schedule_view.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(CalendarEventAdapter());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '语音日历',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showSemanticsDebugger: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechService _speechService = SpeechService();
  final CalendarService _calendarService = CalendarService();
  final VoiceCommandParser _commandParser = VoiceCommandParser();
  final AIIntentService _aiIntentService = AIIntentService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isListening = false;
  String _recognizedText = '';
  String _statusMessage = '点击麦克风开始语音输入';
  bool _isInitialized = false;
  bool _useAIMode = false;
  ViewType _currentView = ViewType.agent;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
    await _calendarService.initialize();
    await _aiIntentService.initialize();
    setState(() {
      _isInitialized = true;
      _selectedDay = DateTime.now();
      _useAIMode = !_aiIntentService.useFallback;
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
      _processCommand(_recognizedText);
    } else {
      setState(() {
        _recognizedText = '';
        _statusMessage = '正在听...';
      });
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
        },
        onListening: () {
          setState(() {
            _isListening = true;
          });
        },
        onStopped: () {
          setState(() {
            _isListening = false;
          });
        },
      );
    }
  }

  void _processCommand(String commandText) async {
    if (commandText.isEmpty) {
      _setStatusMessage('未识别到语音输入');
      return;
    }

    String response = '';

    if (_useAIMode) {
      response = await _processWithAI(commandText);
    } else {
      final parsedCommand = _commandParser.parse(commandText);
      response = await _processWithRules(parsedCommand);
    }

    _setStatusMessage(response);
    await _speechService.speak(response);
  }

  Future<String> _processWithAI(String commandText) async {
    try {
      final intentResult = await _aiIntentService.recognize(commandText);
      
      switch (intentResult.type) {
        case IntentType.addEvent:
          return await _handleAIAddEvent(intentResult);
        case IntentType.deleteEvent:
          return await _handleAIDeleteEvent(intentResult);
        case IntentType.viewToday:
          return await _handleViewToday();
        case IntentType.viewWeek:
          return await _handleViewWeek();
        case IntentType.viewEvents:
          return await _handleViewEvents();
        case IntentType.setReminder:
          return await _handleAISetReminder(intentResult);
        case IntentType.unknown:
          return '抱歉，我没有理解您的指令';
      }
    } catch (e) {
      return await _fallbackToRules(commandText);
    }
  }

  Future<String> _processWithRules(ParsedCommand parsedCommand) async {
    switch (parsedCommand.type) {
      case CommandType.addEvent:
        return await _handleAddEvent(parsedCommand);
      case CommandType.deleteEvent:
        return await _handleDeleteEvent(parsedCommand);
      case CommandType.viewToday:
        return await _handleViewToday();
      case CommandType.viewWeek:
        return await _handleViewWeek();
      case CommandType.viewEvents:
        return await _handleViewEvents();
      case CommandType.setReminder:
        return await _handleSetReminder(parsedCommand);
      case CommandType.unknown:
        return '抱歉，我没有理解您的指令';
    }
  }

  Future<String> _fallbackToRules(String commandText) async {
    final parsedCommand = _commandParser.parse(commandText);
    return await _processWithRules(parsedCommand);
  }

  Future<String> _handleAIAddEvent(IntentResult result) async {
    final title = result.title ?? '未命名事件';
    final dateTime = result.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    final endDateTime = result.endDateTime ?? dateTime.add(const Duration(hours: 1));
    
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startDateTime: dateTime,
      endDateTime: endDateTime,
      location: result.location,
    );
    
    await _calendarService.addEvent(event);
    setState(() {
      _selectedDay = dateTime;
    });
    
    return 'AI识别：已添加日程：$title，时间：${DateFormat('MM月dd日 HH:mm').format(dateTime)}';
  }

  Future<String> _handleAIDeleteEvent(IntentResult result) async {
    if (result.title == null) {
      return '请告诉我要删除的日程名称';
    }
    
    final events = _calendarService.getAllEvents();
    final matchedEvent = events.firstWhere(
      (e) => e.title.contains(result.title!),
      orElse: () => CalendarEvent(
        id: '',
        title: '',
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now(),
      ),
    );
    
    if (matchedEvent.id.isEmpty) {
      return '未找到名为 "${result.title}" 的日程';
    }
    
    await _calendarService.deleteEvent(matchedEvent.id);
    return 'AI识别：已删除日程：${matchedEvent.title}';
  }

  Future<String> _handleAISetReminder(IntentResult result) async {
    final title = result.title ?? '提醒';
    final dateTime = result.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    final reminderMinutes = result.reminderMinutes ?? 15;
    final reminderTime = dateTime.subtract(Duration(minutes: reminderMinutes));
    
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startDateTime: dateTime,
      endDateTime: dateTime.add(const Duration(hours: 1)),
      hasReminder: true,
      reminderTime: reminderTime,
    );
    
    await _calendarService.addEvent(event);
    return 'AI识别：已设置提醒：$title，时间：${DateFormat('MM月dd日 HH:mm').format(dateTime)}';
  }

  Future<String> _handleAddEvent(ParsedCommand command) async {
    final title = command.title ?? '未命名事件';
    final dateTime = command.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    final endDateTime = command.endDateTime ?? dateTime.add(const Duration(hours: 1));
    
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startDateTime: dateTime,
      endDateTime: endDateTime,
      location: command.location,
    );
    
    await _calendarService.addEvent(event);
    setState(() {
      _selectedDay = dateTime;
    });
    
    return '已添加日程：$title，时间：${DateFormat('MM月dd日 HH:mm').format(dateTime)}';
  }

  Future<String> _handleDeleteEvent(ParsedCommand command) async {
    if (command.title == null) {
      return '请告诉我要删除的日程名称';
    }
    
    final events = _calendarService.getAllEvents();
    final matchedEvent = events.firstWhere(
      (e) => e.title.contains(command.title!),
      orElse: () => CalendarEvent(
        id: '',
        title: '',
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now(),
      ),
    );
    
    if (matchedEvent.id.isEmpty) {
      return '未找到名为 "${command.title}" 的日程';
    }
    
    await _calendarService.deleteEvent(matchedEvent.id);
    return '已删除日程：${matchedEvent.title}';
  }

  Future<String> _handleViewToday() async {
    setState(() {
      _selectedDay = DateTime.now();
      _currentView = ViewType.calendar;
    });
    
    final events = _calendarService.getEventsForToday();
    if (events.isEmpty) {
      return '今天没有日程安排';
    }
    
    String response = '今天有 ${events.length} 个日程：';
    for (var event in events) {
      response += '${event.title}在${event.formattedTime}，';
    }
    return response;
  }

  Future<String> _handleViewWeek() async {
    final events = _calendarService.getEventsForWeek(DateTime.now());
    if (events.isEmpty) {
      return '本周没有日程安排';
    }
    
    String response = '本周有 ${events.length} 个日程：';
    for (var event in events) {
      response += '${event.formattedDate} ${event.title}，';
    }
    return response;
  }

  Future<String> _handleViewEvents() async {
    setState(() {
      _currentView = ViewType.schedule;
    });
    
    final events = _calendarService.getAllEvents();
    if (events.isEmpty) {
      return '日历中没有任何日程';
    }
    
    return '日历中共有 ${events.length} 个日程';
  }

  Future<String> _handleSetReminder(ParsedCommand command) async {
    final title = command.title ?? '提醒';
    final dateTime = command.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    final reminderMinutes = command.reminderMinutes ?? 15;
    final reminderTime = dateTime.subtract(Duration(minutes: reminderMinutes));
    
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startDateTime: dateTime,
      endDateTime: dateTime.add(const Duration(hours: 1)),
      hasReminder: true,
      reminderTime: reminderTime,
    );
    
    await _calendarService.addEvent(event);
    return '已设置提醒：$title，时间：${DateFormat('MM月dd日 HH:mm').format(dateTime)}';
  }

  void _setStatusMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onEventTapped(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailDialog(
        event: event,
        onClose: () => Navigator.pop(context),
        onEdit: () => Navigator.pop(context),
      ),
    );
  }

  void _onDeleteEvent(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${event.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _calendarService.deleteEvent(event.id);
              Navigator.pop(context);
              setState(() {});
              _setStatusMessage('已删除日程：${event.title}');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    final events = _calendarService.getEventsMap();
    final List<CalendarEvent> selectedEvents = _selectedDay != null 
        ? _calendarService.getEventsForDate(_selectedDay!) 
        : <CalendarEvent>[];
    final List<CalendarEvent> allEvents = _calendarService.getAllEvents();

    switch (_currentView) {
      case ViewType.agent:
        return AgentView(
          isListening: _isListening,
          onToggleListening: _toggleListening,
          statusMessage: _statusMessage,
          recognizedText: _recognizedText,
        );
      case ViewType.calendar:
        return Column(
          children: [
            CalendarView(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              events: events,
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
            ),
            const Divider(height: 1),
            Expanded(
              child: EventList(
                events: selectedEvents,
                onEventTapped: _onEventTapped,
                onDeleteEvent: _onDeleteEvent,
              ),
            ),
          ],
        );
      case ViewType.schedule:
        return ScheduleView(
          allEvents: allEvents,
          onEventTapped: _onEventTapped,
          onDeleteEvent: _onDeleteEvent,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            currentView: _currentView,
            onViewChanged: (viewType) {
              setState(() {
                _currentView = viewType;
              });
            },
          ),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    _calendarService.dispose();
    _aiIntentService.dispose();
    super.dispose();
  }
}