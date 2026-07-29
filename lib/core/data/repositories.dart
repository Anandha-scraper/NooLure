import '../../models/birthday_model.dart';
import '../../models/note_model.dart';
import '../../models/password_model.dart';
import '../../models/password_vault_model.dart';
import '../../models/task_model.dart';
import 'local_store.dart';
import 'repository.dart';

/// The collections, wired once. Providers hold these; nothing else talks to
/// Hive or Firebase directly.
class Repositories {
  Repositories._();

  static final Repository<TaskModel> tasks = Repository(
    collection: LocalStore.tasks,
    fromJson: TaskModel.fromJson,
    toJson: (t) => t.toJson(),
    idOf: (t) => t.id,
  );

  static final Repository<NoteModel> notes = Repository(
    collection: LocalStore.notes,
    fromJson: NoteModel.fromJson,
    toJson: (n) => n.toJson(),
    idOf: (n) => n.id,
  );

  static final Repository<BirthdayModel> birthdays = Repository(
    collection: LocalStore.birthdays,
    fromJson: BirthdayModel.fromJson,
    toJson: (b) => b.toJson(),
    idOf: (b) => b.id,
  );

  static final Repository<PasswordModel> passwords = Repository(
    collection: LocalStore.passwords,
    fromJson: PasswordModel.fromJson,
    toJson: (p) => p.toJson(),
    idOf: (p) => p.id,
  );

  static final Repository<PasswordVaultModel> passwordVault = Repository(
    collection: LocalStore.passwordVault,
    fromJson: PasswordVaultModel.fromJson,
    toJson: (v) => v.toJson(),
    idOf: (v) => v.id,
  );

  /// Touch every repository so each one registers itself with the sync
  /// service before a user signs in.
  static void init() {
    tasks;
    notes;
    birthdays;
    passwords;
    passwordVault;
  }
}
