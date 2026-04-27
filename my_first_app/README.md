# My Notes App - Flutter

A simple and beautiful notes application built with Flutter.

## What Was Built

A **Notes App** with the following features:
- Create, edit, and delete notes
- 6 color options for note cards
- Search notes by title or content
- Relative timestamps ("Just now", "5m ago", etc.)
- Material Design 3 styling
- Responsive grid layout

## Flutter SDK Installation

Since Flutter was not pre-installed, I downloaded and set it up manually:

```bash
# Clone Flutter SDK (stable branch)
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk

# Add to PATH (add this to your ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/flutter_app/flutter_sdk/bin"
```

### Initial Setup Commands

```bash
# Verify Flutter installation
flutter --version

# Enable Linux desktop (if you want to build for Linux)
flutter config --enable-linux-desktop

# Check Flutter doctor
flutter doctor
```

## Project Creation

```bash
# Create new project
flutter create --org com.learner --project-name my_first_app --platforms linux,web my_first_app

# Add web platform (if already created)
flutter create . --platforms=web

# Get dependencies
flutter pub get
```

## Building the App

### Web Build (what we used)
```bash
# Build for web
flutter build web

# Serve locally
cd build/web
python3 -m http.server 8080
# Or use Flutter's dev server
flutter run -d web-server --web-port 8081
```

### Linux Desktop Build
For Linux, you would need:
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
flutter build linux
```

## Project Structure

```
my_first_app/
├── lib/
│   └── main.dart          # Main application code
├── web/
│   └── index.html         # Web entry point
├── build/
│   └── web/               # Built web assets
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

## Code Explanation

### main.dart Structure

#### 1. Note Data Model
```dart
class Note {
  String title;
  String content;
  DateTime date;
  Color color;
}
```
A simple class to store note data: title, content, creation date, and color.

#### 2. NotesHomePage (Main Screen)
The main screen with:
- **AppBar**: Title "My Notes" with Material 3 styling
- **Search Bar**: Filters notes in real-time
- **Grid View**: Displays notes as cards (2 columns)
- **FAB**: "New Note" button to create notes

Key state variables:
- `_notes`: List of all notes
- `_searchQuery`: Current search text

#### 3. _NoteCard Widget
Displays individual note as a card:
- Title (bold, single line with ellipsis)
- Content preview (5 lines max)
- Relative timestamp
- Delete button

#### 4. _NoteEditorSheet (Bottom Sheet)
Modal for creating/editing notes:
- Title input field
- Content text area
- Color picker (6 color options)
- Save/Cancel buttons

### Key Flutter Concepts Used

1. **StatefulWidget**: `NotesHomePage` manages state (notes list, search)
2. **setState()**: Updates UI when data changes
3. **List/Grid layouts**: Column, GridView.builder
4. **Modal bottom sheets**: For note editor
5. **Material Design 3**: ColorScheme.fromSeed, useMaterial3: true
6. **Theming**: App-wide consistent styling

### Main Functions

```dart
void main() {
  runApp(const MyApp());  // Entry point
}
```

```dart
// Filter notes based on search
List<Note> get _filteredNotes {
  if (_searchQuery.isEmpty) return _notes;
  return _notes.where((note) {
    return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
           note.content.toLowerCase().contains(_searchQuery.toLowerCase());
  }).toList();
}
```

```dart
// Format date as relative time
String _formatDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  // ... etc
}
```

## Dependencies

None! This app uses only Flutter's built-in packages:

- `flutter/material.dart` - Material Design widgets

## Running the App

```bash
# Start Flutter web server
cd my_first_app
flutter run -d web-server --web-port 8081

# OR serve built files
cd my_first_app/build/web
python3 -m http.server 8080
```

Then open http://localhost:8081 (or 8080) in your browser.

## Challenges Encountered

1. **No sudo access**: Couldn't install Linux desktop build tools (cmake, clang, etc.)
2. **Solution**: Built for web instead, which works without additional dependencies

3. **pkg-config not found**: Needed for GTK on Linux desktop builds
4. **Solution**: Downloaded and built pkg-config manually from source

## What I Learned

- Flutter SDK can be installed by cloning from git
- Web builds work out of the box without extra dependencies
- Python's http.server is useful for quickly serving static files
- Material 3 theming with `ColorScheme.fromSeed()` makes beautiful UIs easy

## Future Improvements

With proper Linux toolchain installed:
- Persist notes to local storage or SQLite
- Add categories/labels
- Pin important notes
- Add dark mode support
- Export notes as text/PDF