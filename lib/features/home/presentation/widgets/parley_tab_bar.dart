// FILE: features/home/presentation/widgets/parley_tab_bar.dart
// The bottom tab bar: a hairline on top, the selected tab in the accent colour with a short bar
// above it. No pill-shaped highlight, so it reads the same in light and dark mode. Labels stop
// growing past 1.3x text size so the bar never overflows at large accessibility sizes.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

/// One destination in the tab bar.
class TabDestination {
  const TabDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class ParleyTabBar extends StatelessWidget {
  const ParleyTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<TabDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _height = 62.0;
  static const _maxLabelScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A Material (not a plain DecoratedBox) so the InkWell splash paints above the background.
    return Material(
      color: colors.background,
      shape: Border(top: BorderSide(color: colors.line)),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxLabelScale,
          child: SizedBox(
            height: _height,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _TabButton(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: the accent marker, the icon and the label, announced as a selectable button.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const _markerWidth = 28.0;
  static const _markerHeight = 2.0;
  static const _iconSize = 24.0;
  static const _labelSize = 11.5;
  static const _animation = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: _animation,
              height: _markerHeight,
              width: selected ? _markerWidth : 0,
              color: colors.accent,
            ),
            const SizedBox(height: 8),
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: color,
              size: _iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _labelSize,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
