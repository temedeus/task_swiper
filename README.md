# Task Swiper

Task Swiper is a simple task management app.

# Install Dependencies and Run a Flutter App

```
cd /path/to/task_swiper  
flutter pub get  
flutter run  
```

# How to Use the Recurrence Selector in TaskSwiper

The **Recurrence Selector** allows you to set up repeating tasks based on your preferences. Follow the steps below to configure recurrence for your tasks:

## 1. Choose a Recurrence Frequency
- Tap the dropdown menu labeled **"Repeat Task"**.
- Select one of the following options:
    - **Daily** – Task repeats every set number of days.
    - **Weekly** – Task repeats on selected days of the week.

## 2. Select Specific Days (Only for Weekly Recurrence)
- If you choose **Weekly**, a set of weekday buttons will appear.
- Tap the days when you want the task to repeat (e.g., **Mon, Wed, Fri**).
- Tap again to deselect a day.

## 3. Set the Interval
- Enter a number in the **"Repeat Every (days/weeks)"** field.
- This defines how often the task repeats. Examples:
    - Enter **1** for daily recurrence.
    - Enter **2** for every two weeks (if "Weekly" is selected).

## 4. Set a Reminder Time (Optional)
- Tap the **"Pick Time"** button.
- Choose the time when you want the task to occur.
- The selected time will be displayed.

## 5. Automatic Updates
- Any changes you make update the recurrence settings automatically.
- If you want to remove recurrence, unselect **Repeat Task**.

By following these steps, you can ensure your tasks repeat at the right times! 🚀

# Updating Translations

Task Swiper supports internationalization (i18n) with English and Finnish translations. Here's how to update or add translations:

## Translation Files Location

Translation files are located in `lib/l10n/`:
- `app_en.arb` - English translations
- `app_fi.arb` - Finnish translations

## Adding or Updating a Translation String

1. **Add the string to the English template file** (`app_en.arb`):
   ```json
   {
     "myNewString": "My new string",
     "@myNewString": {
       "description": "Description of what this string is for"
     }
   }
   ```

2. **Add the translation to Finnish** (`app_fi.arb`):
   ```json
   {
     "myNewString": "Minun uusi merkkijono"
   }
   ```

3. **For strings with parameters**, use placeholders:
   ```json
   {
     "greeting": "Hello, {name}!",
     "@greeting": {
       "description": "A greeting message",
       "placeholders": {
         "name": {
           "type": "String"
         }
       }
     }
   }
   ```

4. **Regenerate localization files**:
   ```bash
   flutter gen-l10n
   ```

5. **Use the translation in code**:
   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   
   // In your widget:
   final localizations = AppLocalizations.of(context)!;
   Text(localizations.myNewString)
   
   // With parameters:
   Text(localizations.greeting('John'))
   ```

## Adding a New Language

1. **Create a new ARB file** in `lib/l10n/`:
   - Format: `app_<language_code>.arb` (e.g., `app_de.arb` for German, `app_es.arb` for Spanish)

2. **Copy all keys from `app_en.arb`** and translate the values:
   ```json
   {
     "@@locale": "de",
     "appTitle": "Aufgaben Wischer",
     "taskLists": "Aufgabenlisten",
     // ... all other keys
   }
   ```

3. **Add the locale to `main.dart`**:
   ```dart
   supportedLocales: const [
     Locale('en'), // English
     Locale('fi'), // Finnish
     Locale('de'), // German (new language)
   ],
   ```

4. **Add the language option to the language selector** in `lib/ui/widgets/task_list_drawer.dart`:
   ```dart
   DropdownMenuItem(
     value: Locale('de'),
     child: Text('Deutsch'),
   ),
   ```

5. **Update `LanguageProvider`** if needed to support the new locale's default detection.

6. **Regenerate localization files**:
   ```bash
   flutter gen-l10n
   ```

## Important Notes

- Always update **both** English and Finnish files when adding new strings
- The `@` prefix in ARB files is for metadata (descriptions, placeholders)
- After modifying ARB files, always run `flutter gen-l10n` to regenerate the Dart code
- The generated files are in `.dart_tool/flutter_gen/gen_l10n/` (don't edit these directly)
- Use `AppLocalizations.of(context)!` to access translations in widgets
