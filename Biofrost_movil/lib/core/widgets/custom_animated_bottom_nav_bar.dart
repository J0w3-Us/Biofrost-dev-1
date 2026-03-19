import 'package:flutter/material.dart';

class AnimatedNavBarItem {
  const AnimatedNavBarItem({
    required this.icon,
    this.activeIcon,
    this.tooltip,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String? tooltip;
}

class CustomAnimatedBottomNavigationBar extends StatelessWidget {
  const CustomAnimatedBottomNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = const Color(0xFF121212),
    this.indicatorColor = const Color(0xFFFFFFFF),
    this.activeIconColor = const Color(0xFF121212),
    this.inactiveIconColor = const Color(0xFFB0B0B0),
    this.height = 76,
    this.indicatorDiameter = 54,
    this.iconSize = 24,
    this.popUpDistance = 12,
    this.animationDuration = const Duration(milliseconds: 620),
    this.animationCurve = Curves.easeOutCubic,
    this.indicatorTop,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  })  : assert(
          items.length >= 2,
          'CustomAnimatedBottomNavigationBar expects at least 2 items.',
        ),
        assert(currentIndex >= 0 && currentIndex < items.length);

  final List<AnimatedNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  final Color backgroundColor;
  final Color indicatorColor;
  final Color activeIconColor;
  final Color inactiveIconColor;

  final double height;
  final double indicatorDiameter;
  final double iconSize;
  final double popUpDistance;
  final double? indicatorTop;

  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final totalHeight = height + popUpDistance;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalTrack =
              constraints.maxWidth - padding.left - padding.right;
          final sectionWidth = horizontalTrack / items.length;
          final indicatorLeft = padding.left +
              (sectionWidth * currentIndex) +
              (sectionWidth - indicatorDiameter) / 2;
          final resolvedIndicatorTop = indicatorTop ??
              ((height - indicatorDiameter) / 2) - (popUpDistance * 0.5);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: animationDuration,
                curve: animationCurve,
                left: indicatorLeft,
                top: resolvedIndicatorTop,
                child: IgnorePointer(
                  child: Container(
                    width: indicatorDiameter,
                    height: indicatorDiameter,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(24),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: height,
                  child: Padding(
                    padding: padding,
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;

                        final iconWidget = AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          width: indicatorDiameter,
                          height: indicatorDiameter,
                          transform: Matrix4.translationValues(
                            0,
                            isSelected ? -popUpDistance : 0,
                            0,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isSelected
                                ? (item.activeIcon ?? item.icon)
                                : item.icon,
                            size: iconSize,
                            color: isSelected
                                ? activeIconColor
                                : inactiveIconColor,
                          ),
                        );

                        return Expanded(
                          child: Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(index),
                              child: item.tooltip == null
                                  ? iconWidget
                                  : Tooltip(
                                      message: item.tooltip!,
                                      child: iconWidget,
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
