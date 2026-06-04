import 'package:flutter/material.dart';
import 'wechat_constants.dart';

/// 微信风格会话数据模型
class WeChatSession {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String? avatarText;
  final Widget? avatarWidget;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  const WeChatSession({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.avatarText,
    this.avatarWidget,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
  });
}

/// 微信风格会话列表项
class WeChatSessionItem extends StatelessWidget {
  final WeChatSession session;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WeChatSessionItem({
    super.key,
    required this.session,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: WeChatConstants.sessionItemHeight,
      color: isSelected
          ? (isDark
              ? const Color(0xFF2A2A2A)
              : WeChatConstants.sessionItemHover)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 头像
              Stack(
                children: [
                  session.avatarWidget ??
                      CircleAvatar(
                        radius: WeChatConstants.avatarSize / 2,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          session.avatarText ?? session.name.isNotEmpty
                              ? session.name[0]
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  // 未读红点
                  if (session.unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: WeChatConstants.unreadBadge,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          session.unreadCount > 99
                              ? '99+'
                              : '${session.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  // 免打扰图标
                  if (session.isMuted)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_off,
                          size: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // 内容区域
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上排：名称 + 时间
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style: TextStyle(
                              fontSize: WeChatConstants.fontSizeSessionName,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF181818),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session.time,
                          style: TextStyle(
                            fontSize: WeChatConstants.fontSizeSessionTime,
                            color: WeChatConstants.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 下排：最后消息
                    Row(
                      children: [
                        if (session.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 12,
                              color: WeChatConstants.secondaryText,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            session.lastMessage,
                            style: TextStyle(
                              fontSize: WeChatConstants.fontSizeSessionLastMsg,
                              color: WeChatConstants.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 微信风格搜索栏
class WeChatSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const WeChatSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: WeChatConstants.searchBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.search,
                size: 18,
                color: WeChatConstants.secondaryText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: controller != null
                    ? TextField(
                        controller: controller,
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          hintText: '搜索',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: WeChatConstants.secondaryText,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF181818),
                        ),
                      )
                    : const Text(
                        '搜索',
                        style: TextStyle(
                          fontSize: 14,
                          color: WeChatConstants.secondaryText,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 微信风格会话列表（完整组件）
class WeChatSessionListView extends StatelessWidget {
  final List<WeChatSession> sessions;
  final String? selectedSessionId;
  final ValueChanged<WeChatSession>? onSessionTap;
  final ValueChanged<WeChatSession>? onSessionLongPress;

  const WeChatSessionListView({
    super.key,
    required this.sessions,
    this.selectedSessionId,
    this.onSessionTap,
    this.onSessionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        WeChatSearchBar(),
        // 分割线
        const Divider(height: 0.5),
        // 列表
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 0.5,
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return WeChatSessionItem(
                session: session,
                isSelected: session.id == selectedSessionId,
                onTap: () => onSessionTap?.call(session),
                onLongPress: () => onSessionLongPress?.call(session),
              );
            },
          ),
        ),
      ],
    );
  }
}
