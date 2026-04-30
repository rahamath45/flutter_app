# Home Remedies App

A Flutter application for recording and managing home remedies for everyday health issues.

## Features

- Auto-login using device ID
- User registration with name, age, gender, location, and contact
- Audio recording for remedy capture (up to 15 minutes)
- PostgreSQL database for data persistence

## Dependencies

The following packages are required (defined in `pubspec.yaml`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  postgres: ^3.4.0
  device_info_plus: ^11.0.0
  logging: ^1.3.0
```

## Prerequisites

1. **Flutter SDK** (3.41.8 or compatible)
2. **PostgreSQL Database**

### Database Setup

Create the PostgreSQL database:

```bash
sudo -u postgres psql -c "CREATE DATABASE home_remedies;"
```

### Enable Flutter Web

```bash
flutter config --enable-web
```

## Running on Android

The app connects to PostgreSQL using `10.0.2.2:5432` (Android emulator's alias for localhost).

**Connect your Android phone and run:**

```bash
cd my_first_app
flutter run -d android
```

Or build an APK:

```bash
flutter build apk --debug
```

## Running on Web

```bash
cd my_first_app
flutter run -d web-server --web-port=8080
```

Then open `http://localhost:8080` in your browser.

## Running on Linux Desktop

```bash
cd my_first_app
flutter run -d linux
```

## Project Structure

```
my_first_app/
├── lib/
│   ├── main.dart           # Main app with splash, login, and recording screens
│   ├── database_service.dart   # PostgreSQL database operations
│   └── device_service.dart     # Device ID retrieval for auto-login
├── pubspec.yaml            # Dependencies and project configuration
└── README.md               # This file
```

## App Flow

1. **Splash Screen** - App checks for existing user via device ID
2. **Login Page** - New users register with their details
3. **Recording Page** - Record home remedy audio (max 15 minutes)

## Database Configuration

| Platform | Host | Port | Reason |
|----------|------|------|--------|
| Android Emulator | `10.0.2.2` | `5433` | Alias for host machine's localhost |
| Android Device (USB) | `localhost` or actual IP | `5433` | Direct connection |
| Web | N/A | N/A | Database not available (stub mode) |
| Linux Desktop | `localhost` | `5433` | Direct connection |

**Default credentials:** Username: `postgres`, Password: `password`, Database: `home_remedies`

## Development

### Hot Reload Commands (while running)

- `h` - List all available commands
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit the application

### Build for Production

**Web:**
```bash
flutter build web
```

**Android APK:**
```bash
flutter build apk --release
```

### adk
/home/nisha/flutter_app/my_first_app/build/app/outputs/flutter-apk/app-debug.apk

build/app/outputs/flutter-apk/app-debug.apk
---------------------------------------------------------------------------------------------------
Flutter Web Run – Error Walkthrough
Step 1 — Tried to run Flutter in Chrome

Command used:

flutter run -d chrome

Error:

No pubspec.yaml file found.
This command should be run from the root of your Flutter project.

Reason:

Command executed outside Flutter project folder
pubspec.yaml not found

Fix:

cd my_first_app
flutter run -d chrome
Step 2 — Chrome device not found

Command:

flutter run -d chrome

Error:

No supported devices found with name or id matching 'chrome'

Available device:

Linux (desktop)

Reason:

Flutter Web not enabled
Chrome browser not installed
Step 3 — Enabled Flutter Web

Command:

flutter config --enable-web

Output:

Setting "enable-web" value to "true"

This enables Flutter Web support.

Step 4 — Still Chrome not available

Command:

flutter run -d chrome

Error:

No supported devices found with name or id matching 'chrome'

Reason:

Chrome not installed in Linux system
Step 5 — Tried installing Chrome

Command:

sudo apt-get install chromium

Error:

sudo: a password is required

Reason:

No sudo permission
Cannot install Chrome
Step 6 — Alternative: Web Server Mode

Used command:

flutter run -d web-server --web-port=8080

This runs Flutter in web server mode.

Output:

Flutter app running at:
http://localhost:8080
Final Result

App successfully running using:

http://localhost:8080

This is:

Flutter Web mode
No Chrome dependency
Works in any browser
Final Working Command
flutter run -d web-server --web-port=8080

Open in browser:

http://localhost:8080
Conclusion
Chrome not installed → cannot use -d chrome
Used web-server mode instead
App successfully runs in browser
No Linux desktop or Android used


Perfect! I've fixed the issue. The problem was that your Flutter app on the real Android phone was trying to connect to 'localhost' (the phone's localhost), but PostgreSQL is running on your computer.

