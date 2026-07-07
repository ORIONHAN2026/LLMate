// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'ChatHub';

  @override
  String get appSlogan => '智能对话助手';

  @override
  String get feedback => '反馈意见';

  @override
  String get modelManagement => '模型管理';

  @override
  String get connectorManagement => '连接器管理(MCP)';

  @override
  String get domainManagement => 'Service Management';

  @override
  String get otherSettings => '其他设置';

  @override
  String get languageSettings => '语言设置';

  @override
  String get skinSettings => '外观设置';

  @override
  String get followSystem => '跟随系统';

  @override
  String get followSystemDesc => '自动切换亮色/暗色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get lightModeDesc => '始终使用亮色主题';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeDesc => '始终使用暗色主题';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => '简体中文';

  @override
  String get english => 'English';

  @override
  String get englishDesc => '英语';

  @override
  String get login => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get add => '添加';

  @override
  String get close => '关闭';

  @override
  String get remove => '移除';

  @override
  String get clear => '清除';

  @override
  String get search => '搜索';

  @override
  String get noData => '暂无数据';

  @override
  String get loading => '加载中...';

  @override
  String get send => '发送';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get copyContent => '复制内容';

  @override
  String get retry => '重试';

  @override
  String get done => '完成';

  @override
  String get back => '返回';

  @override
  String get previousStep => '上一步';

  @override
  String get settings => '设置';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get temperature => '温度参数';

  @override
  String get replyLanguage => '回复语言';

  @override
  String get newSession => '新建会话';

  @override
  String get sessionList => '会话列表';

  @override
  String get rename => '重命名';

  @override
  String get shareConversation => '分享对话';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get clearConversation => '清空对话';

  @override
  String get deleteConversation => '删除会话';

  @override
  String get deleteConfirm => '确认删除';

  @override
  String get deleteConfirmMsg => '确定要删除吗？';

  @override
  String removeConfirmMsg(Object name) {
    return '确定要移除 \"$name\" 吗？';
  }

  @override
  String get addModel => '添加模型';

  @override
  String get copyModel => '复制模型';

  @override
  String get modelName => '模型名称';

  @override
  String get modelProvider => '服务商';

  @override
  String get modelApiKey => 'API 密钥';

  @override
  String get modelBaseUrl => '接口地址';

  @override
  String get modelMaxTokens => '最大Token数';

  @override
  String get thinkTag => '思考标签';

  @override
  String get thinkTagDesc => '模型的思考过程标签';

  @override
  String get addService => '添加服务';

  @override
  String get removeService => '移除服务';

  @override
  String get testConnection => '测试连接';

  @override
  String get fullTest => '完整测试';

  @override
  String get connectAndAdd => '连接并添加';

  @override
  String get addCustomConnector => '添加自定义连接器';

  @override
  String get clearKey => '清除密钥';

  @override
  String get fetchTools => '获取工具列表';

  @override
  String get fetchModels => '获取模型列表';

  @override
  String get copyMessage => '复制消息';

  @override
  String get regenerate => '重新生成';

  @override
  String get regenerateFromHere => '从此处重新生成';

  @override
  String get regenerateLastReply => '重新生成最后一条回复';

  @override
  String get regenerateThisReply => '重新生成这条回复';

  @override
  String get createNewChatFromHere => '从此处创建新对话';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get deleteReply => '删除回复';

  @override
  String get screenshot => '截图';

  @override
  String get entireConversation => '整个对话';

  @override
  String get currentRound => '当前回合';

  @override
  String get currentMessage => '当前消息';

  @override
  String get memoryConfig => '记忆配置';

  @override
  String get clearMcpServices => '清空MCP服务';

  @override
  String get selectFile => '选择文件';

  @override
  String get selectWorkingDir => '选择工作目录';

  @override
  String get confirmDeleteTitle => '确认删除';

  @override
  String get deleteSessionTitle => '删除会话';

  @override
  String get favorites => '收藏';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get earlier => '更早';

  @override
  String get removeServiceTitle => '移除服务';

  @override
  String get removeMcpServiceTitle => '移除 MCP 服务';

  @override
  String get noActiveSession => '当前没有活动会话';

  @override
  String get presetRoleApplied => '预设角色已应用';

  @override
  String get fileNotFound => '文件不存在';

  @override
  String get fileOpenFailed => '打开文件失败';

  @override
  String get enterMessageContent => '请输入消息内容';

  @override
  String get copyMessageContent => '复制消息内容';

  @override
  String get apiKeyHint => '请输入API密钥';

  @override
  String get modelNameHint => '请输入模型名称';

  @override
  String get messageHint => '请输入消息内容...';

  @override
  String get apiUrlHint => '输入API地址';

  @override
  String get commandHint => '输入快捷指令内容';

  @override
  String get enterCommandContent => '请输入指令内容';

  @override
  String get modelSearchHint => '输入模型名称，如：gpt-4o-mini, claude-3-haiku 等';

  @override
  String get roleDescHint => '请输入角色设定的描述，用于指导大模型的行为和响应风格...';

  @override
  String get toolLogicHint => '请输入工具的工作逻辑描述...';

  @override
  String get typeCommandOrSearch => '键入命令或搜索...';

  @override
  String get searchMcp => '搜索 MCP 服务...';

  @override
  String get scheduledMessageHint => '定时发送的消息内容...';

  @override
  String get cronExample => '例: 0 9 * * * (每天9:00)';

  @override
  String get config => '配置';

  @override
  String get pasteMcpCode => '请粘贴 MCP 代码';

  @override
  String get fileNameLabel => '文件名';

  @override
  String get fileSizeLabel => '大小';

  @override
  String get fileTypeLabel => '类型';

  @override
  String get filePathLabel => '路径';

  @override
  String get aliyun => '阿里云';

  @override
  String get tencentCloud => '腾讯云';

  @override
  String get modelscope => '魔塔';

  @override
  String get goToAliyun => '去阿里云开通';

  @override
  String pleaseEnter(Object field) {
    return '请输入$field';
  }

  @override
  String get more => '更多';

  @override
  String get copyFailed => '复制失败';

  @override
  String get invalidLinkFormat => '链接格式不正确';

  @override
  String get cannotOpenLink => '无法打开链接';

  @override
  String get linkOpenedInBrowser => '已在浏览器中打开链接';

  @override
  String get cannotOpenThisLinkType => '无法打开此类型的链接';

  @override
  String get openLinkFailed => '打开链接失败';

  @override
  String get fileOpened => '已打开文件';

  @override
  String get cannotOpenFile => '无法打开文件';

  @override
  String get openFileFailed => '打开文件失败';

  @override
  String get sessionNotFoundForMessage => '找不到包含该消息的会话';

  @override
  String get messageNotFound => '消息不存在';

  @override
  String get regenerateFailed => '重新生成失败';

  @override
  String get cannotFindQuestion => '无法找到对应的问题';

  @override
  String get noAiReplyFound => '没有找到AI回复';

  @override
  String get cannotRegenerateInvalidIndex => '无法重新生成：消息索引无效';

  @override
  String get editMessageTitle => '编辑消息';

  @override
  String get messageContentCannotBeEmpty => '消息内容不能为空';

  @override
  String get newChatFromHistory => '基于历史记录的新对话';

  @override
  String get newChatCreatedFromHere => '已从此处创建新对话';

  @override
  String get createNewChatFailed => '创建新对话失败';

  @override
  String get thinking => '思考中...';

  @override
  String get callingTool => '正在调用工具';

  @override
  String get toolCallRecord => '工具调用记录';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get deleteMessageFailed => '删除消息失败';

  @override
  String get duration => '耗时';

  @override
  String get calculating => '计算中...';

  @override
  String get speed => '速度';

  @override
  String get outputTokensLabel => '生成 token 数';

  @override
  String get fullscreen => '全屏';

  @override
  String get collapseSidebar => '收起边栏';

  @override
  String get expandSidebar => '展开边栏';

  @override
  String get collapseRightSidebar => '收起右侧栏';

  @override
  String get expandRightSidebar => '展开右侧栏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoriteSession => '收藏会话';

  @override
  String get user => '用户';

  @override
  String get assistant => '助手';

  @override
  String get noMemory => '暂无记忆';

  @override
  String get noFiles => '暂无文件';

  @override
  String get fileInfo => '文件信息';

  @override
  String get fileContent => '文件内容';

  @override
  String get noContentPreview => '暂无内容预览';

  @override
  String get fileContentCopied => '文件内容已复制到剪贴板';

  @override
  String get selectOrCreateSession => '请选择或创建一个会话';

  @override
  String get invalidSessionIndex => '无效的会话索引';

  @override
  String get cannotOpenEmailApp => '无法打开邮箱应用';

  @override
  String get sendEmailFailed => '发送邮件失败';

  @override
  String get memorySummary => '记忆摘要';

  @override
  String get recentConversations => '最近对话';

  @override
  String get sessionFiles => '会话文件';

  @override
  String get files => '文件';

  @override
  String get memory => '记忆';

  @override
  String get processed => '已处理';

  @override
  String todayTime(Object time) {
    return '今天 $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month月$day日 $time';
  }

  @override
  String messageCount(Object count) {
    return '$count 条';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action 失败: $error';
  }

  @override
  String xDone(Object action) {
    return '$action 完成';
  }

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get replyDeleted => '已删除此消息后的所有回复';

  @override
  String get deleteReplyFailed => '删除回复失败';

  @override
  String get asConversationContinues => '随着对话进行，AI 会自动\n记录和压缩对话记忆';

  @override
  String get whenAiCreatesFiles => '当 AI 工具在对话中创建或\n修改文件后，会在此显示';

  @override
  String get deleteSessionTitle_warning => '此操作无法撤销';

  @override
  String get pleaseSetupModel => '请设置大模型';

  @override
  String get clickToSelectModel => '点击上方选择对话模型';

  @override
  String get selectModel => '选择对话模型';

  @override
  String get noAvailableModels => '暂无可用模型';

  @override
  String get sessionNotFoundCannotSelectModel => '当前会话不存在，无法选择模型';

  @override
  String get inputHint => '在这里输入消息，↵ 发送，Shift+↵ 换行';

  @override
  String get stopAnswer => '停止回答';

  @override
  String waitingAttachments(Object count) {
    return '等待 $count 个附件处理完成';
  }

  @override
  String get sendMessageAction => '发送消息';

  @override
  String get deepThinkEnabled => '深度思考: 已开启';

  @override
  String get deepThinkDisabled => '深度思考: 已关闭';

  @override
  String get deepThink => '深度思考';

  @override
  String get workingDirectoryLabel => '工作目录';

  @override
  String workingDirectoryPath(Object path) {
    return '工作目录: $path';
  }

  @override
  String get setWorkingDirHint => '设置工作目录（文件默认保存位置）';

  @override
  String get workingDirSet => '工作目录已设置';

  @override
  String get workingDirCleared => '工作目录已清除';

  @override
  String get noWorkingDir => 'Please set the contract file directory first';

  @override
  String get parseContract => 'Parse Contract';

  @override
  String get parseContractHint => 'Parse contract files in working directory';

  @override
  String get parseContractPrompt =>
      'The following are document files in the working directory. Please first determine which files are actual contract documents (not attachments, descriptions, or other non-contract files). Then, only for files confirmed as contracts, use the contract_inspect tool to write each contract\'s information.\n\nWriting rules:\n- For each contract, first call action=add to create a contract entry (fill in contractName, contractType, paymentClause, paymentSchedule, breachClause, liabilityClause, startDate, endDate, signingDate, etc.)\n- Then call action=addParty for each party, adding Party A, Party B, etc. one by one\n- Also briefly explain in your reply which files were determined as non-contract and why';

  @override
  String get contractPoints => 'Contract Points';

  @override
  String get noContracts => 'No contract points';

  @override
  String get contractParsing =>
      'Contract points will appear here after parsing';

  @override
  String get contractParty => 'Parties';

  @override
  String get contractPaymentClause => 'Payment Clause';

  @override
  String get contractPaymentSchedule => 'Payment Schedule';

  @override
  String get contractBreachClause => 'Breach Clause';

  @override
  String get contractLiability => 'Liability';

  @override
  String get contractPeriod => 'Contract Period';

  @override
  String get contractSigningDate => 'Signing Date';

  @override
  String get contractTypeLabel => 'Contract Type';

  @override
  String nRounds(Object n) {
    return '$n轮';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return '记忆配置: 保留最近 $label 对话';
  }

  @override
  String get closeMemory => '关闭记忆';

  @override
  String get noContext => '无上下文';

  @override
  String keepXRounds(Object n) {
    return '保留 $n 轮';
  }

  @override
  String lastXRounds(Object n) {
    return '最近$n轮';
  }

  @override
  String get defaultMemory => '默认';

  @override
  String get longConversation => '长对话';

  @override
  String get veryLongConversation => '超长对话';

  @override
  String get noMatchingResults => '无匹配结果';

  @override
  String get memoryClosed => '已关闭记忆';

  @override
  String memoryConfigSet(Object n) {
    return '记忆配置: $n轮';
  }

  @override
  String get attach => '附件';

  @override
  String get selectMcpTool => '选连接器';

  @override
  String get noMcpTool => '无连接器';

  @override
  String get viewMcpToolDetail => '查看MCP工具详情';

  @override
  String get clickToSelectMcpTool => '点击选择MCP工具';

  @override
  String get noMcpToolConfigured => '当前模型未配置MCP工具';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return '工具工作逻辑描述: $desc';
  }

  @override
  String get clickToDesignWorkflow => '设定连接器和技能联合使用逻辑';

  @override
  String get alreadySet => '已设置';

  @override
  String get toolWorkflowDescTitle => '工具的工作逻辑描述';

  @override
  String get enterToolWorkflowDesc => '请输入工具的工作逻辑描述...';

  @override
  String get relationDescCleared => '已清空关系描述';

  @override
  String get relationDescSaved => '已保存关系描述';

  @override
  String get noMcpServiceConfigured => '当前未配置MCP服务';

  @override
  String mcpServiceList(Object n) {
    return 'MCP服务列表 ($n)';
  }

  @override
  String get mcpServiceTitle => 'MCP服务';

  @override
  String get enabledStatus => '已启用';

  @override
  String get disabledStatus => '已禁用';

  @override
  String commandLabel(Object cmd) {
    return '命令: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return '参数: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return '工作目录: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return '超时: $n秒';
  }

  @override
  String get mcpListHint => '提示：双击MCP按钮查看此列表，单击切换开关状态';

  @override
  String get mcpEnabledMsg => '已开启MCP工具，发送消息时可自动调用相关工具';

  @override
  String get mcpDisabledMsg => '已关闭MCP工具';

  @override
  String get clearMcpService => '清空MCP服务';

  @override
  String get unbindAction => '取消绑定';

  @override
  String xTools(Object n) {
    return '$n个工具';
  }

  @override
  String mcpServiceSelected(Object name) {
    return '已选择 MCP 服务: $name';
  }

  @override
  String get mcpToolsDisabled => '已关闭MCP工具';

  @override
  String get createAction => '创建';

  @override
  String get noModelBound => '还未绑定模型';

  @override
  String serviceUnavailable(Object error) {
    return '抱歉，服务暂时不可用，$error';
  }

  @override
  String get confirmClear => '确认清除';

  @override
  String get clearHistoryConfirmMsg => '确定要清除当前对话的所有历史记录吗？此操作不可撤销。';

  @override
  String get historyCleared => '历史记录已清除';

  @override
  String folderPath(Object path) {
    return '文件夹: $path';
  }

  @override
  String toolList(Object n) {
    return '工具列表 ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... 还有 $n 个工具';
  }

  @override
  String get jsonCopied => 'JSON 已复制';

  @override
  String get mcpDetail => 'MCP 详情';

  @override
  String toolsRefreshed(Object n) {
    return '已刷新 $n 个工具';
  }

  @override
  String refreshFailed(Object error) {
    return '刷新失败: $error';
  }

  @override
  String get refreshAction => '刷新';

  @override
  String toolsFetched(Object n) {
    return '已获取 $n 个工具';
  }

  @override
  String fetchFailed(Object error) {
    return '获取失败: $error';
  }

  @override
  String get scheduledTaskLabel => '定时任务';

  @override
  String get setScheduledMessage => '设置定时消息';

  @override
  String get scheduledLabelColon => '定时';

  @override
  String get modelConfigNotFound => '未找到模型配置';

  @override
  String get modelProviderNotConfigured => '模型提供商未配置';

  @override
  String get screenshotFailed => '截图失败：未找到渲染对象';

  @override
  String get generateImageFailed => '生成图片失败';

  @override
  String get messageScreenshotCopied => '消息截图已复制到剪贴板';

  @override
  String get currentRoundScreenshotCopied => '当前回合截图已复制到剪贴板';

  @override
  String get fullConversationScreenshotCopied => '整个对话截图已复制到剪贴板';

  @override
  String get noMessagesInConversation => '对话中没有消息';

  @override
  String get cannotFindMessage => '找不到当前消息';

  @override
  String get cannotFindCompleteRound => '找不到完整的对话回合';

  @override
  String partialScreenshot(Object n, Object total) {
    return '部分消息未能截图，已截图 $n/$total 条消息';
  }

  @override
  String get renderObjectStillDrawing => '截图失败：渲染对象还在绘制中';

  @override
  String screenshotCopied(Object type) {
    return '$type截图已复制到剪贴板';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return '生成$type截图失败: $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return '合并截图失败: $error';
  }

  @override
  String copyImageFailed(Object error) {
    return '复制图片失败: $error';
  }

  @override
  String get unsupportedOS => '不支持的操作系统';

  @override
  String desktopCopyFailed(Object error) {
    return '桌面端复制图片失败: $error';
  }

  @override
  String get noClipboardTool => '无法找到可用的剪贴板工具（xclip 或 wl-copy）';

  @override
  String get cannotFindRenderObject => '无法找到消息的渲染对象';

  @override
  String get editScheduledTask => '编辑定时任务';

  @override
  String get setScheduledTaskDialog => '设置定时任务';

  @override
  String get cronExpression => 'Cron 表达式';

  @override
  String get cronFormat => '格式: 分 时 日 月 周 (5个字段)';

  @override
  String get messageContentLabel => '消息内容';

  @override
  String get enableTask => '启用任务';

  @override
  String get pleaseEnterCron => '请输入 cron 表达式';

  @override
  String get cronFormatError => 'cron 格式错误（需要5个字段）';

  @override
  String get daily0900 => '每天 09:00';

  @override
  String get daily1200 => '每天 12:00';

  @override
  String get daily1800 => '每天 18:00';

  @override
  String get workday0900 => '工作日 09:00';

  @override
  String get every30min => '每 30 分钟';

  @override
  String get every2h => '每 2 小时';

  @override
  String get processFailedStatus => '处理失败';

  @override
  String get processingStatus => '正在处理';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - 内容预览';
  }

  @override
  String get contentCopiedToClipboard => '已复制内容到剪贴板';

  @override
  String get fileProcessFailed => '文件处理失败';

  @override
  String get pleaseReupload => '请重新上传文件或联系技术支持';

  @override
  String get processingFileStatus => '正在处理文件...';

  @override
  String get imageFile => '图片文件';

  @override
  String get documentFile => '文档文件';

  @override
  String get textFile => '文本文件';

  @override
  String get codeFile => '代码文件';

  @override
  String get officeDocument => '办公文档';

  @override
  String get webLink => '网页链接';

  @override
  String get folderType => '文件夹';

  @override
  String get otherFile => '其他文件';

  @override
  String get defaultConversation => '通用对话';

  @override
  String modelCopied(Object name) {
    return '模型 \"$name\" 复制成功';
  }

  @override
  String copyOf(Object name) {
    return '$name的副本';
  }

  @override
  String copyOfN(Object n, Object name) {
    return '$name的副本($n)';
  }

  @override
  String get noModels => '暂无模型';

  @override
  String get clickAddModelHint => '点击左下角\"添加模型\"按钮开始添加';

  @override
  String modelUpdatedNotify(Object name) {
    return '模型 \"$name\" 已更新，相关会话设置已同步';
  }

  @override
  String serviceRemoved(Object name) {
    return '已移除服务: $name';
  }

  @override
  String get connectorManagementTitle => '连接器管理(MCP)';

  @override
  String get marketplace => '应用市场';

  @override
  String get noMcpServices => '暂无 MCP 服务';

  @override
  String get clickToEnterMarketplace => '点击右上角 + 号进入应用市场';

  @override
  String fetchToolsFailed(Object error) {
    return '获取工具失败: $error';
  }

  @override
  String get removeServiceLabel => '移除服务';

  @override
  String get removeServiceConfirm => '确定要移除服务';

  @override
  String get removeServiceWarning => '移除后需重新添加';

  @override
  String get jsonConfig => 'cấu hình JSON';

  @override
  String get cannotReadFilePath => 'Không thể đọc đường dẫn tập tin';

  @override
  String get extractingImport => 'Đang giải nén và nhập...';

  @override
  String importFailed(Object error) {
    return 'Nhập không thành công: $error';
  }

  @override
  String get irreversibleAction => 'Hành động này không thể thay đổi được';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'Đã xóa mô hình';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'Đã xóa thành công mô hình \"$name\"';
  }

  @override
  String get selectOtherModelFromList =>
      'Vui lòng chọn mô hình khác từ danh sách bên trái để xem chi tiết';

  @override
  String get unnamedModel => 'Mô hình không tên';

  @override
  String get noDescription => 'Không có mô tả';

  @override
  String get confirmDeleteModel => 'Bạn có chắc chắn muốn xóa mô hình';

  @override
  String modelDeletedToast(Object name) {
    return 'Đã xóa mô hình \"$name\"';
  }

  @override
  String get addOnlineModel => 'Thêm mô hình trực tuyến';

  @override
  String get selectProvider => 'Chọn nhà cung cấp';

  @override
  String get configureParams => 'Cấu hình tham số';

  @override
  String get checkConfig => 'Kiểm tra cấu hình';

  @override
  String get setName => 'Đặt tên';

  @override
  String get nextStep => 'Tiếp theo';

  @override
  String get selectOnlineProvider => 'Chọn nhà cung cấp mô hình trực tuyến';

  @override
  String get customProvider => 'Tùy chỉnh';

  @override
  String get customProviderDesc =>
      'Nhập thủ công địa chỉ, khóa API và tên mô hình';

  @override
  String get customProviderConfigTitle => 'Cấu hình mô hình tùy chỉnh';

  @override
  String configureProviderParams(Object provider) {
    return 'Cấu hình tham số $provider';
  }

  @override
  String get ollamaApiKeyOptional =>
      'Dịch vụ Ollama cục bộ thường không cần khóa API, có thể để trống';

  @override
  String get apiAddress => 'Địa chỉ API';

  @override
  String get defaultApiUrlNote =>
      'Địa chỉ API chính thức mặc định, có thể sửa đổi cho triển khai cục bộ hoặc riêng tư';

  @override
  String get presetModel => 'Mô hình cài sẵn';

  @override
  String get customModel => 'Mô hình tùy chỉnh';

  @override
  String get enterFullModelName =>
      'Nhập tên mô hình đầy đủ được nhà cung cấp hỗ trợ';

  @override
  String get ollamaRunningModels => 'Mô hình Ollama đang chạy';

  @override
  String get refreshModelList => 'Làm mới danh sách mô hình';

  @override
  String get ollamaStartHint =>
      'Vui lòng khởi động dịch vụ Ollama và tải xuống mô hình trước\nsau đó nhấp làm mới để lấy danh sách mô hình';

  @override
  String get modelscopeAvailableModels => 'Mô hình ModelScope có sẵn';

  @override
  String get modelscopeApiKeyHint =>
      'Vui lòng đảm bảo khóa API chính xác\nsau đó nhấp làm mới để lấy danh sách mô hình';

  @override
  String get setModelName => 'Đặt tên mô hình';

  @override
  String get configSummary => 'Tóm tắt cấu hình';

  @override
  String get providerLabel => 'Nhà cung cấp';

  @override
  String get platformLabel => 'Nền tảng';

  @override
  String get notSet => 'Chưa đặt';

  @override
  String get modelLabel => 'Mô hình';

  @override
  String get customSuffix => '(Tùy chỉnh)';

  @override
  String get notSelected => 'Chưa chọn';

  @override
  String get customModelName => 'Tên mô hình tùy chỉnh';

  @override
  String enterModelNameHint(Object provider) {
    return 'Nhập tên mô hình, ví dụ: $provider-Chat';
  }

  @override
  String get modelNameSuggestion => 'Sử dụng tên có ý nghĩa để dễ nhận diện';

  @override
  String get testConnectionDesc => 'Kiểm tra kết nối và phản hồi của mô hình';

  @override
  String get waitingForResponse => 'Đang chờ phản hồi...';

  @override
  String get configIncomplete => 'Cấu hình không đầy đủ';

  @override
  String get receivedEmptyResponse => 'Nhận được phản hồi trống';

  @override
  String get receivedNoResponse => 'Không nhận được phản hồi';

  @override
  String connectionFailed(Object error) {
    return 'Kết nối thất bại: $error';
  }

  @override
  String get contextCap => 'Ngữ cảnh';

  @override
  String get thinkingCap => 'Suy nghĩ';

  @override
  String get builtinToolsCap => 'Công cụ tích hợp';

  @override
  String get structuredCap => 'Cấu trúc';

  @override
  String get batchCap => 'Hàng loạt';

  @override
  String get basicInfo => 'Thông tin cơ bản';

  @override
  String get modelParams => 'Tham số mô hình';

  @override
  String get unknown => 'Không xác định';

  @override
  String get nameLabel => 'Tên';

  @override
  String get apiKeyLabel => 'Khóa API';

  @override
  String get notSetDoubleClickToEdit => 'Chưa đặt (nhấp đúp để chỉnh sửa)';

  @override
  String get apiKeySaved => 'Đã lưu khóa API';

  @override
  String get modelNameCannotBeEmpty => 'Tên mô hình không được để trống';

  @override
  String get modelNameSaved => 'Đã lưu tên mô hình';

  @override
  String get modelSaved => 'Đã lưu mô hình';

  @override
  String get temperatureLabel => 'Nhiệt độ (Temperature)';

  @override
  String get precise => 'Chính xác';

  @override
  String get neutral => 'Trung tính';

  @override
  String get creative => 'Sáng tạo';

  @override
  String get temperatureDescription =>
      'Kiểm soát tính ngẫu nhiên và sáng tạo của phản hồi. Giá trị thấp hơn thì bảo thủ hơn, giá trị cao hơn thì sáng tạo hơn.';

  @override
  String get modelRoleSetting => 'Thiết lập vai trò mô hình';

  @override
  String get presetRole => 'Vai trò cài sẵn';

  @override
  String get roleSettingDescription =>
      'Thiết lập vai trò được gửi đến mô hình khi bắt đầu mỗi cuộc trò chuyện để xác định vai trò và hành vi. Có thể điều chỉnh theo vai trò bạn muốn mô hình đảm nhận.';

  @override
  String get selectPresetRole => 'Chọn vai trò cài sẵn';

  @override
  String get generalAssistant => 'Trợ lý chung';

  @override
  String get friendlyAssistantDesc => 'Trợ lý AI thân thiện, chuyên nghiệp';

  @override
  String get spellCheck => 'Kiểm tra chính tả';

  @override
  String get spellCheckDesc => 'Chuyên gia kiểm tra chính tả';

  @override
  String get codeExpert => 'Chuyên gia lập trình';

  @override
  String get codeExpertDesc => 'Chuyên gia kỹ thuật về lập trình và phát triển';

  @override
  String get legalExpert => 'Chuyên gia pháp lý';

  @override
  String get legalExpertDesc => 'Cố vấn pháp lý chuyên nghiệp';

  @override
  String get copywriter => 'Người viết nội dung';

  @override
  String get copywriterDesc => 'Chuyên gia viết nội dung sáng tạo';

  @override
  String get dataAnalyst => 'Nhà phân tích dữ liệu';

  @override
  String get dataAnalystDesc => 'Chuyên gia phân tích dữ liệu và thống kê';

  @override
  String get educationTutor => 'Gia sư giáo dục';

  @override
  String get educationTutorDesc => 'Chuyên gia giảng dạy kiên nhẫn';

  @override
  String get businessConsultant => 'Tư vấn kinh doanh';

  @override
  String get businessConsultantDesc =>
      'Chuyên gia quản lý doanh nghiệp và chiến lược';

  @override
  String get psychologist => 'Nhà tâm lý học';

  @override
  String get psychologistDesc => 'Tư vấn sức khỏe tâm thần chuyên nghiệp';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get workModeSettings => 'Work Mode';

  @override
  String get workModeBusiness => 'Business';

  @override
  String get workModeBusinessDesc =>
      'Business negotiation, contract management, strategy';

  @override
  String get workModeFinance => 'Finance';

  @override
  String get workModeFinanceDesc =>
      'Financial analysis, tax planning, cost accounting';

  @override
  String get workModeLegal => 'Legal';

  @override
  String get workModeLegalDesc =>
      'Legal drafting, compliance review, risk assessment';

  @override
  String get workModeMarketing => 'Marketing';

  @override
  String get workModeMarketingDesc =>
      'Marketing planning, brand promotion, competitive analysis';

  @override
  String get domainSettings => 'Service Settings';

  @override
  String get serviceStatus => 'Local Service';

  @override
  String get localService => 'Local Service';

  @override
  String get serviceStopped => 'Service stopped';

  @override
  String get serviceRunning => 'Running';

  @override
  String get serviceStarting => 'Starting...';

  @override
  String get restart => 'Restart';

  @override
  String get certificateSettings => 'Certificate Settings';

  @override
  String get httpsStatus => 'HTTPS Status';

  @override
  String get domainAddress => 'Service Address';

  @override
  String get domainHint => 'e.g. api.example.com';

  @override
  String get domainDesc =>
      'After setting, the session service URL will use this address. HTTP default port 80, HTTPS default port 443.';

  @override
  String get sslCertificate => 'SSL Certificate';

  @override
  String get sslPrivateKey => 'Private Key';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get httpsEnabled => 'HTTPS';

  @override
  String get httpsEnabledDesc => 'Certificate uploaded, HTTPS auto-enabled';

  @override
  String get httpsDisabledDesc =>
      'Upload certificate (crt/cert + key) to auto-enable HTTPS';

  @override
  String get domainInfoDesc =>
      'After configuring the service address, the session service URL will display this address. External clients can access the session API (/llmwork/chat/completions etc.) through this address.';

  @override
  String get pleaseEnterDomain => 'Please enter service address';

  @override
  String get domainSaved => 'Service configuration saved';
}
