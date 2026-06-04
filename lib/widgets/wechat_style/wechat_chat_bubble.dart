import 'package:flutter/material.dart';
import 'wechat_constants.dart';

/// 微信风格聊天气泡方向
enum BubbleDirection {
  /// 用户消息（右侧，绿色气泡）
  right,

  /// 对方消息（左侧，白色气泡）
  left,
}

/// 微信风格聊天气泡组件
/// 模仿微信的气泡样式：右侧绿色、左侧白色，带小三角尾巴
class WeChatChatBubble extends StatelessWidget {
  final Widget child;
  final BubbleDirection direction;
  final Color? bubbleColor;
  final Color? textColor;
  final EdgeInsets padding;
  final double maxWidthRatio;

  const WeChatChatBubble({
    super.key,
    required this.child,
    required this.direction,
    this.bubbleColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.maxWidthRatio = WeChatConstants.bubbleMaxWidthRatio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = bubbleColor ??
        (direction == BubbleDirection.right
            ? (isDark
                ? WeChatConstants.userBubbleBgDark
                : WeChatConstants.userBubbleBg)
            : (isDark
                ? WeChatConstants.otherBubbleBgDark
                : WeChatConstants.otherBubbleBg));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * maxWidthRatio,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 气泡主体
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(WeChatConstants.bubbleRadius),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: WeChatConstants.fontSizeMessage,
                color: textColor ??
                    (isDark ? Colors.white : const Color(0xFF181818)),
                height: 1.4,
              ),
              child: child,
            ),
          ),
          // 小三角尾巴
          Positioned(
            top: 12,
            left: direction == BubbleDirection.left ? -5 : null,
            right: direction == BubbleDirection.right ? -5 : null,
            child: ClipPath(
              clipper: _TriangleClipper(direction: direction),
              child: Container(
                width: 10,
                height: 14,
                color: bgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 气泡三角尾巴裁剪器
class _TriangleClipper extends CustomClipper<Path> {
  final BubbleDirection direction;

  _TriangleClipper({required this.direction});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (direction == BubbleDirection.left) {
      // 左侧气泡的尾巴（指向左）
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      // 右侧气泡的尾巴（指向右）
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 微信风格时间标签
/// 显示在消息上方，灰底白字
class WeChatTimeTag extends StatelessWidget {
  final String text;

  const WeChatTimeTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WeChatConstants.timeTagBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: WeChatConstants.fontSizeTimeTag,
          color: WeChatConstants.timeTagText,
        ),
      ),
    );
  }
}

/// 微信风格消息行（头像 + 气泡）
/// 左侧：头像 + 气泡（对方消息）
/// 右侧：气泡 + 头像（用户消息）
class WeChatMessageRow extends StatelessWidget {
  final Widget bubble;
  final String? avatarText;
  final Widget? avatarWidget;
  final BubbleDirection direction;
  final String? timeTag;
  final bool showAvatar;

  const WeChatMessageRow({
    super.key,
    required this.bubble,
    this.avatarText,
    this.avatarWidget,
    required this.direction,
    this.timeTag,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = avatarWidget ??
        CircleAvatar(
          radius: WeChatConstants.chatAvatarSize / 2,
          backgroundColor: direction == BubbleDirection.right
              ? WeChatConstants.primaryGreen
              : Colors.blueGrey,
          child: Text(
            avatarText ?? '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          if (timeTag != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WeChatTimeTag(text: timeTag!),
              ),
            ),
          // 消息行
          Row(
            mainAxisAlignment: direction == BubbleDirection.right
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧头像（对方消息）
              if (direction == BubbleDirection.left && showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: avatar,
                ),
              // 气泡
              Flexible(child: bubble),
              // 右侧头像（用户消息）
              if (direction == BubbleDirection.right && showAvatar)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: avatar,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
