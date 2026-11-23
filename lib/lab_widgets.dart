import 'package:flutter/material.dart';

const background = Color(0xff121614);
const sidebar = Color(0xff171c19);
const surface = Color(0xff1b221e);
const raised = Color(0xff222b25);
const border = Color(0xff303c34);
const foreground = Color(0xffeef3ed);
const muted = Color(0xffa4b4a9);
const accent = Color(0xffb7ed90);
const darkAccent = Color(0xff24361f);

class LabPanel extends StatelessWidget {
  const LabPanel({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? surface,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.description, {super.key, this.action});

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: muted)),
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 12), action!],
    ],
  );
}

class TerminalIcon extends StatelessWidget {
  const TerminalIcon({super.key, this.size = 36, this.selected = false});

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: selected ? darkAccent : raised,
      borderRadius: BorderRadius.circular(size / 4),
    ),
    alignment: Alignment.center,
    child: Icon(
      Icons.point_of_sale_outlined,
      size: size * 0.56,
      color: selected ? accent : muted,
    ),
  );
}
