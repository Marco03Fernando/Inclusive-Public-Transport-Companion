import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/contact.dart';

/// A contact's name/phone plus Call/Text buttons that open the phone's own
/// dialer/SMS app pre-filled — the user taps to actually call/send. No
/// server involved, so this works with zero payment plan set up.
class SosContactRow extends StatelessWidget {
  const SosContactRow({super.key, required this.contact});

  final Contact contact;

  Future<void> _call() => launchUrl(Uri(scheme: 'tel', path: contact.phone));

  Future<void> _text() => launchUrl(
        Uri(scheme: 'sms', path: contact.phone, queryParameters: {'body': _distressMessage}),
      );

  static const _distressMessage =
      "I need help right now, this is an SOS alert from Colombo Pal. Please call me.";

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: palette.text)),
                Text(contact.phone, style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call, size: 20, color: palette.success),
            onPressed: _call,
          ),
          IconButton(
            icon: Icon(Icons.sms, size: 20, color: palette.accent),
            onPressed: _text,
          ),
        ],
      ),
    );
  }
}
