import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/core/routes.dart';
import 'package:colombo_pal/core/state/app_state.dart';
import 'package:colombo_pal/data/mock_data.dart';
import 'package:colombo_pal/models/user_profile.dart';

// Condition Reporting tests live in test/condition_report_tests/.
void main() {
  group('users/{uid}.role', () {
    test('maps every stored value onto AppRole', () {
      expect(AppRole.fromName('admin'), AppRole.admin);
      expect(AppRole.fromName('volunteer'), AppRole.volunteer);
      expect(AppRole.fromName('passenger'), AppRole.passenger);
    });

    test('legacy "user", missing and mistyped roles are never admin', () {
      for (final value in ['user', null, 'Admin', 'admin ', 42]) {
        expect(AppRole.fromName(value), AppRole.passenger, reason: '$value');
      }
    });

    test('profile round-trips the role through Firestore', () {
      final profile = UserProfile.fromMap('uid1', {
        'role': 'admin',
        'name': 'A',
        'email': 'a@b.c',
      }, defaultAccessNeeds);
      expect(profile.isAdmin, isTrue);
      expect(profile.email, 'a@b.c');

      final volunteer = UserProfile.fromMap('uid2', {
        'role': 'volunteer',
      }, defaultAccessNeeds);
      expect(volunteer.toMap()['role'], 'volunteer');
      expect(volunteer.isAdmin, isFalse);
    });
  });

  group('role routing', () {
    test('each role lands on its own home', () {
      expect(Routes.homeFor(AppRole.passenger), Routes.home);
      expect(Routes.homeFor(AppRole.volunteer), Routes.volunteerHome);
      expect(Routes.homeFor(AppRole.admin), Routes.admin);
    });

    test('admin dashboard has no passenger chrome', () {
      expect(Routes.showsBottomNav(Routes.admin), isFalse);
      expect(Routes.showsSos(Routes.admin, AppRole.admin), isFalse);
    });
  });
}
