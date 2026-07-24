// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => 'Smart Chat Assistant';

  @override
  String get feedback => 'Feedback';

  @override
  String get modelManagement => 'Model Management';

  @override
  String get connectorManagement => 'Connector (MCP)';

  @override
  String get domainManagement => 'Service Management';

  @override
  String get otherSettings => 'Other Settings';

  @override
  String get resetSystem => 'Reset System';

  @override
  String get resetAllSessions => 'Reset All Sessions';

  @override
  String get resetAllModels => 'Reset All Models';

  @override
  String get resetAllMcp => 'Reset All MCP';

  @override
  String get resetAll => 'Reset All';

  @override
  String resetConfirmMsg(Object action) {
    return 'Are you sure you want to $action? This action cannot be undone.';
  }

  @override
  String get languageSettings => 'Language';

  @override
  String get skinSettings => 'Skin';

  @override
  String get followSystem => 'Follow System';

  @override
  String get followSystemDesc => 'Auto switch light/dark mode';

  @override
  String get lightMode => 'Light';

  @override
  String get lightModeDesc => 'Always use light theme';

  @override
  String get darkMode => 'Dark';

  @override
  String get darkModeDesc => 'Always use dark theme';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => 'Simplified Chinese';

  @override
  String get english => 'English';

  @override
  String get englishDesc => 'English';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get search => 'Search';

  @override
  String get noData => 'No data';

  @override
  String get loading => 'Loading...';

  @override
  String get send => 'Send';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get copyContent => 'Copy Content';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get previousStep => 'Previous';

  @override
  String get settings => 'Settings';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get temperature => 'Temperature';

  @override
  String get replyLanguage => 'Reply Language';

  @override
  String get newSession => 'New Session';

  @override
  String get sessionList => 'Session List';

  @override
  String get rename => 'Rename';

  @override
  String get shareConversation => 'Share Conversation';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearConversation => 'Clear Conversation';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get deleteConfirm => 'Delete Confirmation';

  @override
  String get deleteConfirmMsg => 'Are you sure you want to delete?';

  @override
  String removeConfirmMsg(Object name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String get addModel => 'Add Model';

  @override
  String get copyModel => 'Copy Model';

  @override
  String get modelName => 'Model Name';

  @override
  String get modelProvider => 'Provider';

  @override
  String get modelApiKey => 'API Key';

  @override
  String get modelBaseUrl => 'Base URL';

  @override
  String get modelMaxTokens => 'Max Tokens';

  @override
  String get thinkTag => 'Think Tag';

  @override
  String get thinkTagDesc => 'Thought process tag for the model';

  @override
  String get addService => 'Add Service';

  @override
  String get removeService => 'Remove Service';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get fullTest => 'Full Test';

  @override
  String get connectAndAdd => 'Connect & Add';

  @override
  String get addCustomConnector => 'Add Custom Connector';

  @override
  String get clearKey => 'Clear Key';

  @override
  String get fetchTools => 'Fetch Tools';

  @override
  String get fetchModels => 'Fetch Models';

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get regenerateFromHere => 'Regenerate From Here';

  @override
  String get regenerateLastReply => 'Regenerate Last Reply';

  @override
  String get regenerateThisReply => 'Regenerate This Reply';

  @override
  String get createNewChatFromHere => 'New Chat From Here';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get deleteReply => 'Delete Reply';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get entireConversation => 'Entire Conversation';

  @override
  String get currentRound => 'Current Round';

  @override
  String get currentMessage => 'Current Message';

  @override
  String get memoryConfig => 'Memory Config';

  @override
  String get clearMcpServices => 'Clear MCP Services';

  @override
  String get selectFile => 'Select File';

  @override
  String get selectWorkingDir => 'Select Working Directory';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String get deleteSessionTitle => 'Delete Session';

  @override
  String get favorites => 'Favorites';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get earlier => 'Earlier';

  @override
  String get removeServiceTitle => 'Remove Service';

  @override
  String get removeMcpServiceTitle => 'Remove MCP Service';

  @override
  String get noActiveSession => 'No active session';

  @override
  String get presetRoleApplied => 'Preset role applied';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get fileOpenFailed => 'Failed to open file';

  @override
  String get enterMessageContent => 'Please enter message content';

  @override
  String get copyMessageContent => 'Copy Message Content';

  @override
  String get apiKeyHint => 'Enter API Key';

  @override
  String get modelNameHint => 'Enter model name';

  @override
  String get messageHint => 'Enter message content...';

  @override
  String get apiUrlHint => 'Enter API URL';

  @override
  String get commandHint => 'Enter command content';

  @override
  String get enterCommandContent => 'Please enter command content';

  @override
  String get modelSearchHint =>
      'Enter model name, e.g. gpt-4o-mini, claude-3-haiku';

  @override
  String get roleDescHint =>
      'Enter role description to guide the model\'s behavior and response style...';

  @override
  String get toolLogicHint => 'Enter the tool logic description...';

  @override
  String get typeCommandOrSearch => 'Type command or search...';

  @override
  String get searchMcp => 'Search MCP services...';

  @override
  String get cronExample => 'e.g. 0 9 * * * (daily at 9:00)';

  @override
  String get config => 'Config';

  @override
  String get pasteMcpCode => 'Paste MCP code';

  @override
  String get fileNameLabel => 'Filename';

  @override
  String get fileSizeLabel => 'Size';

  @override
  String get fileTypeLabel => 'Type';

  @override
  String get filePathLabel => 'Path';

  @override
  String get aliyun => 'Alibaba Cloud';

  @override
  String get tencentCloud => 'Tencent Cloud';

  @override
  String get modelscope => 'ModelScope';

  @override
  String get goToAliyun => 'Go to Alibaba Cloud';

  @override
  String pleaseEnter(Object field) {
    return 'Please enter $field';
  }

  @override
  String get more => 'More';

  @override
  String get copyFailed => 'Copy failed';

  @override
  String get invalidLinkFormat => 'Invalid link format';

  @override
  String get cannotOpenLink => 'Cannot open link';

  @override
  String get linkOpenedInBrowser => 'Link opened in browser';

  @override
  String get cannotOpenThisLinkType => 'Cannot open this link type';

  @override
  String get openLinkFailed => 'Open link failed';

  @override
  String get fileOpened => 'File opened';

  @override
  String get cannotOpenFile => 'Cannot open file';

  @override
  String get openFileFailed => 'Open file failed';

  @override
  String get sessionNotFoundForMessage => 'Session not found for this message';

  @override
  String get messageNotFound => 'Message not found';

  @override
  String get regenerateFailed => 'Regeneration failed';

  @override
  String get cannotFindQuestion => 'Cannot find the corresponding question';

  @override
  String get noAiReplyFound => 'No AI reply found';

  @override
  String get cannotRegenerateInvalidIndex =>
      'Cannot regenerate: invalid message index';

  @override
  String get editMessageTitle => 'Edit Message';

  @override
  String get messageContentCannotBeEmpty => 'Message content cannot be empty';

  @override
  String get newChatFromHistory => 'New chat from history';

  @override
  String get newChatCreatedFromHere => 'New chat created from here';

  @override
  String get createNewChatFailed => 'Failed to create new chat';

  @override
  String get thinking => 'Thinking...';

  @override
  String get callingTool => 'Calling tool';

  @override
  String get toolCallRecord => 'Tool call record';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deleteMessageFailed => 'Failed to delete message';

  @override
  String get duration => 'Duration';

  @override
  String get calculating => 'Calculating...';

  @override
  String get speed => 'Speed';

  @override
  String get outputTokensLabel => 'Output tokens';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get collapseSidebar => 'Collapse Sidebar';

  @override
  String get expandSidebar => 'Expand Sidebar';

  @override
  String get collapseRightSidebar => 'Collapse Right Sidebar';

  @override
  String get expandRightSidebar => 'Expand Right Sidebar';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get favoriteSession => 'Add to favorites';

  @override
  String get user => 'User';

  @override
  String get assistant => 'Assistant';

  @override
  String get noMemory => 'No memory';

  @override
  String get noFiles => 'No files';

  @override
  String get fileInfo => 'File Info';

  @override
  String get fileContent => 'File Content';

  @override
  String get noContentPreview => 'No content preview';

  @override
  String get fileContentCopied => 'File content copied to clipboard';

  @override
  String get selectOrCreateSession => 'Please select or create a session';

  @override
  String get invalidSessionIndex => 'Invalid session index';

  @override
  String get cannotOpenEmailApp => 'Cannot open email app';

  @override
  String get sendEmailFailed => 'Failed to send email';

  @override
  String get memorySummary => 'Memory Summary';

  @override
  String get recentConversations => 'Recent Conversations';

  @override
  String get sessionFiles => 'Session Files';

  @override
  String get files => 'Files';

  @override
  String get memory => 'Memory';

  @override
  String get processed => 'Processed';

  @override
  String todayTime(Object time) {
    return 'Today $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month/$day $time';
  }

  @override
  String messageCount(Object count) {
    return '$count messages';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action failed: $error';
  }

  @override
  String xDone(Object action) {
    return '$action completed';
  }

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get replyDeleted => 'Replies deleted';

  @override
  String get deleteReplyFailed => 'Failed to delete replies';

  @override
  String get asConversationContinues =>
      'As the conversation continues, AI will\nautomatically record and compress memory';

  @override
  String get whenAiCreatesFiles =>
      'When AI tools create or modify\nfiles in conversation, they will appear here';

  @override
  String get deleteSessionTitle_warning => 'This action cannot be undone';

  @override
  String get pleaseSetupModel => 'Please set up a model';

  @override
  String get clickToSelectModel => 'Click above to select a chat model';

  @override
  String get selectModel => 'Select Model';

  @override
  String get noAvailableModels => 'No available models';

  @override
  String get sessionNotFoundCannotSelectModel =>
      'Session not found, cannot select model';

  @override
  String get inputHint => 'Type message here, ↵ to send, Shift+↵ for new line';

  @override
  String get stopAnswer => 'Stop answering';

  @override
  String waitingAttachments(Object count) {
    return 'Waiting for $count attachments to process';
  }

  @override
  String get sendMessageAction => 'Send message';

  @override
  String get deepThinkEnabled => 'Deep Think: On';

  @override
  String get deepThinkDisabled => 'Deep Think: Off';

  @override
  String get deepThink => 'Deep Think';

  @override
  String get workingDirectoryLabel => 'Working Directory';

  @override
  String workingDirectoryPath(Object path) {
    return 'Working Directory: $path';
  }

  @override
  String get setWorkingDirHint =>
      'Set working directory (default save location)';

  @override
  String get workingDirSet => 'Working directory set';

  @override
  String get workingDirCleared => 'Working directory cleared';

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
    return '$n rounds';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return 'Memory config: Keep last $label conversations';
  }

  @override
  String get closeMemory => 'Close Memory';

  @override
  String get noContext => 'No context';

  @override
  String keepXRounds(Object n) {
    return 'Keep $n rounds';
  }

  @override
  String lastXRounds(Object n) {
    return 'Last $n rounds';
  }

  @override
  String get defaultMemory => 'Default';

  @override
  String get longConversation => 'Long conversation';

  @override
  String get veryLongConversation => 'Very long conversation';

  @override
  String get noMatchingResults => 'No matching results';

  @override
  String get memoryClosed => 'Memory closed';

  @override
  String memoryConfigSet(Object n) {
    return 'Memory config: $n rounds';
  }

  @override
  String get attach => 'Attachment';

  @override
  String get selectMcpTool => 'Select Connector';

  @override
  String get noMcpTool => 'No Connector';

  @override
  String get viewMcpToolDetail => 'View MCP tool details';

  @override
  String get clickToSelectMcpTool => 'Click to select MCP tool';

  @override
  String get noMcpToolConfigured => 'No MCP tools configured';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return 'Tool workflow: $desc';
  }

  @override
  String get clickToDesignWorkflow =>
      'Set connector and skill joint usage logic';

  @override
  String get alreadySet => 'Set';

  @override
  String get toolWorkflowDescTitle => 'Tool Workflow Description';

  @override
  String get enterToolWorkflowDesc => 'Enter tool workflow description...';

  @override
  String get relationDescCleared => 'Relation description cleared';

  @override
  String get relationDescSaved => 'Relation description saved';

  @override
  String get noMcpServiceConfigured => 'No MCP service configured';

  @override
  String mcpBoundTitle(Object count) {
    return 'Bound MCP ($count)';
  }

  @override
  String mcpServiceList(Object n) {
    return 'MCP Service List ($n)';
  }

  @override
  String get mcpServiceTitle => 'MCP Service';

  @override
  String get enabledStatus => 'Enabled';

  @override
  String get disabledStatus => 'Disabled';

  @override
  String commandLabel(Object cmd) {
    return 'Command: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return 'Args: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return 'Directory: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return 'Timeout: ${n}s';
  }

  @override
  String get mcpListHint =>
      'Tip: Double-click MCP button for list, single-click to toggle';

  @override
  String get mcpEnabledMsg => 'MCP tools enabled, will auto-invoke on send';

  @override
  String get mcpDisabledMsg => 'MCP tools disabled';

  @override
  String get clearMcpService => 'Clear MCP Service';

  @override
  String get unbindAction => 'Unbind';

  @override
  String xTools(Object n) {
    return '$n tools';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'MCP service selected: $name';
  }

  @override
  String get mcpToolsDisabled => 'MCP tools disabled';

  @override
  String get createAction => 'Create';

  @override
  String get noModelBound => 'No model bound';

  @override
  String serviceUnavailable(Object error) {
    return 'Sorry, service temporarily unavailable, $error';
  }

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get clearHistoryConfirmMsg =>
      'Are you sure you want to clear all conversation history? This action cannot be undone.';

  @override
  String get historyCleared => 'History cleared';

  @override
  String folderPath(Object path) {
    return 'Folder: $path';
  }

  @override
  String toolList(Object n) {
    return 'Tool List ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... $n more tools';
  }

  @override
  String get jsonCopied => 'JSON copied';

  @override
  String get mcpDetail => 'MCP Detail';

  @override
  String toolsRefreshed(Object n) {
    return '$n tools refreshed';
  }

  @override
  String refreshFailed(Object error) {
    return 'Refresh failed: $error';
  }

  @override
  String get refreshAction => 'Refresh';

  @override
  String toolsFetched(Object n) {
    return '$n tools fetched';
  }

  @override
  String fetchFailed(Object error) {
    return 'Fetch failed: $error';
  }

  @override
  String get modelConfigNotFound => 'Model configuration not found';

  @override
  String get modelProviderNotConfigured => 'Model provider not configured';

  @override
  String get screenshotFailed => 'Screenshot failed: render object not found';

  @override
  String get generateImageFailed => 'Failed to generate image';

  @override
  String get messageScreenshotCopied =>
      'Message screenshot copied to clipboard';

  @override
  String get currentRoundScreenshotCopied =>
      'Round screenshot copied to clipboard';

  @override
  String get fullConversationScreenshotCopied =>
      'Full conversation screenshot copied to clipboard';

  @override
  String get noMessagesInConversation => 'No messages in conversation';

  @override
  String get cannotFindMessage => 'Cannot find the message';

  @override
  String get cannotFindCompleteRound =>
      'Cannot find complete conversation round';

  @override
  String partialScreenshot(Object n, Object total) {
    return 'Some messages could not be captured, $n/$total messages captured';
  }

  @override
  String get renderObjectStillDrawing =>
      'Screenshot failed: render object still drawing';

  @override
  String screenshotCopied(Object type) {
    return '$type screenshot copied to clipboard';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return '$type screenshot failed: $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return 'Merge screenshot failed: $error';
  }

  @override
  String copyImageFailed(Object error) {
    return 'Copy image failed: $error';
  }

  @override
  String get unsupportedOS => 'Unsupported OS';

  @override
  String desktopCopyFailed(Object error) {
    return 'Desktop copy image failed: $error';
  }

  @override
  String get noClipboardTool =>
      'No clipboard tool available (xclip or wl-copy)';

  @override
  String get cannotFindRenderObject => 'Cannot find message render object';

  @override
  String get cronExpression => 'Cron Expression';

  @override
  String get cronFormat => 'Format: minute hour day month weekday (5 fields)';

  @override
  String get messageContentLabel => 'Message Content';

  @override
  String get enableTask => 'Enable Task';

  @override
  String get pleaseEnterCron => 'Please enter cron expression';

  @override
  String get cronFormatError => 'Cron format error (5 fields required)';

  @override
  String get daily0900 => 'Daily 09:00';

  @override
  String get daily1200 => 'Daily 12:00';

  @override
  String get daily1800 => 'Daily 18:00';

  @override
  String get workday0900 => 'Weekdays 09:00';

  @override
  String get every30min => 'Every 30 min';

  @override
  String get every2h => 'Every 2 hours';

  @override
  String get processFailedStatus => 'Process failed';

  @override
  String get processingStatus => 'Processing';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - Content Preview';
  }

  @override
  String get contentCopiedToClipboard => 'Content copied to clipboard';

  @override
  String get fileProcessFailed => 'File processing failed';

  @override
  String get pleaseReupload => 'Please re-upload the file or contact support';

  @override
  String get processingFileStatus => 'Processing file...';

  @override
  String get imageFile => 'Image file';

  @override
  String get documentFile => 'Document file';

  @override
  String get textFile => 'Text file';

  @override
  String get codeFile => 'Code file';

  @override
  String get officeDocument => 'Office document';

  @override
  String get webLink => 'Web link';

  @override
  String get folderType => 'Folder';

  @override
  String get otherFile => 'Other file';

  @override
  String get defaultConversation => 'General Conversation';

  @override
  String modelCopied(Object name) {
    return 'Model \"$name\" copied successfully';
  }

  @override
  String copyOf(Object name) {
    return '$name copy';
  }

  @override
  String copyOfN(Object n, Object name) {
    return '$name copy ($n)';
  }

  @override
  String get noModels => 'No models';

  @override
  String get clickAddModelHint => 'Click \"Add Model\" button to start';

  @override
  String modelUpdatedNotify(Object name) {
    return 'Model \"$name\" updated, related session settings synchronized';
  }

  @override
  String serviceRemoved(Object name) {
    return 'Service removed: $name';
  }

  @override
  String get connectorManagementTitle => 'Connector Management (MCP)';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get noMcpServices => 'No MCP services';

  @override
  String get clickToEnterMarketplace => 'Click + button to enter marketplace';

  @override
  String fetchToolsFailed(Object error) {
    return 'Fetch tools failed: $error';
  }

  @override
  String get removeServiceLabel => 'Remove Service';

  @override
  String get removeServiceConfirm => 'Are you sure you want to remove service';

  @override
  String get removeServiceWarning => 'Need to re-add after removal';

  @override
  String get jsonConfig => 'JSON Config';

  @override
  String get cannotReadFilePath => 'Cannot read file path';

  @override
  String get extractingImport => 'Extracting import...';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get irreversibleAction => 'This action is irreversible';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'Model Deleted';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'Model \"$name\" successfully deleted';
  }

  @override
  String get selectOtherModelFromList =>
      'Select another model from the list to view details';

  @override
  String get unnamedModel => 'Unnamed Model';

  @override
  String get noDescription => 'No description';

  @override
  String get confirmDeleteModel => 'Are you sure you want to delete the model';

  @override
  String modelDeletedToast(Object name) {
    return 'Model \"$name\" deleted';
  }

  @override
  String get addOnlineModel => 'Add Online Model';

  @override
  String get selectProvider => 'Select Provider';

  @override
  String get configureParams => 'Configure Parameters';

  @override
  String get checkConfig => 'Check Configuration';

  @override
  String get setName => 'Set Name';

  @override
  String get nextStep => 'Next';

  @override
  String get selectOnlineProvider => 'Select Online Model Provider';

  @override
  String get customProvider => 'Custom';

  @override
  String get customProviderDesc =>
      'Manually enter address, API key and model name';

  @override
  String get customProviderConfigTitle => 'Custom Model Configuration';

  @override
  String configureProviderParams(Object provider) {
    return 'Configure $provider Parameters';
  }

  @override
  String get ollamaApiKeyOptional =>
      'Local Ollama service usually doesn\'t require an API key, can leave empty';

  @override
  String get apiAddress => 'API Address';

  @override
  String get defaultApiUrlNote =>
      'Default official API address, can be modified for local or private deployments';

  @override
  String get presetModel => 'Preset Models';

  @override
  String get customModel => 'Custom Model';

  @override
  String get enterFullModelName =>
      'Enter the full model name supported by the provider';

  @override
  String get ollamaRunningModels => 'Ollama Running Models';

  @override
  String get refreshModelList => 'Refresh model list';

  @override
  String get ollamaStartHint =>
      'Please start Ollama service and download models first\nthen click refresh to get the model list';

  @override
  String get modelscopeAvailableModels => 'ModelScope Available Models';

  @override
  String get modelscopeApiKeyHint =>
      'Please ensure API key is correct\nthen click refresh to get the model list';

  @override
  String get setModelName => 'Set Model Name';

  @override
  String get configSummary => 'Configuration Summary';

  @override
  String get providerLabel => 'Provider';

  @override
  String get platformLabel => 'Platform';

  @override
  String get notSet => 'Not set';

  @override
  String get modelLabel => 'Model';

  @override
  String get customSuffix => '(Custom)';

  @override
  String get notSelected => 'Not selected';

  @override
  String get customModelName => 'Custom Model Name';

  @override
  String enterModelNameHint(Object provider) {
    return 'Enter model name, e.g. $provider-Chat';
  }

  @override
  String get modelNameSuggestion =>
      'Use a meaningful name for easy identification';

  @override
  String get testConnectionDesc => 'Test model connection and response';

  @override
  String get waitingForResponse => 'Waiting for response...';

  @override
  String get configIncomplete => 'Configuration incomplete';

  @override
  String get receivedEmptyResponse => 'Received empty response';

  @override
  String get receivedNoResponse => 'No response received';

  @override
  String connectionFailed(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String get contextCap => 'Context';

  @override
  String get thinkingCap => 'Thinking';

  @override
  String get builtinToolsCap => 'Built-in Tools';

  @override
  String get structuredCap => 'Structured';

  @override
  String get batchCap => 'Batch';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get modelParams => 'Model Settings';

  @override
  String get unknown => 'Unknown';

  @override
  String get nameLabel => 'Name';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get notSetDoubleClickToEdit => 'Not set (double-click to edit)';

  @override
  String get apiKeySaved => 'API key saved';

  @override
  String get modelNameCannotBeEmpty => 'Model name cannot be empty';

  @override
  String get modelNameSaved => 'Model name saved';

  @override
  String get modelSaved => 'Model saved';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get precise => 'Precise';

  @override
  String get neutral => 'Neutral';

  @override
  String get creative => 'Creative';

  @override
  String get temperatureDescription =>
      'Controls response randomness and creativity. Lower values are more conservative, higher values more creative.';

  @override
  String get modelRoleSetting => 'Model Role Setting';

  @override
  String get presetRole => 'Preset Role';

  @override
  String get roleSettingDescription =>
      'The role setting is sent to the model at the start of each conversation to define the role and behavior. Adjust according to the role you want the model to play.';

  @override
  String get selectPresetRole => 'Select Preset Role';

  @override
  String get generalAssistant => 'General Assistant';

  @override
  String get friendlyAssistantDesc => 'Friendly, professional AI assistant';

  @override
  String get spellCheck => 'Spell Check';

  @override
  String get spellCheckDesc => 'Spell check expert';

  @override
  String get codeExpert => 'Code Expert';

  @override
  String get codeExpertDesc =>
      'Technical expert in programming and development';

  @override
  String get legalExpert => 'Legal Expert';

  @override
  String get legalExpertDesc => 'Professional legal advisor';

  @override
  String get copywriter => 'Copywriter';

  @override
  String get copywriterDesc =>
      'Creative copywriting and content creation expert';

  @override
  String get dataAnalyst => 'Data Analyst';

  @override
  String get dataAnalystDesc => 'Data analysis and statistics expert';

  @override
  String get educationTutor => 'Education Tutor';

  @override
  String get educationTutorDesc => 'Patient teaching expert';

  @override
  String get businessConsultant => 'Business Consultant';

  @override
  String get businessConsultantDesc =>
      'Business management and strategy expert';

  @override
  String get psychologist => 'Psychologist';

  @override
  String get psychologistDesc => 'Professional mental health consultant';

  @override
  String get versionLabel => 'Version';

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
  String get domainSettings => 'Domain Settings';

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
  String get domainAddress => 'Domain Address';

  @override
  String get domainHint => 'e.g. api.example.com';

  @override
  String get domainDesc =>
      'After setting, the session service URL will use this address. HTTP default port 80, HTTPS default port 443.';

  @override
  String get portSettings => 'Port Settings';

  @override
  String get httpPort => 'HTTP Port';

  @override
  String get httpsPort => 'HTTPS Port';

  @override
  String get portDesc =>
      'HTTP listening port, default 80. HTTPS listening port, default 443. Restart the service to apply changes.';

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
      'After configuring the service address, the session service URL will display this address. External clients can access the session API (/chat/completions etc.) through this address.';

  @override
  String get pleaseEnterDomain => 'Please enter service address';

  @override
  String get domainSaved => 'Service configuration saved';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get cny => 'CNY';

  @override
  String get usd => 'USD';

  @override
  String get loadingPageSubtitle => 'Intelligent Enterprise AI Workspace';

  @override
  String get billingSettings => 'Billing';

  @override
  String get mcpSettings => 'MCP Settings';

  @override
  String get currencyTypeLabel => 'Currency Type';

  @override
  String get inputPriceLabel => 'Input Price';

  @override
  String get outputPriceLabel => 'Output Price';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/M Tokens';
  }

  @override
  String priceUnitDescription(Object unit) {
    return 'Price: $unit/Million Tokens. Used for cumulative session cost calculation.';
  }

  @override
  String get examplePriceHint => 'e.g. 0.14';

  @override
  String get mcpBindingDescription =>
      'After binding MCP services to the model, sessions using this model will automatically inject these MCP tools. Session MCP and model MCP will automatically merge and deduplicate.';

  @override
  String get addMcpServiceButton => 'Add MCP Service';

  @override
  String get clearAllMcpBindings => 'Clear All MCP Bindings';

  @override
  String get selectMcpServiceMultiSelect => 'Select MCP Service (Multi-select)';

  @override
  String get noMcpServiceAddFirst =>
      'No MCP services, please add in MCP Management first';

  @override
  String confirmWithCount(Object count) {
    return 'OK ($count)';
  }

  @override
  String get temperaturePrecise => 'Precise';

  @override
  String get temperatureConservative => 'Conservative';

  @override
  String get temperatureNeutral => 'Neutral';

  @override
  String get temperatureCreative => 'Creative';

  @override
  String get temperatureRandom => 'Random';

  @override
  String xToolsCount(Object n) {
    return '$n tools';
  }

  @override
  String get newConversationDefault => 'New Conversation';

  @override
  String get usageDashboard => 'Usage Dashboard';

  @override
  String get globalUsageDashboard => 'Global Usage Dashboard';

  @override
  String sessionUsageTitle(Object name) {
    return '$name Usage';
  }

  @override
  String get noSessionData => 'No session data';

  @override
  String get noUsageData => 'No usage data';

  @override
  String get overview => 'Overview';

  @override
  String get statMessages => 'Messages';

  @override
  String get totalMessages => 'Total Messages';

  @override
  String get inputTokens => 'Input Tokens';

  @override
  String get outputTokens => 'Output Tokens';

  @override
  String get totalCostLabel => 'Total Cost';

  @override
  String get tokenDistribution => 'Token Distribution';

  @override
  String get modelInfo => 'Model Info';

  @override
  String get quotaLimitSection => 'Quota Limit';

  @override
  String get usageCurve => 'Usage Curve';

  @override
  String get totalSessions => 'Total Sessions';

  @override
  String get totalTokens => 'Total Tokens';

  @override
  String get byModel => 'By Model';

  @override
  String get allSessions => 'All Sessions';

  @override
  String moreSessionsNoData(Object count) {
    return 'Another $count sessions have no usage data';
  }

  @override
  String get inputLabel => 'Input';

  @override
  String get outputLabel => 'Output';

  @override
  String get noQuotaLimit => 'No quota limit set';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count sessions';
  }

  @override
  String get granMinute => 'Minute';

  @override
  String get granHour => 'Hour';

  @override
  String get granDay => 'Day';

  @override
  String get granMonth => 'Month';

  @override
  String get granYear => 'Year';

  @override
  String get selectDate => 'Select date';

  @override
  String get rangeStart => 'Start';

  @override
  String get rangeEnd => 'End';

  @override
  String get startDateHelp => 'Start date';

  @override
  String get endDateHelp => 'End date';

  @override
  String get tokenToggle => 'Token';

  @override
  String get costToggle => 'Cost';

  @override
  String chartLegendCost(Object symbol) {
    return 'Cost ($symbol)';
  }

  @override
  String get noSessionConfig => 'No session configuration';

  @override
  String get resetApiKey => 'Reset API Key';

  @override
  String get resetApiKeyConfirm =>
      'Reset this session\'s API key? After resetting, the old key will be invalid immediately and external requests using the old key will be unable to access.';

  @override
  String get confirmReset => 'Confirm Reset';

  @override
  String get connectorSkillRelation =>
      'Connector and skill relation description';

  @override
  String modelPricing(Object unit) {
    return 'Model Pricing ($unit/M Tokens)';
  }

  @override
  String get billingInfoLabel => 'Billing Info';

  @override
  String get cumulativeInputTokens => 'Cumulative Input Tokens';

  @override
  String get cumulativeOutputTokens => 'Cumulative Output Tokens';

  @override
  String get cumulativeCost => 'Cumulative Cost';

  @override
  String get basicInfoLabel => 'Basic Info';

  @override
  String get sessionName => 'Session Name';

  @override
  String get organization => 'Organization';

  @override
  String get groupLabel => 'Group';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get notGrouped => 'Ungrouped';

  @override
  String get boundModel => 'Bound Model';

  @override
  String get relatedPrompt => 'Related Prompt';

  @override
  String get messageCountLabel => 'Message Count';

  @override
  String get serviceConfigLabel => 'Service Config';

  @override
  String get serviceAddress => 'Service Address';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => 'Model MCP';

  @override
  String get sessionMcp => 'Session MCP';

  @override
  String get notBound => 'Not bound';

  @override
  String get addMcpHint =>
      'You can add MCP services in Model Management or the chat input box';

  @override
  String get usageQuotaLabel => 'Usage Quota';

  @override
  String get noAuthAccess => 'No-auth Access';

  @override
  String get noAuthEnabledDesc => '⚠️ Auth disabled, anyone can access';

  @override
  String get noAuthDisabledDesc => 'Enabled: access without API Key';

  @override
  String get disableSession => 'Disable Session';

  @override
  String get disabledEnabledDesc => '⚠️ Disabled, calls will return error';

  @override
  String get disabledDisabledDesc =>
      'Enabled: this session will not be callable';

  @override
  String get systemPromptHint =>
      'Set the role/behavior for this session, e.g. you are a professional legal advisor...';

  @override
  String get systemPromptDesc =>
      'Set as the highest-priority instruction, auto-injected for third-party requests. Leave empty to not inject.';

  @override
  String get tokenUsageLimit => 'Token Usage Limit';

  @override
  String costBudgetLimit(Object unit) {
    return 'Cost Budget Limit ($unit)';
  }

  @override
  String get requestLimit => 'Request Limit';

  @override
  String get noLimit => 'No limit';

  @override
  String get enableUsageLimit => 'Enable Usage Limit';

  @override
  String get reachLimitReject =>
      'New requests will be rejected after the limit is reached';

  @override
  String get resetPeriod => 'Reset Period';

  @override
  String get resetPeriodNever => 'No auto reset';

  @override
  String get resetPeriodDaily => 'Reset daily';

  @override
  String get resetPeriodMonthly => 'Reset monthly';

  @override
  String get quotaExhausted => 'Quota Exhausted';

  @override
  String get currentUsageStatus => 'Current Usage Status';

  @override
  String get quotaTokenLabel => 'Token';

  @override
  String get quotaCostLabel => 'Cost';

  @override
  String get quotaRequestLabel => 'Requests';

  @override
  String get manualResetUsage => 'Manual Reset Usage';

  @override
  String get manualResetConfirmDesc => 'Determine to manually reset';

  @override
  String get manualResetWarning =>
      'After reset, the current period\'s Token usage, cost, and request count will be cleared, and the period start time will be updated to the current time.';

  @override
  String get tokenUsage => 'Token Usage';

  @override
  String get costUsage => 'Cost Usage';

  @override
  String get resetValue => 'Reset';

  @override
  String get apiKeyReset => 'API key reset';

  @override
  String get securitySettings => 'Security';

  @override
  String get sensitiveInfoMasking => 'Sensitive Info Masking';

  @override
  String get sensitiveInfoMaskingDesc =>
      'When enabled, the corresponding information in messages sent to the model and in local audit logs will be replaced with \'*\' to prevent plaintext privacy leaks.';

  @override
  String get maskPhoneTitle => 'Mask Phone Numbers';

  @override
  String get maskPhoneSubtitle =>
      'Replace phone numbers in messages with \'*\'';

  @override
  String get maskIdCardTitle => 'Mask ID Card Numbers';

  @override
  String get maskIdCardSubtitle =>
      'Replace ID card numbers in messages with \'*\'';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get modelDetails => 'Model Details';

  @override
  String modelDetailsWithPlatform(String platform) {
    return 'Model Details · $platform';
  }

  @override
  String get japanese => '日本語';

  @override
  String get japaneseDesc => 'Japanese';

  @override
  String get korean => '한국어';

  @override
  String get koreanDesc => 'Korean';

  @override
  String get thai => 'ไทย';

  @override
  String get thaiDesc => 'Thai';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get vietnameseDesc => 'Vietnamese';

  @override
  String get french => 'Français';

  @override
  String get frenchDesc => 'French';

  @override
  String get german => 'Deutsch';

  @override
  String get germanDesc => 'German';
}
