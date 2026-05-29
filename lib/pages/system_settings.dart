import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  int _selectedTab = 0;

  // 设置状态
  bool _includeDate = true;
  bool _enhancedSearch = false;
  int _searchResultCount = 1;
  String _selectedSearchProvider = 'Tavily'; // 添加搜索服务商状态

  final List<_SettingCategory> _settingCategories = [
    _SettingCategory(icon: CupertinoIcons.cloud, title: '模型服务', items: []),
    _SettingCategory(
      icon: CupertinoIcons.device_laptop,
      title: '默认模型',
      items: [],
    ),
    _SettingCategory(icon: CupertinoIcons.globe, title: '网络搜索', items: []),
    _SettingCategory(
      icon: CupertinoIcons.cube_box,
      title: 'MCP 服务器',
      items: [],
    ),
    _SettingCategory(icon: CupertinoIcons.gear, title: '常规设置', items: []),
    _SettingCategory(
      icon: CupertinoIcons.square_grid_2x2,
      title: '显示设置',
      items: [],
    ),
    _SettingCategory(icon: CupertinoIcons.cube_box, title: '小程序设置', items: []),
    _SettingCategory(
      icon: CupertinoIcons.speedometer,
      title: '快捷方式',
      items: [],
    ),
    _SettingCategory(icon: CupertinoIcons.bolt, title: '快捷助手', items: []),
    _SettingCategory(
      icon: CupertinoIcons.text_alignleft,
      title: '快捷短语',
      items: [],
    ),
    _SettingCategory(icon: CupertinoIcons.chart_bar, title: '数据设置', items: []),
    _SettingCategory(
      icon: CupertinoIcons.info_circle,
      title: '关于我们',
      items: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.black54,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '系统设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
      ),
      body: Row(
        children: [
          // 左侧导航菜单
          _buildLeftNavigation(),
          // 分割线
          Container(width: 1, color: Colors.grey[100]),
          // 右侧内容区域
          Expanded(child: _buildRightContent()),
        ],
      ),
    );
  }

  Widget _buildLeftNavigation() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(right: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _settingCategories.length,
        itemBuilder: (context, index) {
          final category = _settingCategories[index];
          final isSelected = _selectedTab == index;
          return _buildNavItem(
            category.icon,
            category.title,
            index,
            isSelected,
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String title,
    int index,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isSelected
                ? Border.all(color: const Color(0xFFE5E5E5), width: 1)
                : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black87 : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightContent() {
    switch (_selectedTab) {
      case 2: // 网络搜索
        return _buildNetworkSearchSettings();
      case 4: // 常规设置
        return _buildGeneralSettings();
      default:
        return _buildPlaceholderContent(_settingCategories[_selectedTab].title);
    }
  }

  Widget _buildPlaceholderContent(String title) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.gear, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '该功能正在开发中...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSearchSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '网络搜索',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 搜索服务商配置卡片
          _buildConfigCard('搜索服务商', CupertinoIcons.globe, [
            _buildConfigItem(
              '搜索服务商',
              DropdownButtonFormField<String>(
                initialValue: _selectedSearchProvider,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: const [
                  DropdownMenuItem(
                    value: 'Tavily',
                    child: Text('Tavily', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'Google',
                    child: Text('Google', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'Bing',
                    child: Text('Bing', style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSearchProvider = value!;
                  });
                },
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Tavily API 配置卡片
          _buildConfigCard('Tavily 配置', CupertinoIcons.cloud, [
            // Tavily 服务商标题行
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tavily',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.open_in_new,
                      size: 10,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // API 密钥配置
            _buildConfigItem(
              'API 密钥',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: '请输入系统提示词，用于指导AI的行为和响应风格...',
                      hintStyle: const TextStyle(fontSize: 12), // 添加提示文字字体大小
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6), // 从8减少到6
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6), // 从8减少到6
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      contentPadding: const EdgeInsets.all(10), // 从12减少到10
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Handle get API key
                    },
                    child: const Text(
                      '点击这里获取密钥',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '全个密钥储存在本地分割',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle check
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('检查', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // 常规设置卡片
          _buildConfigCard('常规设置', CupertinoIcons.gear, [
            _buildSwitchConfigItem('搜索包含日期', _includeDate, (value) {
              setState(() {
                _includeDate = value;
              });
            }),

            const SizedBox(height: 12),

            _buildSwitchConfigItem(
              '搜索增强模式',
              _enhancedSearch,
              (value) {
                setState(() {
                  _enhancedSearch = value;
                });
              },
              trailing: const Icon(
                CupertinoIcons.question_circle,
                size: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            _buildSliderConfigItem(
              '搜索结果个数',
              _searchResultCount.toDouble(),
              1,
              20,
              19,
              (value) {
                setState(() {
                  _searchResultCount = value.round();
                });
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '常规设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // 这里可以添加更多常规设置项
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.gear, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '常规设置功能正在开发中...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchConfigItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildSliderConfigItem(
    String title,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            Text(
              '${value.round()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF10B981),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: const Color(0xFF10B981),
            overlayColor: const Color(0xFF10B981).withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.round()}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text('默认', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text(
              '${max.round()}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingCategory {
  final IconData icon;
  final String title;
  final List<String> items;

  _SettingCategory({
    required this.icon,
    required this.title,
    required this.items,
  });
}
