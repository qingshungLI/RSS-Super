import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Color>? gradientColors;
  final double height;
  final bool centerTitle; // 新增

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.gradientColors,
    this.height = kToolbarHeight,
    this.centerTitle = true, // 新增
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = gradientColors ??
        (isDark
            ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
            : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 左侧返回/leading，占位固定宽度，防止挤偏标题
                if (automaticallyImplyLeading && leading == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 48,
                      height: height,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  )
                else if (leading != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 48,
                      height: height,
                      child: leading,
                    ),
                  ),

                // 标题（可选是否居中）
                Align(
                  alignment:
                      centerTitle ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 右侧 actions
                if (actions != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
