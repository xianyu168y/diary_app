# Diary App — 技术文档

Flutter 本地日记本 App，支持 Android。核心功能：日记书写、待办管理、番茄钟专注、专注统计。所有数据本地 Hive 存储，不联网。

## 快速开始

```bash
# 环境要求
# Flutter SDK >= 3.12
# Android SDK 34+
# JDK 17

# 国内需设置代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

flutter pub get
flutter run

# 编译 Release APK
flutter build apk --release --split-per-abi
```

## 项目结构

```
lib/
├── main.dart                           # 入口 → AppDependencies.init() + MaterialApp
├── app_theme.dart                      # 浅色/深色双主题配色
│
├── core/
│   ├── app_dependencies.dart           # 依赖容器：统一创建/初始化所有 Service
│   ├── logger/app_logger.dart          # 统一日志工具
│   └── repository/crud_repository.dart # CrudRepository<T> 泛型基类
│
├── models/                             # 数据模型
│   ├── diary_entry.dart                # 日记（mood/tags/images/pinned）
│   ├── diary_category.dart             # 日记分类
│   ├── todo_task.dart                  # 待办（priority/deadline/repeatType/copyWith）
│   ├── pomodoro_record.dart            # 番茄记录
│   └── focus_goal.dart                 # 专注目标
│
├── repositories/                       # 数据仓库（接口 + Hive 实现）
│   ├── todo/        TodoRepository / HiveTodoRepository
│   ├── diary/       DiaryRepository / HiveDiaryRepository
│   ├── pomodoro/    PomodoroRepository / HivePomodoroRepository
│   └── goal/        GoalRepository / HiveGoalRepository
│
├── services/                           # 业务层（构造注入，不直接操作 Hive）
│   ├── todo_service.dart               # 待办 CRUD + 缓存 + 排序
│   ├── diary_service.dart              # 日记 CRUD + 图片管理
│   ├── pomodoro_service.dart           # 番茄钟计时 + 震动提醒
│   ├── focus_goal_service.dart         # 专注目标 CRUD
│   ├── diary_category_service.dart     # 日记分类
│   └── theme_provider.dart             # 主题/密码锁状态管理
│
├── features/                           # 业务特性
│   ├── stats/                          # 专注统计（拆分为独立 Widget）
│   │   ├── models/stats_data.dart
│   │   ├── services/stats_service.dart
│   │   └── widgets/ (today_card / week_card / period_bars / ...)
│   │
│   └── export/export_service.dart      # 数据导出（JSON，支持全部 4 种数据）
│
└── pages/                              # UI 页面
    ├── home_page.dart                  # 底部导航（4 Tab）+ 每日一语
    ├── diary_page.dart                 # 日记列表+搜索+分类+多选+置顶
    ├── diary_editor_page.dart          # 写日记（图片/心情/标签）
    ├── todo_page.dart                  # 待办列表+长按多选+番茄联动
    ├── pomodoro_page.dart              # 番茄钟（自定义时长+待办绑定）
    └── stats_page.dart                 # 统计+目标+情绪+小树林

test/
├── repositories/                       # 假仓库（内存实现，用于测试）
│   ├── fake_todo_repository.dart
│   ├── fake_diary_repository.dart
│   ├── fake_pomodoro_repository.dart
│   └── fake_goal_repository.dart
│
└── services/                           # 业务层单测
    ├── todo_service_test.dart          (7 条)
    ├── diary_service_test.dart         (9 条)
    ├── pomodoro_service_test.dart      (12 条)
    ├── focus_goal_service_test.dart    (9 条)
    └── export_service_test.dart        (2 条)
```

## 架构

### 三层架构

```
UI (pages/)
    ↓  调用
Service (services/)       ← 业务逻辑 + 内存缓存
    ↓  委托
Repository (repositories/) ← 数据存取抽象（接口）
    ↓  实现
Hive                        ← 本地存储
```

### 依赖管理

```dart
// main.dart — 启动时统一初始化
await appDependencies.init();

// 页面中直接使用
appDependencies.todoService.getAll();
appDependencies.diaryService.save(entry);
```

所有 Service 通过 `AppDependencies` 创建并注入 Repository，不自行管理存储。

### 核心设计原则

| 原则 | 说明 |
|------|------|
| Repository 抽象 | 业务层不直接操作 Hive，通过接口访问数据 |
| 构造注入 | Service 通过构造函数接收 Repository，不自行实例化 |
| 内存缓存 | Service 在 `init()` 时加载全量数据到内存，后续读写同步缓存 |
| 假仓库测试 | 测试时注入 `FakeXxxRepository`，不依赖 Hive 文件系统 |

## 设计要点

### 1. 番茄钟状态管理
`PomodoroService` 通过 `AppDependencies` 统一管理（非单例），计时状态每秒持久化到 Hive，页面切换不丢失。

### 2. 待办-番茄钟联动
- 待办右侧番茄按钮调用 `bindToTodo()` 绑定
- 番茄完成时自动累加 `totalFocusMinutes`
- UI 展示通过 `TodoService` 查询任务名

### 3. 深色/浅色双主题
`app_theme.dart` 定义两套 ThemeData。所有页面通过 `isDark` 判断。

| Token | 浅色 | 深色 |
|-------|------|------|
| 背景 | #FFFDF5 | #1F1C18 |
| 卡片 | #FFFFFF | #2E2A26 |
| 主文字 | #5D4037 | #F2EAD3 |
| 强调色 | #FFA500 | #FFAA33 |

### 4. 数据存储
全部 Hive 本地存储，每个模块独立 Box。Repository 封装所有 Hive 操作，Service 层零 Hive 依赖。

### 5. CI / CD

```
git tag v2.4.0 && git push origin v2.4.0
  → GitHub Actions 自动编译 APK
  → 生成更新日志（git log 对比上个 tag）
  → 创建 Release + 上传 APK
```

版本号在 `pubspec.yaml` 手动管理，tag 对齐。不依赖 Node.js / semantic-release。

## 版本历史

| 版本 | 说明 |
|------|------|
| 1.0.0 | 初始：日记/待办/番茄钟 |
| 1.0.1 | 自定义时长 + 图标 |
| 1.0.2 | 待办多选批量模式 |
| 1.1.0 | 统计+设置+深色主题+日记分类+番茄联动 |
| 1.1.1 | 日记搜索/标签/模板+优先级/截止日期/重复+语录+密码锁+小树林+情绪日历 |
| 2.0.0 | StatsPage 重构为 854→107 行 |
| 2.1.0 | TodoRepository + Repository 模式 |
| 2.2.0 | DiaryRepository + 全部 Repository 统一 CrudRepository |
| 2.3.0 | 测试体系建立（39 条单测） |
| 2.4.0 | AppDependencies + Logger + CI 精简 |