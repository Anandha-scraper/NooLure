import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';

enum CardElevation { none, sm, md, lg }

/// Rounded surface-filled container — `.card` in the design system.
class CardContainer extends StatelessWidget {
  const CardContainer({
    super.key,
    required this.child,
    this.elevation = CardElevation.none,
    this.padding = const EdgeInsets.all(13),
    this.color,
    this.margin,
  });

  final Widget child;
  final CardElevation elevation;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    List<BoxShadow>? shadow;
    switch (elevation) {
      case CardElevation.none:
        shadow = null;
      case CardElevation.sm:
        shadow = AppColors.shadowSm(brightness);
      case CardElevation.md:
        shadow = AppColors.shadowMd(brightness);
      case CardElevation.lg:
        shadow = AppColors.shadowLg(brightness);
    }
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Small uppercase accent-colored label — `.card-kicker`.
class CardKicker extends StatelessWidget {
  const CardKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: TextStyles.cardKicker(context));
  }
}

/// Heading-font card title — `.card-title`.
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyles.cardTitle(context));
  }
}

/// Muted body copy inside a card — `.card-body`.
class CardBody extends StatelessWidget {
  const CardBody(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyles.cardBody(context));
  }
}

/// Small meta line, optionally with a leading icon — `.card-meta`.
class CardMeta extends StatelessWidget {
  const CardMeta(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextStyles.cardMeta(context);
    if (icon == null) return Text(text, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: style.color),
        const SizedBox(width: 6),
        Text(text, style: style),
      ],
    );
  }
}
