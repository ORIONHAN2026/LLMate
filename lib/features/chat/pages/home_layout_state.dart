class HomeLayoutState {
  static const double defaultSidebarWidth = 200.0;
  static const double minSidebarWidth = 150.0;
  static const double maxSidebarWidth = 400.0;
  static const double minChatAreaWidth = 700.0;

  bool isSidebarCollapsed = false;
  bool isRightSidebarCollapsed = false;
  bool isResizeHandleHovered = false;
  double sidebarWidth = defaultSidebarWidth;

  void toggleSidebar() {
    isSidebarCollapsed = !isSidebarCollapsed;
  }

  void expandSidebar() {
    isSidebarCollapsed = false;
  }

  void toggleRightSidebar() {
    isRightSidebarCollapsed = !isRightSidebarCollapsed;
  }

  void setResizeHandleHovered(bool value) {
    isResizeHandleHovered = value;
  }

  void resizeSidebar({required double delta, required double screenWidth}) {
    final proposedWidth = (sidebarWidth + delta).clamp(
      minSidebarWidth,
      maxSidebarWidth,
    );
    final availableChatWidth = screenWidth - proposedWidth;

    sidebarWidth =
        availableChatWidth < minChatAreaWidth
            ? (screenWidth - minChatAreaWidth).clamp(
              defaultSidebarWidth,
              maxSidebarWidth,
            )
            : proposedWidth;
  }
}
