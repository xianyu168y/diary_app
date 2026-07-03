# Diary App — 技术文档

## 项目概述

Flutter 本地日记本 App，支持 Android。核心功能：日记书写、待办管理、番茄钟专注、专注统计。所有数据本地 Hive 存储，不联网。

## 快速开始

```bash
# 环境要求
# Flutter SDK >= 3.12（C:\tools\flutter）
# Android SDK 36（C:\Users\92024\Android\Sdk）
# JDK 21

# 国内需设置代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

cd C:\Users\92024\Desktop\diary_app
flutter pub get
flutter run

# 编译 Release APK
flutter build apk --release --target-platform android-arm64 --split-debug-info=build/debug-info --obfuscate
```

## 项目结构

```
lib/
├── main.dart                     # 入口，MaterialApp + ThemeProvider
├── app_theme.dart                # 浅色/深色双主题配色
├── models/                       # 数据模型
│   ├── diary_entry.dart          # 日记（mood/tags/images/pinned）
│   ├── diary_category.dart       # 日记分类
│   ├── todo_task.dart            # 待办（priority/deadline/repeatType）
│   ├── category.dart             # 待办分类
│   ├── pomodoro_record.dart      # 番茄记录
│   └── focus_goal.dart           # 专注目标
├── services/                     # 数据持久化
│   ├── diary_service.dart        # 日记 CRUD + 图片存取
│   ├── diary_category_service.dart
│   ├── todo_service.dart         # 待办 CRUD（按优先级排序）
│   ├── category_service.dart
│   ├── pomodoro_service.dart     # 番茄钟计时（单例）+ 待办绑定
│   ├── focus_goal_service.dart
│   └── theme_provider.dart       # 主题/密码锁状态管理
└── pages/                        # UI 页面
    ├── home_page.dart            # 底部导航（4 Tab）
    ├── diary_page.dart           # 日记列表+搜索+分类+多选+置顶
    ├── diary_editor_page.dart    # 写日记（图片/心情/标签/模板）
    ├── todo_page.dart            # 待办列表+番茄联动
    ├── pomodoro_page.dart        # 番茄钟
    └── stats_page.dart           # 统计+目标+情绪+小树林
```

## 关键架构

### 1. 番茄钟全局单例
PomodoroService 是单例，跨 Tab 切换不销毁。计时状态每秒持久化到 Hive，切回自动恢复。

```dart
final service = PomodoroService(); // 始终返回同一实例
```

### 2. 待办-番茄钟联动
- 待办右侧番茄按钮调用 bindToTodo() 绑定
- 番茄完成时自动累加 totalFocusMinutes
- PomodoroRecord.categoryId 存绑定待办 ID
- UI 展示通过 TodoService 查询任务名，不渲染原始 UUID

### 3. 深色/浅色双主题
app_theme.dart 定义两套 ThemeData。所有页面通过 isDark 判断，禁止硬编码颜色值。

| Token | 浅色 | 深色 |
|-------|------|------|
| 背景 | #FFFDF5 | #1F1C18 |
| 卡片 | #FFFFFF | #2E2A26 |
| 主文字 | #5D4037 | #F2EAD3 |
| 强调色 | #FFA500 | #FFAA33 |

### 4. 数据存储
全部 Hive 本地存储，每个模块独立 Box。

### 5. 日记密码锁
ThemeProvider 管理密码状态。锁定状态渲染 PIN 输入屏替代日记内容。输错 5 次锁定 30 秒。

## 常见维护

### 编译 Release APK
```bash
flutter build apk --release --target-platform android-arm64 --split-debug-info=build/debug-info --obfuscate
```
输出：`build/app/outputs/flutter-apk/app-release.apk`

### 中文路径
项目必须在纯英文路径下编译，中文路径会导致 Dart AOT 编译失败。

### 国内网络
```bash
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
```

### UUID 乱码展示
所有 id/categoryId/bindTomatoId 等主键/外键字段禁止直接渲染到 UI，必须通过 Service 查询业务名称显示。

## 版本历史

| 版本 | 说明 |
|------|------|
| 1.0.0 | 初始：日记/待办/番茄钟 |
| 1.0.1 | 自定义时长 + 图标 |
| 1.0.2 | 待办多选批量模式 |
| 1.1.0 | 统计+设置+深色主题+日记分类+番茄联动 |
| 1.1.1 | 日记搜索/标签/模板+优先级/截止日期/重复+语录+密码锁+小树林+情绪日历 |