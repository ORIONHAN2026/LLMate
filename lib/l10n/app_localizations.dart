import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChatHub'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Smart Chat Assistant'**
  String get appSlogan;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @modelManagement.
  ///
  /// In en, this message translates to:
  /// **'Model Management'**
  String get modelManagement;

  /// No description provided for @connectorManagement.
  ///
  /// In en, this message translates to:
  /// **'Connector (MCP)'**
  String get connectorManagement;

  /// No description provided for @skillManagement.
  ///
  /// In en, this message translates to:
  /// **'Skill (SKILL)'**
  String get skillManagement;

  /// No description provided for @otherSettings.
  ///
  /// In en, this message translates to:
  /// **'Other Settings'**
  String get otherSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @skinSettings.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get skinSettings;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @followSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto switch light/dark mode'**
  String get followSystemDesc;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @lightModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get lightModeDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get darkModeDesc;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @chineseDesc.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get chineseDesc;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @englishDesc.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishDesc;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy Content'**
  String get copyContent;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousStep;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPrompt;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @replyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Reply Language'**
  String get replyLanguage;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get newSession;

  /// No description provided for @sessionList.
  ///
  /// In en, this message translates to:
  /// **'Session List'**
  String get sessionList;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @shareConversation.
  ///
  /// In en, this message translates to:
  /// **'Share Conversation'**
  String get shareConversation;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation'**
  String get clearConversation;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirm;

  /// No description provided for @deleteConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get deleteConfirmMsg;

  /// No description provided for @removeConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\"?'**
  String removeConfirmMsg(Object name);

  /// No description provided for @addModel.
  ///
  /// In en, this message translates to:
  /// **'Add Model'**
  String get addModel;

  /// No description provided for @copyModel.
  ///
  /// In en, this message translates to:
  /// **'Copy Model'**
  String get copyModel;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// No description provided for @modelProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get modelProvider;

  /// No description provided for @modelApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get modelApiKey;

  /// No description provided for @modelBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get modelBaseUrl;

  /// No description provided for @modelMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get modelMaxTokens;

  /// No description provided for @thinkTag.
  ///
  /// In en, this message translates to:
  /// **'Think Tag'**
  String get thinkTag;

  /// No description provided for @thinkTagDesc.
  ///
  /// In en, this message translates to:
  /// **'Thought process tag for the model'**
  String get thinkTagDesc;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @removeService.
  ///
  /// In en, this message translates to:
  /// **'Remove Service'**
  String get removeService;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @fullTest.
  ///
  /// In en, this message translates to:
  /// **'Full Test'**
  String get fullTest;

  /// No description provided for @connectAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Connect & Add'**
  String get connectAndAdd;

  /// No description provided for @addCustomConnector.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Connector'**
  String get addCustomConnector;

  /// No description provided for @clearKey.
  ///
  /// In en, this message translates to:
  /// **'Clear Key'**
  String get clearKey;

  /// No description provided for @installSkill.
  ///
  /// In en, this message translates to:
  /// **'Install Skill'**
  String get installSkill;

  /// No description provided for @uninstallSkill.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Skill'**
  String get uninstallSkill;

  /// No description provided for @deleteSkill.
  ///
  /// In en, this message translates to:
  /// **'Delete Skill'**
  String get deleteSkill;

  /// No description provided for @fetchTools.
  ///
  /// In en, this message translates to:
  /// **'Fetch Tools'**
  String get fetchTools;

  /// No description provided for @fetchModels.
  ///
  /// In en, this message translates to:
  /// **'Fetch Models'**
  String get fetchModels;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @regenerateFromHere.
  ///
  /// In en, this message translates to:
  /// **'Regenerate From Here'**
  String get regenerateFromHere;

  /// No description provided for @regenerateLastReply.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Last Reply'**
  String get regenerateLastReply;

  /// No description provided for @regenerateThisReply.
  ///
  /// In en, this message translates to:
  /// **'Regenerate This Reply'**
  String get regenerateThisReply;

  /// No description provided for @createNewChatFromHere.
  ///
  /// In en, this message translates to:
  /// **'New Chat From Here'**
  String get createNewChatFromHere;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @deleteReply.
  ///
  /// In en, this message translates to:
  /// **'Delete Reply'**
  String get deleteReply;

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @entireConversation.
  ///
  /// In en, this message translates to:
  /// **'Entire Conversation'**
  String get entireConversation;

  /// No description provided for @currentRound.
  ///
  /// In en, this message translates to:
  /// **'Current Round'**
  String get currentRound;

  /// No description provided for @currentMessage.
  ///
  /// In en, this message translates to:
  /// **'Current Message'**
  String get currentMessage;

  /// No description provided for @memoryConfig.
  ///
  /// In en, this message translates to:
  /// **'Memory Config'**
  String get memoryConfig;

  /// No description provided for @clearMcpServices.
  ///
  /// In en, this message translates to:
  /// **'Clear MCP Services'**
  String get clearMcpServices;

  /// No description provided for @clearSkillSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Skill Selection'**
  String get clearSkillSelection;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @selectWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Select Working Directory'**
  String get selectWorkingDir;

  /// No description provided for @skillMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Skill Marketplace'**
  String get skillMarketplace;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSessionTitle;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @removeServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Service'**
  String get removeServiceTitle;

  /// No description provided for @deleteSkillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Skill'**
  String get deleteSkillTitle;

  /// No description provided for @removeMcpServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove MCP Service'**
  String get removeMcpServiceTitle;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession;

  /// No description provided for @presetRoleApplied.
  ///
  /// In en, this message translates to:
  /// **'Preset role applied'**
  String get presetRoleApplied;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @fileOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get fileOpenFailed;

  /// No description provided for @enterMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter message content'**
  String get enterMessageContent;

  /// No description provided for @copyMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Copy Message Content'**
  String get copyMessageContent;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get apiKeyHint;

  /// No description provided for @modelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model name'**
  String get modelNameHint;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter message content...'**
  String get messageHint;

  /// No description provided for @apiUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API URL'**
  String get apiUrlHint;

  /// No description provided for @commandHint.
  ///
  /// In en, this message translates to:
  /// **'Enter command content'**
  String get commandHint;

  /// No description provided for @enterCommandContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter command content'**
  String get enterCommandContent;

  /// No description provided for @modelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model name, e.g. gpt-4o-mini, claude-3-haiku'**
  String get modelSearchHint;

  /// No description provided for @roleDescHint.
  ///
  /// In en, this message translates to:
  /// **'Enter role description to guide the model\'s behavior and response style...'**
  String get roleDescHint;

  /// No description provided for @toolLogicHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the tool logic description...'**
  String get toolLogicHint;

  /// No description provided for @typeCommandOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Type command or search...'**
  String get typeCommandOrSearch;

  /// No description provided for @searchSkills.
  ///
  /// In en, this message translates to:
  /// **'Search skills...'**
  String get searchSkills;

  /// No description provided for @searchMcp.
  ///
  /// In en, this message translates to:
  /// **'Search MCP services...'**
  String get searchMcp;

  /// No description provided for @scheduledMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Scheduled message content...'**
  String get scheduledMessageHint;

  /// No description provided for @cronExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0 9 * * * (daily at 9:00)'**
  String get cronExample;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get config;

  /// No description provided for @pasteMcpCode.
  ///
  /// In en, this message translates to:
  /// **'Paste MCP code'**
  String get pasteMcpCode;

  /// No description provided for @fileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get fileNameLabel;

  /// No description provided for @fileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSizeLabel;

  /// No description provided for @fileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fileTypeLabel;

  /// No description provided for @filePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get filePathLabel;

  /// No description provided for @aliyun.
  ///
  /// In en, this message translates to:
  /// **'Alibaba Cloud'**
  String get aliyun;

  /// No description provided for @tencentCloud.
  ///
  /// In en, this message translates to:
  /// **'Tencent Cloud'**
  String get tencentCloud;

  /// No description provided for @modelscope.
  ///
  /// In en, this message translates to:
  /// **'ModelScope'**
  String get modelscope;

  /// No description provided for @goToAliyun.
  ///
  /// In en, this message translates to:
  /// **'Go to Alibaba Cloud'**
  String get goToAliyun;

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String pleaseEnter(Object field);

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get copyFailed;

  /// No description provided for @invalidLinkFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid link format'**
  String get invalidLinkFormat;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link'**
  String get cannotOpenLink;

  /// No description provided for @linkOpenedInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Link opened in browser'**
  String get linkOpenedInBrowser;

  /// No description provided for @cannotOpenThisLinkType.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this link type'**
  String get cannotOpenThisLinkType;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Open link failed'**
  String get openLinkFailed;

  /// No description provided for @fileOpened.
  ///
  /// In en, this message translates to:
  /// **'File opened'**
  String get fileOpened;

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file'**
  String get cannotOpenFile;

  /// No description provided for @openFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Open file failed'**
  String get openFileFailed;

  /// No description provided for @sessionNotFoundForMessage.
  ///
  /// In en, this message translates to:
  /// **'Session not found for this message'**
  String get sessionNotFoundForMessage;

  /// No description provided for @messageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get messageNotFound;

  /// No description provided for @regenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Regeneration failed'**
  String get regenerateFailed;

  /// No description provided for @cannotFindQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cannot find the corresponding question'**
  String get cannotFindQuestion;

  /// No description provided for @noAiReplyFound.
  ///
  /// In en, this message translates to:
  /// **'No AI reply found'**
  String get noAiReplyFound;

  /// No description provided for @cannotRegenerateInvalidIndex.
  ///
  /// In en, this message translates to:
  /// **'Cannot regenerate: invalid message index'**
  String get cannotRegenerateInvalidIndex;

  /// No description provided for @editMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessageTitle;

  /// No description provided for @messageContentCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Message content cannot be empty'**
  String get messageContentCannotBeEmpty;

  /// No description provided for @newChatFromHistory.
  ///
  /// In en, this message translates to:
  /// **'New chat from history'**
  String get newChatFromHistory;

  /// No description provided for @newChatCreatedFromHere.
  ///
  /// In en, this message translates to:
  /// **'New chat created from here'**
  String get newChatCreatedFromHere;

  /// No description provided for @createNewChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create new chat'**
  String get createNewChatFailed;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get thinking;

  /// No description provided for @callingTool.
  ///
  /// In en, this message translates to:
  /// **'Calling tool'**
  String get callingTool;

  /// No description provided for @toolCallRecord.
  ///
  /// In en, this message translates to:
  /// **'Tool call record'**
  String get toolCallRecord;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deleteMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message'**
  String get deleteMessageFailed;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @outputTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Output tokens'**
  String get outputTokensLabel;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand Sidebar'**
  String get expandSidebar;

  /// No description provided for @collapseRightSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Right Sidebar'**
  String get collapseRightSidebar;

  /// No description provided for @expandRightSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand Right Sidebar'**
  String get expandRightSidebar;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @favoriteSession.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteSession;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @noMemory.
  ///
  /// In en, this message translates to:
  /// **'No memory'**
  String get noMemory;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get fileInfo;

  /// No description provided for @fileContent.
  ///
  /// In en, this message translates to:
  /// **'File Content'**
  String get fileContent;

  /// No description provided for @noContentPreview.
  ///
  /// In en, this message translates to:
  /// **'No content preview'**
  String get noContentPreview;

  /// No description provided for @fileContentCopied.
  ///
  /// In en, this message translates to:
  /// **'File content copied to clipboard'**
  String get fileContentCopied;

  /// No description provided for @selectOrCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Please select or create a session'**
  String get selectOrCreateSession;

  /// No description provided for @invalidSessionIndex.
  ///
  /// In en, this message translates to:
  /// **'Invalid session index'**
  String get invalidSessionIndex;

  /// No description provided for @cannotOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Cannot open email app'**
  String get cannotOpenEmailApp;

  /// No description provided for @sendEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send email'**
  String get sendEmailFailed;

  /// No description provided for @memorySummary.
  ///
  /// In en, this message translates to:
  /// **'Memory Summary'**
  String get memorySummary;

  /// No description provided for @recentConversations.
  ///
  /// In en, this message translates to:
  /// **'Recent Conversations'**
  String get recentConversations;

  /// No description provided for @sessionFiles.
  ///
  /// In en, this message translates to:
  /// **'Session Files'**
  String get sessionFiles;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @todayTime.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayTime(Object time);

  /// No description provided for @monthDayTime.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day} {time}'**
  String monthDayTime(Object day, Object month, Object time);

  /// No description provided for @messageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String messageCount(Object count);

  /// No description provided for @xFailed.
  ///
  /// In en, this message translates to:
  /// **'{action} failed: {error}'**
  String xFailed(Object action, Object error);

  /// No description provided for @xDone.
  ///
  /// In en, this message translates to:
  /// **'{action} completed'**
  String xDone(Object action);

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @replyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Replies deleted'**
  String get replyDeleted;

  /// No description provided for @deleteReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete replies'**
  String get deleteReplyFailed;

  /// No description provided for @asConversationContinues.
  ///
  /// In en, this message translates to:
  /// **'As the conversation continues, AI will\nautomatically record and compress memory'**
  String get asConversationContinues;

  /// No description provided for @whenAiCreatesFiles.
  ///
  /// In en, this message translates to:
  /// **'When AI tools create or modify\nfiles in conversation, they will appear here'**
  String get whenAiCreatesFiles;

  /// No description provided for @deleteSessionTitle_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteSessionTitle_warning;

  /// No description provided for @pleaseSetupModel.
  ///
  /// In en, this message translates to:
  /// **'Please set up a model'**
  String get pleaseSetupModel;

  /// No description provided for @clickToSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Click above to select a chat model'**
  String get clickToSelectModel;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get selectModel;

  /// No description provided for @noAvailableModels.
  ///
  /// In en, this message translates to:
  /// **'No available models'**
  String get noAvailableModels;

  /// No description provided for @sessionNotFoundCannotSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Session not found, cannot select model'**
  String get sessionNotFoundCannotSelectModel;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Type message here, ↵ to send, Shift+↵ for new line'**
  String get inputHint;

  /// No description provided for @stopAnswer.
  ///
  /// In en, this message translates to:
  /// **'Stop answering'**
  String get stopAnswer;

  /// No description provided for @waitingAttachments.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {count} attachments to process'**
  String waitingAttachments(Object count);

  /// No description provided for @sendMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessageAction;

  /// No description provided for @deepThinkEnabled.
  ///
  /// In en, this message translates to:
  /// **'Deep Think: On'**
  String get deepThinkEnabled;

  /// No description provided for @deepThinkDisabled.
  ///
  /// In en, this message translates to:
  /// **'Deep Think: Off'**
  String get deepThinkDisabled;

  /// No description provided for @deepThink.
  ///
  /// In en, this message translates to:
  /// **'Deep Think'**
  String get deepThink;

  /// No description provided for @workingDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Directory'**
  String get workingDirectoryLabel;

  /// No description provided for @workingDirectoryPath.
  ///
  /// In en, this message translates to:
  /// **'Working Directory: {path}'**
  String workingDirectoryPath(Object path);

  /// No description provided for @setWorkingDirHint.
  ///
  /// In en, this message translates to:
  /// **'Set working directory (default save location)'**
  String get setWorkingDirHint;

  /// No description provided for @workingDirSet.
  ///
  /// In en, this message translates to:
  /// **'Working directory set'**
  String get workingDirSet;

  /// No description provided for @workingDirCleared.
  ///
  /// In en, this message translates to:
  /// **'Working directory cleared'**
  String get workingDirCleared;

  /// No description provided for @nRounds.
  ///
  /// In en, this message translates to:
  /// **'{n} rounds'**
  String nRounds(Object n);

  /// No description provided for @memoryConfigTooltip.
  ///
  /// In en, this message translates to:
  /// **'Memory config: Keep last {label} conversations'**
  String memoryConfigTooltip(Object label);

  /// No description provided for @closeMemory.
  ///
  /// In en, this message translates to:
  /// **'Close Memory'**
  String get closeMemory;

  /// No description provided for @noContext.
  ///
  /// In en, this message translates to:
  /// **'No context'**
  String get noContext;

  /// No description provided for @keepXRounds.
  ///
  /// In en, this message translates to:
  /// **'Keep {n} rounds'**
  String keepXRounds(Object n);

  /// No description provided for @lastXRounds.
  ///
  /// In en, this message translates to:
  /// **'Last {n} rounds'**
  String lastXRounds(Object n);

  /// No description provided for @defaultMemory.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultMemory;

  /// No description provided for @longConversation.
  ///
  /// In en, this message translates to:
  /// **'Long conversation'**
  String get longConversation;

  /// No description provided for @veryLongConversation.
  ///
  /// In en, this message translates to:
  /// **'Very long conversation'**
  String get veryLongConversation;

  /// No description provided for @noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get noMatchingResults;

  /// No description provided for @memoryClosed.
  ///
  /// In en, this message translates to:
  /// **'Memory closed'**
  String get memoryClosed;

  /// No description provided for @memoryConfigSet.
  ///
  /// In en, this message translates to:
  /// **'Memory config: {n} rounds'**
  String memoryConfigSet(Object n);

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attach;

  /// No description provided for @selectMcpTool.
  ///
  /// In en, this message translates to:
  /// **'Select MCP'**
  String get selectMcpTool;

  /// No description provided for @noMcpTool.
  ///
  /// In en, this message translates to:
  /// **'No MCP'**
  String get noMcpTool;

  /// No description provided for @viewMcpToolDetail.
  ///
  /// In en, this message translates to:
  /// **'View MCP tool details'**
  String get viewMcpToolDetail;

  /// No description provided for @clickToSelectMcpTool.
  ///
  /// In en, this message translates to:
  /// **'Click to select MCP tool'**
  String get clickToSelectMcpTool;

  /// No description provided for @noMcpToolConfigured.
  ///
  /// In en, this message translates to:
  /// **'No MCP tools configured'**
  String get noMcpToolConfigured;

  /// No description provided for @toolWorkflowDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool workflow: {desc}'**
  String toolWorkflowDescLabel(Object desc);

  /// No description provided for @clickToDesignWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Click to design tool workflow description'**
  String get clickToDesignWorkflow;

  /// No description provided for @needMcpOrSkillFirst.
  ///
  /// In en, this message translates to:
  /// **'Need to select MCP tool or skill first'**
  String get needMcpOrSkillFirst;

  /// No description provided for @alreadySet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get alreadySet;

  /// No description provided for @toolWorkflowDescTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool Workflow Description'**
  String get toolWorkflowDescTitle;

  /// No description provided for @enterToolWorkflowDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter tool workflow description...'**
  String get enterToolWorkflowDesc;

  /// No description provided for @relationDescCleared.
  ///
  /// In en, this message translates to:
  /// **'Relation description cleared'**
  String get relationDescCleared;

  /// No description provided for @relationDescSaved.
  ///
  /// In en, this message translates to:
  /// **'Relation description saved'**
  String get relationDescSaved;

  /// No description provided for @noMcpServiceConfigured.
  ///
  /// In en, this message translates to:
  /// **'No MCP service configured'**
  String get noMcpServiceConfigured;

  /// No description provided for @mcpServiceList.
  ///
  /// In en, this message translates to:
  /// **'MCP Service List ({n})'**
  String mcpServiceList(Object n);

  /// No description provided for @mcpServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP Service'**
  String get mcpServiceTitle;

  /// No description provided for @enabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledStatus;

  /// No description provided for @disabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledStatus;

  /// No description provided for @commandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command: {cmd}'**
  String commandLabel(Object cmd);

  /// No description provided for @argsLabel.
  ///
  /// In en, this message translates to:
  /// **'Args: {args}'**
  String argsLabel(Object args);

  /// No description provided for @workingDirLabel.
  ///
  /// In en, this message translates to:
  /// **'Directory: {dir}'**
  String workingDirLabel(Object dir);

  /// No description provided for @timeoutSec.
  ///
  /// In en, this message translates to:
  /// **'Timeout: {n}s'**
  String timeoutSec(Object n);

  /// No description provided for @mcpListHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: Double-click MCP button for list, single-click to toggle'**
  String get mcpListHint;

  /// No description provided for @mcpEnabledMsg.
  ///
  /// In en, this message translates to:
  /// **'MCP tools enabled, will auto-invoke on send'**
  String get mcpEnabledMsg;

  /// No description provided for @mcpDisabledMsg.
  ///
  /// In en, this message translates to:
  /// **'MCP tools disabled'**
  String get mcpDisabledMsg;

  /// No description provided for @clearMcpService.
  ///
  /// In en, this message translates to:
  /// **'Clear MCP Service'**
  String get clearMcpService;

  /// No description provided for @unbindAction.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get unbindAction;

  /// No description provided for @xTools.
  ///
  /// In en, this message translates to:
  /// **'{n} tools'**
  String xTools(Object n);

  /// No description provided for @mcpServiceSelected.
  ///
  /// In en, this message translates to:
  /// **'MCP service selected: {name}'**
  String mcpServiceSelected(Object name);

  /// No description provided for @mcpToolsDisabled.
  ///
  /// In en, this message translates to:
  /// **'MCP tools disabled'**
  String get mcpToolsDisabled;

  /// No description provided for @selectSkill.
  ///
  /// In en, this message translates to:
  /// **'Select Skill'**
  String get selectSkill;

  /// No description provided for @noAvailableSkill.
  ///
  /// In en, this message translates to:
  /// **'No available skills'**
  String get noAvailableSkill;

  /// No description provided for @currentSkill.
  ///
  /// In en, this message translates to:
  /// **'Current Skill: {name}'**
  String currentSkill(Object name);

  /// No description provided for @clickToSelectSkill.
  ///
  /// In en, this message translates to:
  /// **'Click to select skill'**
  String get clickToSelectSkill;

  /// No description provided for @noSelectableSkill.
  ///
  /// In en, this message translates to:
  /// **'No selectable skills'**
  String get noSelectableSkill;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @skillCreatedSelected.
  ///
  /// In en, this message translates to:
  /// **'Skill \"{name}\" created and selected'**
  String skillCreatedSelected(Object name);

  /// No description provided for @createSkillFailed.
  ///
  /// In en, this message translates to:
  /// **'Create skill failed: {error}'**
  String createSkillFailed(Object error);

  /// No description provided for @skillSelected.
  ///
  /// In en, this message translates to:
  /// **'Skill selected: {name}'**
  String skillSelected(Object name);

  /// No description provided for @skillCleared.
  ///
  /// In en, this message translates to:
  /// **'Skill selection cleared'**
  String get skillCleared;

  /// No description provided for @noModelBound.
  ///
  /// In en, this message translates to:
  /// **'No model bound'**
  String get noModelBound;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sorry, service temporarily unavailable, {error}'**
  String serviceUnavailable(Object error);

  /// No description provided for @confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get confirmClear;

  /// No description provided for @clearHistoryConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all conversation history? This action cannot be undone.'**
  String get clearHistoryConfirmMsg;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @skillDetail.
  ///
  /// In en, this message translates to:
  /// **'Skill Detail'**
  String get skillDetail;

  /// No description provided for @folderPath.
  ///
  /// In en, this message translates to:
  /// **'Folder: {path}'**
  String folderPath(Object path);

  /// No description provided for @toolList.
  ///
  /// In en, this message translates to:
  /// **'Tool List ({n})'**
  String toolList(Object n);

  /// No description provided for @moreXTools.
  ///
  /// In en, this message translates to:
  /// **'... {n} more tools'**
  String moreXTools(Object n);

  /// No description provided for @jsonCopied.
  ///
  /// In en, this message translates to:
  /// **'JSON copied'**
  String get jsonCopied;

  /// No description provided for @mcpDetail.
  ///
  /// In en, this message translates to:
  /// **'MCP Detail'**
  String get mcpDetail;

  /// No description provided for @toolsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'{n} tools refreshed'**
  String toolsRefreshed(Object n);

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {error}'**
  String refreshFailed(Object error);

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @toolsFetched.
  ///
  /// In en, this message translates to:
  /// **'{n} tools fetched'**
  String toolsFetched(Object n);

  /// No description provided for @fetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Fetch failed: {error}'**
  String fetchFailed(Object error);

  /// No description provided for @scheduledTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Task'**
  String get scheduledTaskLabel;

  /// No description provided for @setScheduledMessage.
  ///
  /// In en, this message translates to:
  /// **'Set scheduled message'**
  String get setScheduledMessage;

  /// No description provided for @scheduledLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledLabelColon;

  /// No description provided for @modelConfigNotFound.
  ///
  /// In en, this message translates to:
  /// **'Model configuration not found'**
  String get modelConfigNotFound;

  /// No description provided for @modelProviderNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Model provider not configured'**
  String get modelProviderNotConfigured;

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Screenshot failed: render object not found'**
  String get screenshotFailed;

  /// No description provided for @generateImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate image'**
  String get generateImageFailed;

  /// No description provided for @messageScreenshotCopied.
  ///
  /// In en, this message translates to:
  /// **'Message screenshot copied to clipboard'**
  String get messageScreenshotCopied;

  /// No description provided for @currentRoundScreenshotCopied.
  ///
  /// In en, this message translates to:
  /// **'Round screenshot copied to clipboard'**
  String get currentRoundScreenshotCopied;

  /// No description provided for @fullConversationScreenshotCopied.
  ///
  /// In en, this message translates to:
  /// **'Full conversation screenshot copied to clipboard'**
  String get fullConversationScreenshotCopied;

  /// No description provided for @noMessagesInConversation.
  ///
  /// In en, this message translates to:
  /// **'No messages in conversation'**
  String get noMessagesInConversation;

  /// No description provided for @cannotFindMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot find the message'**
  String get cannotFindMessage;

  /// No description provided for @cannotFindCompleteRound.
  ///
  /// In en, this message translates to:
  /// **'Cannot find complete conversation round'**
  String get cannotFindCompleteRound;

  /// No description provided for @partialScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Some messages could not be captured, {n}/{total} messages captured'**
  String partialScreenshot(Object n, Object total);

  /// No description provided for @renderObjectStillDrawing.
  ///
  /// In en, this message translates to:
  /// **'Screenshot failed: render object still drawing'**
  String get renderObjectStillDrawing;

  /// No description provided for @screenshotCopied.
  ///
  /// In en, this message translates to:
  /// **'{type} screenshot copied to clipboard'**
  String screenshotCopied(Object type);

  /// No description provided for @screenshotTypeFailed.
  ///
  /// In en, this message translates to:
  /// **'{type} screenshot failed: {error}'**
  String screenshotTypeFailed(Object error, Object type);

  /// No description provided for @mergeScreenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Merge screenshot failed: {error}'**
  String mergeScreenshotFailed(Object error);

  /// No description provided for @copyImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy image failed: {error}'**
  String copyImageFailed(Object error);

  /// No description provided for @unsupportedOS.
  ///
  /// In en, this message translates to:
  /// **'Unsupported OS'**
  String get unsupportedOS;

  /// No description provided for @desktopCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Desktop copy image failed: {error}'**
  String desktopCopyFailed(Object error);

  /// No description provided for @noClipboardTool.
  ///
  /// In en, this message translates to:
  /// **'No clipboard tool available (xclip or wl-copy)'**
  String get noClipboardTool;

  /// No description provided for @cannotFindRenderObject.
  ///
  /// In en, this message translates to:
  /// **'Cannot find message render object'**
  String get cannotFindRenderObject;

  /// No description provided for @editScheduledTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Scheduled Task'**
  String get editScheduledTask;

  /// No description provided for @setScheduledTaskDialog.
  ///
  /// In en, this message translates to:
  /// **'Set Scheduled Task'**
  String get setScheduledTaskDialog;

  /// No description provided for @cronExpression.
  ///
  /// In en, this message translates to:
  /// **'Cron Expression'**
  String get cronExpression;

  /// No description provided for @cronFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: minute hour day month weekday (5 fields)'**
  String get cronFormat;

  /// No description provided for @messageContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Message Content'**
  String get messageContentLabel;

  /// No description provided for @enableTask.
  ///
  /// In en, this message translates to:
  /// **'Enable Task'**
  String get enableTask;

  /// No description provided for @pleaseEnterCron.
  ///
  /// In en, this message translates to:
  /// **'Please enter cron expression'**
  String get pleaseEnterCron;

  /// No description provided for @cronFormatError.
  ///
  /// In en, this message translates to:
  /// **'Cron format error (5 fields required)'**
  String get cronFormatError;

  /// No description provided for @daily0900.
  ///
  /// In en, this message translates to:
  /// **'Daily 09:00'**
  String get daily0900;

  /// No description provided for @daily1200.
  ///
  /// In en, this message translates to:
  /// **'Daily 12:00'**
  String get daily1200;

  /// No description provided for @daily1800.
  ///
  /// In en, this message translates to:
  /// **'Daily 18:00'**
  String get daily1800;

  /// No description provided for @workday0900.
  ///
  /// In en, this message translates to:
  /// **'Weekdays 09:00'**
  String get workday0900;

  /// No description provided for @every30min.
  ///
  /// In en, this message translates to:
  /// **'Every 30 min'**
  String get every30min;

  /// No description provided for @every2h.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get every2h;

  /// No description provided for @processFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Process failed'**
  String get processFailedStatus;

  /// No description provided for @processingStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingStatus;

  /// No description provided for @contentPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} - Content Preview'**
  String contentPreviewTitle(Object name);

  /// No description provided for @contentCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Content copied to clipboard'**
  String get contentCopiedToClipboard;

  /// No description provided for @fileProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'File processing failed'**
  String get fileProcessFailed;

  /// No description provided for @pleaseReupload.
  ///
  /// In en, this message translates to:
  /// **'Please re-upload the file or contact support'**
  String get pleaseReupload;

  /// No description provided for @processingFileStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing file...'**
  String get processingFileStatus;

  /// No description provided for @imageFile.
  ///
  /// In en, this message translates to:
  /// **'Image file'**
  String get imageFile;

  /// No description provided for @documentFile.
  ///
  /// In en, this message translates to:
  /// **'Document file'**
  String get documentFile;

  /// No description provided for @textFile.
  ///
  /// In en, this message translates to:
  /// **'Text file'**
  String get textFile;

  /// No description provided for @codeFile.
  ///
  /// In en, this message translates to:
  /// **'Code file'**
  String get codeFile;

  /// No description provided for @officeDocument.
  ///
  /// In en, this message translates to:
  /// **'Office document'**
  String get officeDocument;

  /// No description provided for @webLink.
  ///
  /// In en, this message translates to:
  /// **'Web link'**
  String get webLink;

  /// No description provided for @folderType.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folderType;

  /// No description provided for @otherFile.
  ///
  /// In en, this message translates to:
  /// **'Other file'**
  String get otherFile;

  /// No description provided for @defaultConversation.
  ///
  /// In en, this message translates to:
  /// **'General Conversation'**
  String get defaultConversation;

  /// No description provided for @modelCopied.
  ///
  /// In en, this message translates to:
  /// **'Model \"{name}\" copied successfully'**
  String modelCopied(Object name);

  /// No description provided for @copyOf.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String copyOf(Object name);

  /// No description provided for @copyOfN.
  ///
  /// In en, this message translates to:
  /// **'{name} copy ({n})'**
  String copyOfN(Object n, Object name);

  /// No description provided for @noModels.
  ///
  /// In en, this message translates to:
  /// **'No models'**
  String get noModels;

  /// No description provided for @clickAddModelHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add Model\" button to start'**
  String get clickAddModelHint;

  /// No description provided for @modelUpdatedNotify.
  ///
  /// In en, this message translates to:
  /// **'Model \"{name}\" updated, related session settings synchronized'**
  String modelUpdatedNotify(Object name);

  /// No description provided for @serviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Service removed: {name}'**
  String serviceRemoved(Object name);

  /// No description provided for @connectorManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Connector Management (MCP)'**
  String get connectorManagementTitle;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @noMcpServices.
  ///
  /// In en, this message translates to:
  /// **'No MCP services'**
  String get noMcpServices;

  /// No description provided for @clickToEnterMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Click + button to enter marketplace'**
  String get clickToEnterMarketplace;

  /// No description provided for @fetchToolsFailed.
  ///
  /// In en, this message translates to:
  /// **'Fetch tools failed: {error}'**
  String fetchToolsFailed(Object error);

  /// No description provided for @removeServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Service'**
  String get removeServiceLabel;

  /// No description provided for @removeServiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove service'**
  String get removeServiceConfirm;

  /// No description provided for @removeServiceWarning.
  ///
  /// In en, this message translates to:
  /// **'Need to re-add after removal'**
  String get removeServiceWarning;

  /// No description provided for @jsonConfig.
  ///
  /// In en, this message translates to:
  /// **'JSON Config'**
  String get jsonConfig;

  /// No description provided for @cannotReadFilePath.
  ///
  /// In en, this message translates to:
  /// **'Cannot read file path'**
  String get cannotReadFilePath;

  /// No description provided for @extractingImport.
  ///
  /// In en, this message translates to:
  /// **'Extracting import...'**
  String get extractingImport;

  /// No description provided for @skillImported.
  ///
  /// In en, this message translates to:
  /// **'Skill imported'**
  String get skillImported;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @deleteSkillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete skill'**
  String get deleteSkillConfirm;

  /// No description provided for @irreversibleAction.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible'**
  String get irreversibleAction;

  /// No description provided for @skillDeleted.
  ///
  /// In en, this message translates to:
  /// **'Skill deleted: {name}'**
  String skillDeleted(Object name);

  /// No description provided for @deleteSkillFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete skill failed: {error}'**
  String deleteSkillFailed(Object error);

  /// No description provided for @skillDescription.
  ///
  /// In en, this message translates to:
  /// **'Skill Description'**
  String get skillDescription;

  /// No description provided for @skillManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill Management (SKILL)'**
  String get skillManagementTitle;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add Skill'**
  String get addSkill;

  /// No description provided for @noSkills.
  ///
  /// In en, this message translates to:
  /// **'No skills'**
  String get noSkills;

  /// No description provided for @clickAddSkillHint.
  ///
  /// In en, this message translates to:
  /// **'Click add button to create custom skill'**
  String get clickAddSkillHint;

  /// No description provided for @toolNameDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} · {desc}'**
  String toolNameDesc(Object desc, Object name);

  /// No description provided for @modelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Model Deleted'**
  String get modelDeleted;

  /// No description provided for @modelDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Model \"{name}\" successfully deleted'**
  String modelDeletedSuccessfully(Object name);

  /// No description provided for @selectOtherModelFromList.
  ///
  /// In en, this message translates to:
  /// **'Select another model from the list to view details'**
  String get selectOtherModelFromList;

  /// No description provided for @unnamedModel.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Model'**
  String get unnamedModel;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @confirmDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the model'**
  String get confirmDeleteModel;

  /// No description provided for @modelDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Model \"{name}\" deleted'**
  String modelDeletedToast(Object name);

  /// No description provided for @addOnlineModel.
  ///
  /// In en, this message translates to:
  /// **'Add Online Model'**
  String get addOnlineModel;

  /// No description provided for @selectProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Provider'**
  String get selectProvider;

  /// No description provided for @configureParams.
  ///
  /// In en, this message translates to:
  /// **'Configure Parameters'**
  String get configureParams;

  /// No description provided for @checkConfig.
  ///
  /// In en, this message translates to:
  /// **'Check Configuration'**
  String get checkConfig;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set Name'**
  String get setName;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @selectOnlineProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Online Model Provider'**
  String get selectOnlineProvider;

  /// No description provided for @configureProviderParams.
  ///
  /// In en, this message translates to:
  /// **'Configure {provider} Parameters'**
  String configureProviderParams(Object provider);

  /// No description provided for @ollamaApiKeyOptional.
  ///
  /// In en, this message translates to:
  /// **'Local Ollama service usually doesn\'t require an API key, can leave empty'**
  String get ollamaApiKeyOptional;

  /// No description provided for @apiAddress.
  ///
  /// In en, this message translates to:
  /// **'API Address'**
  String get apiAddress;

  /// No description provided for @defaultApiUrlNote.
  ///
  /// In en, this message translates to:
  /// **'Default official API address, can be modified for local or private deployments'**
  String get defaultApiUrlNote;

  /// No description provided for @presetModel.
  ///
  /// In en, this message translates to:
  /// **'Preset Models'**
  String get presetModel;

  /// No description provided for @customModel.
  ///
  /// In en, this message translates to:
  /// **'Custom Model'**
  String get customModel;

  /// No description provided for @enterFullModelName.
  ///
  /// In en, this message translates to:
  /// **'Enter the full model name supported by the provider'**
  String get enterFullModelName;

  /// No description provided for @ollamaRunningModels.
  ///
  /// In en, this message translates to:
  /// **'Ollama Running Models'**
  String get ollamaRunningModels;

  /// No description provided for @refreshModelList.
  ///
  /// In en, this message translates to:
  /// **'Refresh model list'**
  String get refreshModelList;

  /// No description provided for @ollamaStartHint.
  ///
  /// In en, this message translates to:
  /// **'Please start Ollama service and download models first\nthen click refresh to get the model list'**
  String get ollamaStartHint;

  /// No description provided for @modelscopeAvailableModels.
  ///
  /// In en, this message translates to:
  /// **'ModelScope Available Models'**
  String get modelscopeAvailableModels;

  /// No description provided for @modelscopeApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Please ensure API key is correct\nthen click refresh to get the model list'**
  String get modelscopeApiKeyHint;

  /// No description provided for @setModelName.
  ///
  /// In en, this message translates to:
  /// **'Set Model Name'**
  String get setModelName;

  /// No description provided for @configSummary.
  ///
  /// In en, this message translates to:
  /// **'Configuration Summary'**
  String get configSummary;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @platformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformLabel;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// No description provided for @customSuffix.
  ///
  /// In en, this message translates to:
  /// **'(Custom)'**
  String get customSuffix;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @customModelName.
  ///
  /// In en, this message translates to:
  /// **'Custom Model Name'**
  String get customModelName;

  /// No description provided for @enterModelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model name, e.g. {provider}-Chat'**
  String enterModelNameHint(Object provider);

  /// No description provided for @modelNameSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use a meaningful name for easy identification'**
  String get modelNameSuggestion;

  /// No description provided for @testConnectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Test model connection and response'**
  String get testConnectionDesc;

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response...'**
  String get waitingForResponse;

  /// No description provided for @configIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Configuration incomplete'**
  String get configIncomplete;

  /// No description provided for @receivedEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'Received empty response'**
  String get receivedEmptyResponse;

  /// No description provided for @receivedNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response received'**
  String get receivedNoResponse;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(Object error);

  /// No description provided for @contextCap.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get contextCap;

  /// No description provided for @thinkingCap.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinkingCap;

  /// No description provided for @builtinToolsCap.
  ///
  /// In en, this message translates to:
  /// **'Built-in Tools'**
  String get builtinToolsCap;

  /// No description provided for @structuredCap.
  ///
  /// In en, this message translates to:
  /// **'Structured'**
  String get structuredCap;

  /// No description provided for @batchCap.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batchCap;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @modelParams.
  ///
  /// In en, this message translates to:
  /// **'Model Parameters'**
  String get modelParams;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @notSetDoubleClickToEdit.
  ///
  /// In en, this message translates to:
  /// **'Not set (double-click to edit)'**
  String get notSetDoubleClickToEdit;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get apiKeySaved;

  /// No description provided for @modelNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Model name cannot be empty'**
  String get modelNameCannotBeEmpty;

  /// No description provided for @modelNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Model name saved'**
  String get modelNameSaved;

  /// No description provided for @modelSaved.
  ///
  /// In en, this message translates to:
  /// **'Model saved'**
  String get modelSaved;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @precise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get precise;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @creative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get creative;

  /// No description provided for @temperatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls response randomness and creativity. Lower values are more conservative, higher values more creative.'**
  String get temperatureDescription;

  /// No description provided for @modelRoleSetting.
  ///
  /// In en, this message translates to:
  /// **'Model Role Setting'**
  String get modelRoleSetting;

  /// No description provided for @presetRole.
  ///
  /// In en, this message translates to:
  /// **'Preset Role'**
  String get presetRole;

  /// No description provided for @roleSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'The role setting is sent to the model at the start of each conversation to define the role and behavior. Adjust according to the role you want the model to play.'**
  String get roleSettingDescription;

  /// No description provided for @selectPresetRole.
  ///
  /// In en, this message translates to:
  /// **'Select Preset Role'**
  String get selectPresetRole;

  /// No description provided for @generalAssistant.
  ///
  /// In en, this message translates to:
  /// **'General Assistant'**
  String get generalAssistant;

  /// No description provided for @friendlyAssistantDesc.
  ///
  /// In en, this message translates to:
  /// **'Friendly, professional AI assistant'**
  String get friendlyAssistantDesc;

  /// No description provided for @spellCheck.
  ///
  /// In en, this message translates to:
  /// **'Spell Check'**
  String get spellCheck;

  /// No description provided for @spellCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Spell check expert'**
  String get spellCheckDesc;

  /// No description provided for @codeExpert.
  ///
  /// In en, this message translates to:
  /// **'Code Expert'**
  String get codeExpert;

  /// No description provided for @codeExpertDesc.
  ///
  /// In en, this message translates to:
  /// **'Technical expert in programming and development'**
  String get codeExpertDesc;

  /// No description provided for @legalExpert.
  ///
  /// In en, this message translates to:
  /// **'Legal Expert'**
  String get legalExpert;

  /// No description provided for @legalExpertDesc.
  ///
  /// In en, this message translates to:
  /// **'Professional legal advisor'**
  String get legalExpertDesc;

  /// No description provided for @copywriter.
  ///
  /// In en, this message translates to:
  /// **'Copywriter'**
  String get copywriter;

  /// No description provided for @copywriterDesc.
  ///
  /// In en, this message translates to:
  /// **'Creative copywriting and content creation expert'**
  String get copywriterDesc;

  /// No description provided for @dataAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Data Analyst'**
  String get dataAnalyst;

  /// No description provided for @dataAnalystDesc.
  ///
  /// In en, this message translates to:
  /// **'Data analysis and statistics expert'**
  String get dataAnalystDesc;

  /// No description provided for @educationTutor.
  ///
  /// In en, this message translates to:
  /// **'Education Tutor'**
  String get educationTutor;

  /// No description provided for @educationTutorDesc.
  ///
  /// In en, this message translates to:
  /// **'Patient teaching expert'**
  String get educationTutorDesc;

  /// No description provided for @businessConsultant.
  ///
  /// In en, this message translates to:
  /// **'Business Consultant'**
  String get businessConsultant;

  /// No description provided for @businessConsultantDesc.
  ///
  /// In en, this message translates to:
  /// **'Business management and strategy expert'**
  String get businessConsultantDesc;

  /// No description provided for @psychologist.
  ///
  /// In en, this message translates to:
  /// **'Psychologist'**
  String get psychologist;

  /// No description provided for @psychologistDesc.
  ///
  /// In en, this message translates to:
  /// **'Professional mental health consultant'**
  String get psychologistDesc;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
