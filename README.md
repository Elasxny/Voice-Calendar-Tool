# 语音日历工具

一个基于Flutter的语音交互日历管理工具，帮助用户通过语音快速添加、删除和查看日程安排。

## 功能特性

- **语音添加日程**：通过语音命令快速创建日历事件
- **语音删除日程**：通过语音命令删除已有的日历事件
- **语音查询日程**：通过语音查询今天或本周的日程安排
- **语音提醒设置**：通过语音设置事件提醒
- **日历视图**：直观的月历视图，支持日期选择和事件标记
- **事件管理**：支持查看、编辑和删除事件
- **本地存储**：使用Hive数据库持久化存储日程数据

## 技术栈

- **框架**：Flutter 3.x
- **语音识别**：speech_to_text
- **文字转语音**：flutter_tts
- **日历组件**：table_calendar
- **本地存储**：Hive
- **状态管理**：Provider

## 支持的语音命令

### 添加日程
- "添加会议在今天下午3点"
- "创建约会明天晚上7点"
- "新建事项在办公室"

### 删除日程
- "删除会议"
- "取消约会"

### 查看日程
- "查看今天的日程"
- "查询本周安排"
- "我今天有什么事"

### 设置提醒
- "提醒我明天早上9点开会"
- "设置闹钟下午4点"

## 开发环境

1. 安装Flutter SDK
2. 克隆项目
3. 安装依赖：`flutter pub get`
4. 生成Hive适配器：`flutter pub run build_runner build`
5. 运行项目：`flutter run`

## 项目结构

```
lib/
├── main.dart              # 主入口文件
├── models/
│   └── calendar_event.dart # 日历事件模型
├── services/
│   ├── speech_service.dart     # 语音服务
│   ├── calendar_service.dart   # 日历服务
│   └── voice_command_parser.dart # 语音命令解析器
└── widgets/
    ├── calendar_view.dart      # 日历视图组件
    ├── event_list.dart         # 事件列表组件
    ├── event_detail_dialog.dart # 事件详情对话框
    └── voice_command_button.dart # 语音命令按钮组件
```

## 许可证

MIT License