# NooLure

**Your days, organized beautifully.**

A personal productivity and life organizer built with Flutter. Manage your tasks, notes, birthdays, and calendar — all in one calm, beautifully designed app.


## Features

- **Tasks** — Create, edit, and track tasks with priorities (Low / Medium / High / Urgent), subtasks, categories, and repeat options.
- **Notes** — Write notes with tags, checklists, and the ability to pin important ones.
- **Birthdays** — Never forget a birthday. Track names, relationships, gift ideas, and set reminders.
- **Calendar** — View your events and schedule at a glance.
- **Home Dashboard** — See a daily greeting, your task progress ring, upcoming birthdays, and a motivational quote.
- **Authentication** — Google Sign-In flow (mocked locally, ready for real Firebase).
- **Theming** — Light, Dark, and System modes with two accent color options (Gold or Sage).

## Tech Stack

| Package | What it does |
|---|---|
| `provider` | State management across the app |
| `firebase_core` + `firebase_database` | Firebase Realtime Database for syncing data |
| `shared_preferences` | Persisting local settings (theme, session) |
| `google_fonts` | Figtree font family |
| `lucide_icons_flutter` | Clean, modern icon set |
| `percent_indicator` | Circular progress rings on the home screen |
| `intl` | Date formatting |

## Project Structure

```
lib/
├── main.dart                  # Entry point — initializes Firebase, runs the app
├── app.dart                   # Root widget, providers setup, auth gate
│
├── models/                    # Data classes
│   ├── user_model.dart        #   User (id, name, email, initials)
│   ├── task_model.dart        #   Task + Subtask with priority levels
│   ├── note_model.dart        #   Note with tags, checklists, pinning
│   ├── birthday_model.dart    #   Birthday with gift ideas & reminders
│   ├── calendar_model.dart    #   Calendar event
│   ├── goal_model.dart        #   Goal (placeholder)
│   └── password_model.dart    #   Password entry (placeholder)
│
├── providers/                 # State management (ChangeNotifier + Provider)
│   ├── auth_provider.dart     #   Sign in/out, session restore
│   ├── task_provider.dart     #   Task CRUD + filtering
│   ├── note_provider.dart     #   Note CRUD
│   ├── birthday_provider.dart #   Birthday CRUD
│   ├── calendar_provider.dart #   Calendar state
│   ├── goal_provider.dart     #   Goal state (placeholder)
│   └── theme_provider.dart    #   Light/Dark/System mode, accent color
│
├── screens/                   # UI organized by feature
│   ├── auth/                  #   Login, splash, setting-up screens
│   ├── home/                  #   Home dashboard + drawer menu
│   ├── tasks/                 #   Task list, add, edit
│   ├── notes/                 #   Note list, add, edit
│   ├── birthdays/             #   Birthday list + detail view
│   ├── calendar/              #   Calendar view
│   ├── goals/                 #   Goal screens (placeholder)
│   ├── passwords/             #   Password screens (placeholder)
│   └── profile/               #   Profile + settings + edit profile
│
├── widgets/                   # Reusable UI components
│   ├── app_drawer.dart        #   Side navigation drawer
│   ├── avatar_circle.dart     #   Initials-based avatar
│   ├── card_container.dart    #   Styled card wrapper
│   ├── custom_button.dart     #   Primary/secondary buttons
│   ├── custom_textfield.dart  #   Styled text input
│   ├── goal_tile.dart         #   Goal list item
│   ├── loading_widget.dart    #   Loading spinner / progress ring
│   ├── note_tile.dart         #   Note list item
│   ├── password_tile.dart     #   Password list item
│   ├── segmented_control.dart #   Tab-like segmented selector
│   ├── tag_chip.dart          #   Tag pill/chip
│   └── task_tile.dart         #   Task list item
│
└── core/                      # Backend plumbing
    ├── database_service.dart  #   Firebase Realtime DB read/write
    ├── routes/
    │   ├── app_routes.dart    #   Route name constants
    │   └── route_generator.dart # Named-route switch generator
    ├── services/
    │   ├── auth_service.dart  #   Auth backend (mocked Google Sign-In)
    │   └── firebase_service.dart # Firebase helpers
    ├── theme/
    │   ├── app_theme.dart     #   Full ThemeData (light + dark)
    │   └── text_styles.dart   #   Heading / body text styles
    ├── constants/
    │   ├── app_colors.dart    #   "Cabin" color palette + shadow helpers
    │   ├── app_strings.dart   #   App name, tagline, legal copy
    │   └── firebase_constants.dart # Firebase path keys
    └── utils/
        ├── dialogs.dart       #   Alert / confirm dialogs
        ├── helpers.dart       #   Miscellaneous utilities
        └── validators.dart    #   Form field validation
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.12.2)
- Android Studio / Xcode / VS Code with Flutter plugin

### Run the app

```bash
git clone <repo-url>
cd NooLure
flutter pub get
flutter run
```

> **Note:** The app currently uses a **mock auth backend** — you can sign in immediately without any Firebase config. It returns a fake user ("Maya Kapoor") so you can explore the full app locally.

### Firebase Setup (for production)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Run `flutterfire configure` in the project root
3. Uncomment the `firebase_options.dart` import and `Firebase.initializeApp(...)` call in `lib/main.dart`
4. Set up Firebase Realtime Database rules for your use case

## License

<!-- Add your license here -->
