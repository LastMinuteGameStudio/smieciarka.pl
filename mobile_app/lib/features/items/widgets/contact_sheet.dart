import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a dismissable bottom sheet with the owner's phone number.
Future<void> showContactSheet(BuildContext context, String phoneNumber) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: ColorPalette.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ContactSheet(phoneNumber: phoneNumber),
  );
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({required this.phoneNumber});

  final String phoneNumber;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  bool _copied = false;

  String get _dialableNumber => widget.phoneNumber.replaceAll(' ', '');

  /// Opens the device's phone app with the number already entered.
  Future<void> _openDialer() {
    return launchUrl(
      Uri(scheme: 'tel', path: _dialableNumber),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copyPhoneNumber() async {
    await Clipboard.setData(ClipboardData(text: _dialableNumber));
    if (mounted) {
      setState(() => _copied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kontakt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: ColorPalette.titleColor,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openDialer,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  top: 8,
                  bottom: 8,
                  right: 8,
                ),
                decoration: BoxDecoration(
                  color: ColorPalette.yelowishWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.mainColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: ColorPalette.mainColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.phoneNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kopiuj numer',
                      visualDensity: VisualDensity.compact,
                      onPressed: _copyPhoneNumber,
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 20,
                        color: ColorPalette.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _copied ? 'Numer skopiowany' : 'Dotknij numer, aby zadzwonić',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorPalette.descColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
