import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../models/contact.dart';

/// Emergency-contact card. [trailing] carries the screen-specific bit:
/// a "Contact 1" relation pill during sign-up, or an "Edit" link in the
/// profile's contacts list.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact, this.heading, this.trailing});

  final Contact contact;
  final String? heading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                heading ?? contact.name,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: palette.text),
              ),
              ?trailing,
            ],
          ),
          if (heading != null) ...[
            const SizedBox(height: 8),
            Text(contact.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: palette.text)),
          ],
          SizedBox(height: heading != null ? 4 : 6),
          Text(contact.phone, style: TextStyle(fontSize: 13, color: palette.muted)),
        ],
      ),
    );
  }
}

/// The tappable contact row used on the Share Journey picker screen.
class ContactPickerRow extends StatelessWidget {
  const ContactPickerRow({
    super.key,
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: palette.cta, width: 1.5) : null,
          boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: Text(
                contact.initial,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: palette.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.text)),
                  Text('${contact.relation} · ${contact.phone}', style: TextStyle(fontSize: 12, color: palette.muted)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? palette.cta : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? palette.cta : palette.border, width: 1.5),
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}
