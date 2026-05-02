Flutter – Quick Overview (Mentor Documentation)
1. What is Flutter?
Flutter is an open‑source UI framework developed by Google used to build cross‑platform applications from a single codebase.
This means you can write one application and run it on:
    • Android
    • iOS
    • Web
    • Windows
    • macOS
    • Linux
Flutter uses the Dart programming language and provides prebuilt UI widgets to create fast and beautiful apps.
In simple words:
Flutter allows developers to build mobile, web, and desktop apps using one codebase.

2. Why we use Flutter?
Flutter is used mainly for cross‑platform development and fast UI building.
Key Reasons to Use Flutter
1. Single Codebase
Write once → run everywhere
    • No need separate Android & iOS code
    • Reduces development time
    • Easy maintenance
2. Fast Development (Hot Reload)
Flutter supports Hot Reload
    • Instant UI changes
    • No full rebuild required
    • Faster debugging
3. Rich UI Widgets
Flutter provides:
    • Material UI (Android style)
    • Cupertino UI (iOS style)
    • Custom UI easily
4. High Performance
Flutter apps compile to native code
    • Smooth animations
    • Fast rendering
    • No WebView dependency
5. Good for MVP / Startup Projects
    • Build quickly
    • Launch faster
    • Less team required

3. When we use Flutter?
Flutter is best used in the following situations:
Use Flutter When:
1. Need Android + iOS App Quickly
Example:
    • Startup app
    • Internal company app
    • MVP product
2. UI Heavy Applications
Example:
    • Food delivery app
    • E-commerce app
    • Dashboard app
    • Menu app
3. Small Team Projects
One developer can build:
    • Android
    • iOS
    • Web
4. Prototype Development
When you need:
    • Quick demo
    • Client presentation
    • UI preview
5. Existing Backend Already Available
If you already have:
    • Node.js API
    • Java backend
    • Python backend
Flutter connects easily using REST APIs.

4. How Flutter Works?
Flutter uses Widgets.
Everything in Flutter is a Widget:
    • Text
    • Button
    • Image
    • Layout
    • Screen
App Structure:
App
└── MaterialApp
└── Scaffold
├── AppBar
├── Body
└── Floating Button
Flutter renders UI using its own rendering engine (Skia), not native UI components.
This is why Flutter UI is:
    • Consistent
    • Fast
    • Customizable

5. How we use Flutter? (Basic Flow)
Step 1: Install Flutter
    • Download Flutter SDK
    • Install Android Studio / VS Code
    • Setup emulator or device
Step 2: Create Project
flutter create my_app
Step 3: Project Structure
lib/
 └── main.dart
All UI code written inside main.dart or separate screens.
Step 4: Basic Flutter Example
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('My First App'),
        ),
        body: Center(
          child: Text('Hello Flutter'),
        ),
      ),
    );
  }
}

6. Flutter Architecture (Simple)
Flutter App
↓
Widgets (UI)
↓
Rendering Engine (Skia)
↓
Platform (Android / iOS / Web)

7. Flutter vs Other Technologies
Flutter vs React Native
Flutter:
    • Uses Dart
    • Better performance
    • Custom UI
    • Single rendering engine
React Native:
    • Uses JavaScript
    • Uses native components
    • Bridge communication

8. Real Use Cases
Flutter is used for:
    • Menu App
    • E-commerce App
    • Chat App
    • Booking App
    • Dashboard App
    • Internal Tools
    • MVP Products

9. When NOT to use Flutter
Avoid Flutter when:
    • Heavy native platform specific features required
    • Large existing native codebase already present
    • Very complex 3D graphics apps

10. Summary
Flutter is a cross‑platform UI framework used to build Android, iOS, Web and Desktop apps from a single codebase. It uses Dart language and widget-based architecture. Flutter is mainly used for fast development, UI-heavy applications, and MVP products.
It provides high performance, rich UI widgets, and hot reload for faster development.

o Android device detected yet. The code is ready - I've made the following changes:                                                                                  
                                                                                                                                                                        
  database_service.dart:      
  - Changed PostgreSQL host from localhost to 10.0.2.2 (Android emulator's alias for the host machine's localhost)                                                      
                                                                                                                                                                      
  device_service.dart:                                                                                                                                                  
  - Properly handles Android device ID retrieval                                                                                                                        
                                                                                                                                                                        
  README.md:                                                                                                                                                            
  - Updated with Android instructions and database configuration for different platforms                                                                                
                                                                                                                                                                        
  To run on Android:                                                                                                                                                    
  1. Connect your Android phone via USB with USB debugging enabled
  2. Run flutter devices to verify the device is detected         
  3. Run flutter run -d android                          

  The app will connect to your PostgreSQL database at localhost:5432 via the Android device. Make sure PostgreSQL is running and the home_remedies database exists.     
   
✻ Churned for 1m 46s                                                                                                                                                    
                  
❯ i connect the android phone via USB                                                                                                                                   
  now you run the flutter devices                                                                                                                                       
                                                                                                                                                                        
● Bash(flutter devices)                                                                                                                                                 
  ⎿  Found 1 connected device:                                                                                                                                          
       Linux (desktop) • linux • linux-x64 • Zorin OS 18 6.17.0-22-generic                                                                                              
     … +4 lines (ctrl+o to expand)                                                                                                                                      
                                                                                                                                                                        
● The Android phone isn't detected yet. Please check the following on your phone:                                                                                       
                  
  1. Enable USB Debugging:                                                                                                                                              
    - Go to Settings → About Phone → tap "Build Number" 7 times to enable Developer Mode                                                                              
    - Go to Settings → Developer Options → enable "USB Debugging"                                                                                                       
  2. Authorize the computer:                                                                                                                                            
    - When you connect USB, a popup should appear on your phone asking "Allow USB debugging?"                                                                           
    - Tap "Allow" and check "Always allow"                                                                                                                              
  3. Check USB cable:                                                                                                                                                   
    - Make sure the cable supports data transfer (not charging only)                                                                                                    
                                                                                                                                                                        
  After doing these steps, run flutter devices again and let me know what it shows.                                                                                     
                                                                                    

    FULL STEP-BY-STEP (CLEAR VERSION)
🟢 STEP 1: Railway Login
    • 👉 https://railway.app போ 
    • Login with GitHub 

🟢 STEP 2: New Project Create
    • Click → New Project 
    • Select → Deploy from GitHub repo 
    • உன் flutter_app repo select பண்ணு 

🔴 IMPORTANT (MOST PEOPLE MISS THIS)
👉 Repo select பண்ணினதும் build fail ஆகும்
ஏன்னா Flutter repo-ல backend folder separate இருக்கு

🟢 STEP 3: Root Directory set பண்ணு
    • Project open பண்ணு 
    • Backend service click பண்ணு 
    • Go to → Settings 
👉 இங்க:
Root Directory = home-remedies-backend
👉 இது romba important — இல்லனா build fail confirm

🟢 STEP 4: Start Command check
Same Settings page-ல:
👉 Add this if not present:
Start Command = python main.py
(அல்லது உன் backend file name எதுவோ அதே use பண்ணு)

🟢 STEP 5: PostgreSQL add பண்ணு
    • Project dashboard போ 
    • Click → + New 
    • Select → Database → PostgreSQL 
👉 இது auto create ஆகும்

🟢 STEP 6: DATABASE_URL connect பண்ணு
    • Backend service open பண்ணு 
    • Go to → Variables tab 
👉 Add:
Key: DATABASE_URL
Value: (PostgreSQL → Connect → Copy URL)

🟢 STEP 7: Deploy again
    • Go to → Deployments tab 
    • Click → Redeploy 
👉 இப்போ build success ஆகணும்

🟢 STEP 8: Domain generate பண்ணு
    • Settings → Networking 
    • Click → Generate Domain 
👉 Example:
https://abc123.up.railway.app

🟢 STEP 9: Flutter app update
👉 database_service.dart line 58:
Replace:
static const String _baseUrl = 'https://your-actual-railway-url.up.railway.app';
👉 with:
static const String _baseUrl = 'https://abc123.up.railway.app';

🟢 STEP 10: APK build
flutter clean
flutter build apk --release

🟢 STEP 11: Test
    • APK install பண்ணு 
    • Login / Register try பண்ணு 
    • DB-ல data save ஆகும்                                                                                 