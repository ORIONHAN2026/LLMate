/// 微信风格常量定义
/// 所有颜色、尺寸、间距等统一管理
class WeChatConstants {
  WeChatConstants._();

  // ========== 颜色 ==========

  /// 微信主题绿
  static const Color primaryGreen = Color(0xFF07C160);

  /// 微信主题绿（深色）
  static const Color primaryGreenDark = Color(0xFF06AD56);

  /// 导航栏背景色
  static const Color appBarBg = Color(0xFFEDEDED);

  /// 导航栏文字色
  static const Color appBarText = Color(0xFF181818);

  /// 聊天背景色 - 经典的微信聊天灰
  static const Color chatBg = Color(0xFFF5F5F5);

  /// 聊天背景色（深色模式）
  static const Color chatBgDark = Color(0xFF111111);

  /// 用户消息气泡背景 - 绿色
  static const Color userBubbleBg = Color(0xFF95EC69);

  /// 用户消息气泡背景（深色）
  static const Color userBubbleBgDark = Color(0xFF3E9B3E);

  /// AI/对方消息气泡背景 - 白色
  static const Color otherBubbleBg = Colors.white;

  /// AI/对方消息气泡背景（深色）
  static const Color otherBubbleBgDark = Color(0xFF1E1E1E);

  /// 时间标签背景
  static const Color timeTagBg = Color(0xFFD6D6D6);

  /// 时间标签文字
  static const Color timeTagText = Colors.white;

  /// 未读消息红点
  static const Color unreadBadge = Color(0xFFFA5151);

  /// 分割线颜色
  static const Color dividerColor = Color(0xFFE6E6E6);

  /// 搜索框背景
  static const Color searchBg = Color(0xFFEDEDED);

  /// 会话列表项背景（选中/悬停）
  static const Color sessionItemHover = Color(0xFFE8E8E8);

  /// 副标题灰色文字
  static const Color secondaryText = Color(0xFF999999);

  // ========== 尺寸 ==========

  /// 导航栏高度
  static const double appBarHeight = 56.0;

  /// 会话列表头像大小
  static const double avatarSize = 48.0;

  /// 会话列表项高度
  static const double sessionItemHeight = 72.0;

  /// 消息气泡圆角
  static const double bubbleRadius = 8.0;

  /// 消息气泡最大宽度比例（相对于屏幕宽度）
  static const double bubbleMaxWidthRatio = 0.7;

  /// 消息气泡之间的间距
  static const double messageSpacing = 16.0;

  /// 头像大小（聊天界面）
  static const double chatAvatarSize = 40.0;

  /// 输入框圆角
  static const double inputRadius = 6.0;

  /// 输入框高度
  static const double inputHeight = 40.0;

  // ========== 字体大小 ==========

  /// 导航栏标题
  static const double fontSizeTitle = 17.0;

  /// 会话列表名称
  static const double fontSizeSessionName = 16.0;

  /// 会话列表最后消息
  static const double fontSizeSessionLastMsg = 13.0;

  /// 会话列表时间
  static const double fontSizeSessionTime = 11.0;

  /// 消息内容
  static const double fontSizeMessage = 15.0;

  /// 消息时间标签
  static const double fontSizeTimeTag = 12.0;

  /// 提示文字
  static const double fontSizeHint = 14.0;

  // ========== 动画时长 ==========

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
}
