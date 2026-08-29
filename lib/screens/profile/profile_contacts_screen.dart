import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale.dart';
import '../../core/routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contact.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/contact_form_sheet.dart';
import '../../widgets/dotted_add_button.dart';

class ProfileContactsScreen extends StatefulWidget {
  const ProfileContactsScreen({super.key});

  @override
  State<ProfileContactsScreen> createState() => _ProfileContactsScreenState();
}

class _ProfileContactsScreenState extends State<ProfileContactsScreen> {
  final _service = UserProfileService();

  Future<void> _add(String uid) async {
    final contact = await showContactFormSheet(context);
    if (contact != null) await _service.addContact(uid, contact);
  }

  Future<void> _edit(String uid, Contact contact) async {
    final edited = await showContactFormSheet(context, initial: contact);
    if (edited != null) await _service.updateContact(uid, edited);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final uid = context.watch<AuthState>().uid;
    return AppScaffold(
      routeName: Routes.profileContacts,
      title: context.t('emergencyContactsTitle'),
      onBack: () => Navigator.of(context).pushReplacementNamed(Routes.profileHome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.t('emergencyContactsNote'), style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 12),
          if (uid == null)
            const SizedBox.shrink()
          else
            StreamBuilder<List<Contact>>(
              stream: _service.watchContacts(uid),
              builder: (context, snapshot) {
                final contacts = snapshot.data ?? const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final contact in contacts) ...[
                      ContactCard(
                        contact: contact,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _edit(uid, contact),
                              child: Text(
                                context.t('editWord'),
                                style: TextStyle(fontSize: 12, color: palette.accent, fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: palette.muted),
                              onPressed: () => _service.deleteContact(uid, contact.id!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    DottedAddButton(label: context.t('addContact'), onTap: () => _add(uid)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
