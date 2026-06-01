part of '../settings_screen.dart';

const _kSettingsDivider = Border(
  bottom: BorderSide(color: Color(0xFF192036), width: 0.5),
);

// Gold uppercase section label.
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.0,
          ),
        ),
      );
}

// Rounded card container for a section's rows.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard(this.children);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2D4A)),
        ),
        child: Column(children: children),
      );
}

// Tappable row with chevron.
class _SettingsNavRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool isLast;
  final VoidCallback? onTap;

  const _SettingsNavRow({
    required this.title,
    this.subtitle,
    this.titleColor,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(border: isLast ? null : _kSettingsDivider),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppTheme.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppTheme.textSubtle),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSubtle.withValues(alpha: 0.5), size: 20),
          ]),
        ),
      );
}

// Row with a toggle switch.
class _SettingsToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    this.isLast = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(border: isLast ? null : _kSettingsDivider),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSubtle),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected)
                    ? Colors.white
                    : AppTheme.textSubtle),
            trackColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected)
                    ? AppTheme.accent
                    : const Color(0xFF1F2D4A)),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ]),
      );
}

// Static info row (no chevron, no tap).
class _SettingsInfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingsInfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: const BoxDecoration(border: _kSettingsDivider),
        child: Row(children: [
          Expanded(
              child: Text(
            title,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          )),
          Text(
            value,
            style:
                GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSubtle),
          ),
        ]),
      );
}
