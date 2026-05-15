import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the pending invite ref extracted from a deep link before the user logs in.
/// HomeScreen listens to this and shows InviteWelcomeSheet when it becomes non-null.
/// Cleared (set to null) after the sheet is shown or if the user is already logged in.
final pendingInviteRefProvider = StateProvider<String?>((ref) => null);
