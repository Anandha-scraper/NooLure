import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/birthdays/add_birthday_screen.dart';
import '../../screens/birthdays/birthday_screen.dart';
import '../../screens/birthdays/birthdays_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/notes/add_note_screen.dart';
import '../../screens/notes/notes_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/tasks/add_task_screen.dart';
import '../../screens/tasks/edit_task_screen.dart';
import '../../screens/tasks/task_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _page(const LoginScreen());
      case AppRoutes.home:
        return _page(const HomeScreen());
      case AppRoutes.tasks:
        return _page(const TaskScreen());
      case AppRoutes.taskDetail:
        return _page(EditTaskScreen(taskId: settings.arguments as String));
      case AppRoutes.addTask:
        return _page(const AddTaskScreen());
      case AppRoutes.notes:
        return _page(const NotesScreen());
      case AppRoutes.addNote:
        return _page(const AddNoteScreen());
      case AppRoutes.editNote:
        return _page(AddNoteScreen(noteId: settings.arguments as String));
      case AppRoutes.birthdays:
        return _page(const BirthdaysScreen());
      case AppRoutes.addBirthday:
        return _page(const AddBirthdayScreen());
      case AppRoutes.editBirthday:
        return _page(
          AddBirthdayScreen(birthdayId: settings.arguments as String),
        );
      case AppRoutes.birthdayDetail:
        return _page(BirthdayScreen(birthdayId: settings.arguments as String));
      case AppRoutes.profile:
        return _page(const ProfileScreen());
      case AppRoutes.editProfile:
        return _page(const EditProfileScreen());
      default:
        return _page(
          Scaffold(body: Center(child: Text('No route: ${settings.name}'))),
        );
    }
  }

  static MaterialPageRoute<void> _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}
