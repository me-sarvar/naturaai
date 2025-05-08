import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naturaai/shared/providers/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return DropdownButton<Locale>(
      value: locale,
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          notifier.setLocale(newLocale);
        }
      },
      items: const [
        DropdownMenuItem(
          value: Locale('en'),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('ko'),
          child: Text('한국어'),
        ),
      ],
    );
  }
}
