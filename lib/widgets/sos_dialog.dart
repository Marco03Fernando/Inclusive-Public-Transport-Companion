import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/locale.dart';
import '../core/state/app_state.dart';
import '../core/state/auth_state.dart';
import '../core/theme/app_theme.dart';
import '../models/contact.dart';
import '../services/user_profile_service.dart';
import 'sos_contact_row.dart';

/// The SOS confirm -> press-and-hold -> activated modal, reachable from
/// every eligible passenger screen. Mirrors the design's 3-second hold
/// timer and countdown ring.
Future<void> showSosDialog(BuildContext context) {
  final appState = context.read<AppState>();
  appState.openSosConfirm();
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const SosDialog(),
  ).then((_) => appState.closeSos());
}

class SosDialog extends StatelessWidget {
  const SosDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.sosStage == SosStage.hidden) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        return Dialog(
          insetPadding: const EdgeInsets.all(28),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: state.sosStage == SosStage.activated
                ? const _SosActivated()
                : const _SosHold(),
          ),
        );
      },
    );
  }
}

class _SosHold extends StatelessWidget {
  const _SosHold();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t('sosHoldTitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 17, color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('sosHoldNote'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _RingPainter(
                    progress: state.holdPct / 100,
                    track: palette.border,
                    fill: palette.danger,
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => state.startHold(),
                  onTapUp: (_) => state.cancelHold(),
                  onTapCancel: () => state.cancelHold(),
                  child: Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: palette.danger, shape: BoxShape.circle),
                    child: Text(
                      'SOS',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(context.t('cancel'), style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SosActivated extends StatefulWidget {
  const _SosActivated();

  @override
  State<_SosActivated> createState() => _SosActivatedState();
}

class _SosActivatedState extends State<_SosActivated> {
  final _service = UserProfileService();
  late final Future<List<Contact>> _contactsFuture = _loadContacts();

  Future<List<Contact>> _loadContacts() {
    final uid = context.read<AuthState>().uid;
    if (uid == null) return Future.value(const []);
    return _service.watchContacts(uid).first;
  }

  // Sri Lanka's Suwa Seriya free ambulance service.
  static const _ambulanceNumber = '1990';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.dangerSoft, shape: BoxShape.circle),
            child: Text('!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: palette.danger)),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('helpOnWay'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 17, color: palette.text),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('helpOnWayNote'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted, height: 1.5),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Contact>>(
            future: _contactsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final contacts = snapshot.data ?? const [];
              if (contacts.isEmpty) {
                return Text(
                  context.t('noContactsSaved'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                );
              }
              return Column(children: [for (final c in contacts) SosContactRow(contact: c)]);
            },
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: _ambulanceNumber)),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(context.t('callAmbulance'), style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.text,
                side: BorderSide(color: palette.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(context.t('imSafe'), style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.fill});

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final fillPaint = Paint()
      ..color = fill
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
