---
name: taskswiper-ui
description: UI component development and testing for Task Swiper. Use for working with widgets, dialogs, screens, and UI-related logic.
 aliases: [ui, widget, screen, dialog, flutter-ui, ui-test]
 on_include:
   - lib/ui/
   - lib/main.dart
   - lib/providers/
 on_exclude:
   - .dart_tool/
   - build/
---

# TaskSwiper UI Skill

You are an expert in Task Swiper's Flutter UI layer. Help with widgets, dialogs, screens, and UI testing.

## When to Use This Skill

- Creating or modifying widgets in `lib/ui/`
- Working with dialogs (add/edit task, recurrence selector)
- Testing UI components
- Debugging layout issues
- Adding new screens or UI elements

## UI Structure

```
lib/ui/
├── screens/
│   └── task_listing.dart      # Main screen with task carousel
├── dialogs/
│   ├── add_task_list_dialog.dart
│   ├── edit_task_dialog.dart
│   ├── recurrence_selector.dart
│   └── confirm_dialog.dart
└── widgets/
    ├── about_app_dialog.dart
    ├── actionable_icon_button.dart
    ├── separator.dart
    ├── task_item.dart
    └── task_list_drawer.dart
```

## Core Widgets

### Screens

**TaskListing (`lib/ui/screens/task_listing.dart`)**
- Main screen displaying tasks in a carousel
- Uses `CarouselSlider` from `carousel_slider` package
- Shows tasks from selected task list
- Handles swipe gestures (left for complete, right for reopen)
- Filter chips for status filtering

### Dialogs

**RecurrenceSelector (`lib/ui/dialogs/recurrence_selector.dart`)**
- Dropdown for recurrence frequency (daily, weekly)
- Day-of-week chips for weekly recurrence
- Interval input field
- Time picker button
- Calls `onRecurrenceChanged` with `RecurrenceRules?`

**EditTaskDialog (`lib/ui/dialogs/edit_task_dialog.dart`)**
- Text field for task description
- Status selector (open, completed)
- RecurrenceSelector embedded
- Saves to database via `DatabaseService`

**AddTaskListDialog (`lib/ui/dialogs/add_task_list_dialog.dart`)**
- Creates new task lists

**ConfirmDialog (`lib/ui/dialogs/confirm_dialog.dart`)**
- Generic confirmation dialog
- Used for delete operations

### Widgets

**TaskItem (`lib/ui/widgets/task_item.dart`)**
- Displays a single task
- Shows status, description
- Handles tap and swipe gestures
- Displays recurrence icon if task has recurrence

**TaskListDrawer (`lib/ui/widgets/task_list_drawer.dart`)**
- Navigation drawer
- Lists all task lists
- Language selector
- About app link
- Settings/export actions

**ActionableIconButton (`lib/ui/widgets/actionable_icon_button.dart`)**
- Reusable icon button with action

**Separator (`lib/ui/widgets/separator.dart`)**
- Visual separator widget

## Key UI Patterns

### Task Swipe Actions
```dart
// In TaskListing
GestureDetector(
  onHorizontalDragEnd: (details) {
    if (details.primaryVelocity! < 0) {
      // Swipe left -> complete task
      completeTask(task);
    } else if (details.primaryVelocity! > 0) {
      // Swipe right -> reopen task
      reopenTask(task);
    }
  },
)
```

### Carousel Display
```dart
CarouselSlider(
  items: tasks.map((task) => TaskItem(task: task)).toList(),
  options: CarouselOptions(
    height: MediaQuery.of(context).size.height * 0.7,
    viewportFraction: 0.8,
    enableInfiniteScroll: false,
    onPageChanged: (index, reason) {
      setState(() => currentIndex = index);
    },
  ),
)
```

### Task Status Colors
- Open: Default text color
- Completed: Grey/strikethrough

### Recurrence Indicator
- Tasks with `recurrenceId != null` show a repeat icon

## State Management

### Providers
- `SelectedTaskListProvider` - Tracks currently selected task list
- `LanguageProvider` - Tracks current locale

Access via:
```dart
final taskListProvider = Provider.of<SelectedTaskListProvider>(context);
final currentListId = taskListProvider.selectedTaskListId;
```

Or in build methods:
```dart
Consumer<SelectedTaskListProvider>(
  builder: (context, provider, child) {
    return Text(provider.selectedTaskListId.toString());
  },
)
```

## Service Integration

UI components interact with services via `locator` (from `get_it`):
```dart
final databaseService = locator<DatabaseService>();
final tasks = await databaseService.getTasks(taskListId);
```

## Common Tasks

### Add a new widget
1. Create file in `lib/ui/widgets/`
2. Import dependencies
3. Build widget with proper theming
4. Add to exports if needed

### Add a new dialog
1. Create file in `lib/ui/dialogs/`
2. Use `showDialog` pattern:
```dart
showDialog(
  context: context,
  builder: (context) => MyNewDialog(...),
);
```
3. Return result via `Navigator.pop(context, result)`

### Add a new screen
1. Create file in `lib/ui/screens/`
2. Add route to `main.dart` or navigation system
3. Use consistent app bar styling

### Test a widget
Create test file in `test/`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskswiper/ui/widgets/task_item.dart';

void main() {
  testWidgets('TaskItem displays task text', (tester) async {
    final task = Task(null, 'Test task', Status.open, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskItem(task: task),
        ),
      ),
    );
    expect(find.text('Test task'), findsOneWidget);
  });
}
```

### Style Guidelines
- Use `Theme.of(context)` for colors
- Primary swatch: Colors.blue (defined in `main.dart`)
- Use Material Design components
- Text styles: Use built-in styles like `headline6`, `bodyText1`

## Gotchas

- Always check `mounted` before calling `setState` in async callbacks
- Use `WidgetsBinding.instance.addPostFrameCallback` for post-build actions
- Drawer items need proper Navigation with `Navigator.pop(context)` before pushing new routes
- Carousel widgets can be performance-intensive with many items
- Gesture detectors should handle both tap and drag appropriately
- Always provide feedback for swipe actions (snackbar, animation)

## UI Constants

- Carousel viewport fraction: 0.8
- Task item height: ~70% of screen
- Default padding: 16.0
- Border radius: 8.0
- Animation duration: 300ms
