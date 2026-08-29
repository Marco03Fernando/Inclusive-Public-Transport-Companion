import 'package:flutter/material.dart';

import '../core/localization/locale.dart';
import '../core/theme/app_theme.dart';
import '../models/contact.dart';
import 'buttons.dart';
import 'labeled_text_field.dart';

/// Bottom sheet for adding/editing an emergency contact. Returns the new
/// [Contact] (preserving `initial.id` when editing) or null if cancelled.
/// `ContactCard`/`ContactPickerRow` are read-only, so this is the one place
/// a user actually types a contact's details.
Future<Contact?> showContactFormSheet(BuildContext context, {Contact? initial}) {
  return showModalBottomSheet<Contact?>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ContactFormSheet(initial: initial),
  );
}

class _ContactFormSheet extends StatefulWidget {
  const _ContactFormSheet({this.initial});

  final Contact? initial;

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _relation = TextEditingController(text: widget.initial?.relation);
  late final _phone = TextEditingController(text: widget.initial?.phone);

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      Contact(
        id: widget.initial?.id,
        name: _name.text.trim(),
        relation: _relation.text.trim(),
        phone: _phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? context.t('addContact') : context.t('editWord'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('contactNameLabel'), controller: _name),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('contactRelationLabel'), controller: _relation),
          const SizedBox(height: 14),
          LabeledTextField(label: context.t('phoneNumber'), controller: _phone),
          const SizedBox(height: 20),
          PrimaryButton(label: context.t('saveWord'), onPressed: _save),
        ],
      ),
    );
  }
}
