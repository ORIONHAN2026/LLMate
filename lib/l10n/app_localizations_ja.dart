// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => 'スマートチャットアシスタント';

  @override
  String get feedback => 'フィードバック';

  @override
  String get modelManagement => 'モデル管理';

  @override
  String get connectorManagement => 'コネクタ管理 (MCP)';

  @override
  String get domainManagement => 'サービス管理';

  @override
  String get otherSettings => 'その他の設定';

  @override
  String get resetSystem => 'システムをリセット';

  @override
  String get resetAllSessions => 'すべてのセッションをリセット';

  @override
  String get resetAllModels => 'すべてのモデルをリセット';

  @override
  String get resetAllMcp => 'すべてのMCPをリセット';

  @override
  String get resetAll => 'すべてリセット';

  @override
  String resetConfirmMsg(Object action) {
    return '$actionしてもよろしいですか？この操作は取り消せません。';
  }

  @override
  String get languageSettings => '言語';

  @override
  String get skinSettings => 'テーマ';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get followSystemDesc => 'ライト/ダークモードを自動切替';

  @override
  String get lightMode => 'ライト';

  @override
  String get lightModeDesc => '常にライトテーマを使用';

  @override
  String get darkMode => 'ダーク';

  @override
  String get darkModeDesc => '常にダークテーマを使用';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => '簡体字中国語';

  @override
  String get english => 'English';

  @override
  String get englishDesc => '英語';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get close => '閉じる';

  @override
  String get remove => '削除';

  @override
  String get clear => 'クリア';

  @override
  String get search => '検索';

  @override
  String get noData => 'データなし';

  @override
  String get loading => '読み込み中...';

  @override
  String get send => '送信';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get copyContent => '内容をコピー';

  @override
  String get retry => '再試行';

  @override
  String get done => '完了';

  @override
  String get back => '戻る';

  @override
  String get previousStep => '前へ';

  @override
  String get settings => '設定';

  @override
  String get systemPrompt => 'システムプロンプト';

  @override
  String get temperature => '温度';

  @override
  String get replyLanguage => '応答言語';

  @override
  String get newSession => '新規セッション';

  @override
  String get sessionList => 'セッション一覧';

  @override
  String get rename => '名前を変更';

  @override
  String get shareConversation => '会話を共有';

  @override
  String get exportData => 'データをエクスポート';

  @override
  String get importData => 'データをインポート';

  @override
  String get clearConversation => '会話をクリア';

  @override
  String get deleteConversation => '会話を削除';

  @override
  String get deleteConfirm => '削除の確認';

  @override
  String get deleteConfirmMsg => '本当に削除しますか？';

  @override
  String removeConfirmMsg(Object name) {
    return '本当に「$name」を削除しますか？';
  }

  @override
  String get addModel => 'モデルを追加';

  @override
  String get copyModel => 'モデルをコピー';

  @override
  String get modelName => 'モデル名';

  @override
  String get modelProvider => 'プロバイダ';

  @override
  String get modelApiKey => 'APIキー';

  @override
  String get modelBaseUrl => 'ベースURL';

  @override
  String get modelMaxTokens => '最大トークン数';

  @override
  String get thinkTag => '思考タグ';

  @override
  String get thinkTagDesc => 'モデルの思考プロセスタグ';

  @override
  String get addService => 'サービスを追加';

  @override
  String get removeService => 'サービスを削除';

  @override
  String get testConnection => '接続テスト';

  @override
  String get fullTest => '完全テスト';

  @override
  String get connectAndAdd => '接続して追加';

  @override
  String get addCustomConnector => 'カスタムコネクタを追加';

  @override
  String get clearKey => 'キーをクリア';

  @override
  String get fetchTools => 'ツールを取得';

  @override
  String get fetchModels => 'モデルを取得';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get regenerate => '再生成';

  @override
  String get regenerateFromHere => 'ここから再生成';

  @override
  String get regenerateLastReply => '最後の応答を再生成';

  @override
  String get regenerateThisReply => 'この応答を再生成';

  @override
  String get createNewChatFromHere => 'ここから新しいチャット';

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String get deleteReply => '応答を削除';

  @override
  String get screenshot => 'スクリーンショット';

  @override
  String get entireConversation => '全体の会話';

  @override
  String get currentRound => '現在のラウンド';

  @override
  String get currentMessage => '現在のメッセージ';

  @override
  String get memoryConfig => 'メモリ設定';

  @override
  String get clearMcpServices => 'MCPサービスをクリア';

  @override
  String get selectFile => 'ファイルを選択';

  @override
  String get selectWorkingDir => '作業ディレクトリを選択';

  @override
  String get confirmDeleteTitle => '削除の確認';

  @override
  String get deleteSessionTitle => 'セッションを削除';

  @override
  String get favorites => 'お気に入り';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get earlier => '以前';

  @override
  String get removeServiceTitle => 'サービスを削除';

  @override
  String get removeMcpServiceTitle => 'MCPサービスを削除';

  @override
  String get noActiveSession => 'アクティブなセッションがありません';

  @override
  String get presetRoleApplied => 'プリセットロールを適用しました';

  @override
  String get fileNotFound => 'ファイルが見つかりません';

  @override
  String get fileOpenFailed => 'ファイルを開けませんでした';

  @override
  String get enterMessageContent => 'メッセージ内容を入力してください';

  @override
  String get copyMessageContent => 'メッセージ内容をコピー';

  @override
  String get apiKeyHint => 'APIキーを入力';

  @override
  String get modelNameHint => 'モデル名を入力';

  @override
  String get messageHint => 'メッセージ内容を入力...';

  @override
  String get apiUrlHint => 'APIのURLを入力';

  @override
  String get commandHint => 'コマンド内容を入力';

  @override
  String get enterCommandContent => 'コマンド内容を入力してください';

  @override
  String get modelSearchHint => 'モデル名を入力（例：gpt-4o-mini, claude-3-haiku）';

  @override
  String get roleDescHint => 'モデルの動作と応答スタイルを導くロール説明を入力...';

  @override
  String get toolLogicHint => 'ツールのロジック説明を入力...';

  @override
  String get typeCommandOrSearch => 'コマンドを入力または検索...';

  @override
  String get searchMcp => 'MCPサービスを検索...';

  @override
  String get cronExample => '例：0 9 * * *（毎日9:00）';

  @override
  String get config => '設定';

  @override
  String get pasteMcpCode => 'MCPコードを貼り付け';

  @override
  String get fileNameLabel => 'ファイル名';

  @override
  String get fileSizeLabel => 'サイズ';

  @override
  String get fileTypeLabel => '種類';

  @override
  String get filePathLabel => 'パス';

  @override
  String get aliyun => 'アリババクラウド';

  @override
  String get tencentCloud => 'テンセントクラウド';

  @override
  String get modelscope => 'ModelScope';

  @override
  String get goToAliyun => 'アリババクラウドへ移動';

  @override
  String pleaseEnter(Object field) {
    return '$fieldを入力してください';
  }

  @override
  String get more => 'もっと見る';

  @override
  String get copyFailed => 'コピーに失敗しました';

  @override
  String get invalidLinkFormat => '無効なリンク形式';

  @override
  String get cannotOpenLink => 'リンクを開けません';

  @override
  String get linkOpenedInBrowser => 'リンクをブラウザで開きました';

  @override
  String get cannotOpenThisLinkType => 'この種類のリンクは開けません';

  @override
  String get openLinkFailed => 'リンクのオープンに失敗しました';

  @override
  String get fileOpened => 'ファイルを開きました';

  @override
  String get cannotOpenFile => 'ファイルを開けません';

  @override
  String get openFileFailed => 'ファイルを開けませんでした';

  @override
  String get sessionNotFoundForMessage => 'このメッセージのセッションが見つかりません';

  @override
  String get messageNotFound => 'メッセージが見つかりません';

  @override
  String get regenerateFailed => '再生成に失敗しました';

  @override
  String get cannotFindQuestion => '対応する質問が見つかりません';

  @override
  String get noAiReplyFound => 'AIの応答が見つかりません';

  @override
  String get cannotRegenerateInvalidIndex => '再生成できません：無効なメッセージインデックス';

  @override
  String get editMessageTitle => 'メッセージを編集';

  @override
  String get messageContentCannotBeEmpty => 'メッセージ内容は空にできません';

  @override
  String get newChatFromHistory => '履歴から新しいチャット';

  @override
  String get newChatCreatedFromHere => 'ここから新しいチャットを作成しました';

  @override
  String get createNewChatFailed => '新しいチャットの作成に失敗しました';

  @override
  String get thinking => '思考中...';

  @override
  String get callingTool => 'ツールを呼び出し中';

  @override
  String get toolCallRecord => 'ツール呼び出し記録';

  @override
  String get messageDeleted => 'メッセージを削除しました';

  @override
  String get deleteMessageFailed => 'メッセージの削除に失敗しました';

  @override
  String get duration => '所要時間';

  @override
  String get calculating => '計算中...';

  @override
  String get speed => '速度';

  @override
  String get outputTokensLabel => '出力トークン';

  @override
  String get fullscreen => '全画面';

  @override
  String get collapseSidebar => 'サイドバーを折りたたむ';

  @override
  String get expandSidebar => 'サイドバーを展開';

  @override
  String get collapseRightSidebar => '右サイドバーを折りたたむ';

  @override
  String get expandRightSidebar => '右サイドバーを展開';

  @override
  String get unfavorite => 'お気に入りから削除';

  @override
  String get favoriteSession => 'お気に入りに追加';

  @override
  String get user => 'ユーザー';

  @override
  String get assistant => 'アシスタント';

  @override
  String get noMemory => 'メモリなし';

  @override
  String get noFiles => 'ファイルなし';

  @override
  String get fileInfo => 'ファイル情報';

  @override
  String get fileContent => 'ファイル内容';

  @override
  String get noContentPreview => 'プレビューなし';

  @override
  String get fileContentCopied => 'ファイル内容をクリップボードにコピーしました';

  @override
  String get selectOrCreateSession => 'セッションを選択または作成してください';

  @override
  String get invalidSessionIndex => '無効なセッションインデックス';

  @override
  String get cannotOpenEmailApp => 'メールアプリを開けません';

  @override
  String get sendEmailFailed => 'メールの送信に失敗しました';

  @override
  String get memorySummary => 'メモリ概要';

  @override
  String get recentConversations => '最近の会話';

  @override
  String get sessionFiles => 'セッションファイル';

  @override
  String get files => 'ファイル';

  @override
  String get memory => 'メモリ';

  @override
  String get processed => '処理済み';

  @override
  String todayTime(Object time) {
    return '今日 $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month/$day $time';
  }

  @override
  String messageCount(Object count) {
    return '$count 件のメッセージ';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action に失敗しました: $error';
  }

  @override
  String xDone(Object action) {
    return '$action が完了しました';
  }

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get replyDeleted => '応答を削除しました';

  @override
  String get deleteReplyFailed => '応答の削除に失敗しました';

  @override
  String get asConversationContinues => '会話が続くにつれて、AIは\n自動的にメモリを記録・圧縮します';

  @override
  String get whenAiCreatesFiles => 'AIツールが会話中にファイルを作成・変更すると、\nここに表示されます';

  @override
  String get deleteSessionTitle_warning => 'この操作は取り消せません';

  @override
  String get pleaseSetupModel => 'モデルを設定してください';

  @override
  String get clickToSelectModel => '上をクリックしてチャットモデルを選択';

  @override
  String get selectModel => 'モデルを選択';

  @override
  String get noAvailableModels => '利用可能なモデルがありません';

  @override
  String get sessionNotFoundCannotSelectModel => 'セッションが見つからないため、モデルを選択できません';

  @override
  String get inputHint => 'ここにメッセージを入力、↵で送信、Shift+↵で改行';

  @override
  String get stopAnswer => '回答を停止';

  @override
  String waitingAttachments(Object count) {
    return '$count 件の添付ファイルの処理を待機中';
  }

  @override
  String get sendMessageAction => 'メッセージを送信';

  @override
  String get deepThinkEnabled => 'ディープシンク：オン';

  @override
  String get deepThinkDisabled => 'ディープシンク：オフ';

  @override
  String get deepThink => 'ディープシンク';

  @override
  String get workingDirectoryLabel => '作業ディレクトリ';

  @override
  String workingDirectoryPath(Object path) {
    return '作業ディレクトリ: $path';
  }

  @override
  String get setWorkingDirHint => '作業ディレクトリを設定（既定の保存場所）';

  @override
  String get workingDirSet => '作業ディレクトリを設定しました';

  @override
  String get workingDirCleared => '作業ディレクトリをクリアしました';

  @override
  String get noWorkingDir => '最初に契約ファイルのディレクトリを設定してください';

  @override
  String get parseContract => '契約を解析';

  @override
  String get parseContractHint => '作業ディレクトリ内の契約ファイルを解析';

  @override
  String get parseContractPrompt =>
      '以下は作業ディレクトリ内のドキュメントファイルです。まず、どのファイルが実際の契約書（添付ファイル、説明、その他の非契約ファイルではない）であるかを判断してください。その後、契約書と確定したファイルについてのみ、contract_inspectツールを使用して各契約の情報を書き込んでください。\n\n書き込みルール：\n- 各契約について、まずaction=addを呼び出して契約エントリを作成（contractName、contractType、paymentClause、paymentSchedule、breachClause、liabilityClause、startDate、endDate、signingDateなどを入力）\n- 次に、各当事者についてaction=addPartyを呼び出し、甲、乙などを順に追加\n- また、どのファイルが非契約と判定されたか、その理由を応答に簡単に説明してください';

  @override
  String get contractPoints => '契約のポイント';

  @override
  String get noContracts => '契約のポイントなし';

  @override
  String get contractParsing => '解析後に契約のポイントがここに表示されます';

  @override
  String get contractParty => '当事者';

  @override
  String get contractPaymentClause => '支払条項';

  @override
  String get contractPaymentSchedule => '支払スケジュール';

  @override
  String get contractBreachClause => '違約条項';

  @override
  String get contractLiability => '責任';

  @override
  String get contractPeriod => '契約期間';

  @override
  String get contractSigningDate => '契約締結日';

  @override
  String get contractTypeLabel => '契約種別';

  @override
  String nRounds(Object n) {
    return '$n ラウンド';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return 'メモリ設定：直近 $label 件の会話を保持';
  }

  @override
  String get closeMemory => 'メモリを閉じる';

  @override
  String get noContext => 'コンテキストなし';

  @override
  String keepXRounds(Object n) {
    return '$n ラウンド保持';
  }

  @override
  String lastXRounds(Object n) {
    return '直近 $n ラウンド';
  }

  @override
  String get defaultMemory => '既定';

  @override
  String get longConversation => '長い会話';

  @override
  String get veryLongConversation => '非常に長い会話';

  @override
  String get noMatchingResults => '一致する結果がありません';

  @override
  String get memoryClosed => 'メモリを閉じました';

  @override
  String memoryConfigSet(Object n) {
    return 'メモリ設定: $n ラウンド';
  }

  @override
  String get attach => '添付';

  @override
  String get selectMcpTool => 'コネクタを選択';

  @override
  String get noMcpTool => 'コネクタなし';

  @override
  String get viewMcpToolDetail => 'MCPツール詳細を表示';

  @override
  String get clickToSelectMcpTool => 'クリックしてMCPツールを選択';

  @override
  String get noMcpToolConfigured => 'MCPツールが設定されていません';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return 'ツールワークフロー: $desc';
  }

  @override
  String get clickToDesignWorkflow => 'コネクタとスキルの連携ロジックを設定';

  @override
  String get alreadySet => '設定済み';

  @override
  String get toolWorkflowDescTitle => 'ツールワークフロー説明';

  @override
  String get enterToolWorkflowDesc => 'ツールワークフロー説明を入力...';

  @override
  String get relationDescCleared => '関連説明をクリアしました';

  @override
  String get relationDescSaved => '関連説明を保存しました';

  @override
  String get noMcpServiceConfigured => 'MCPサービスが設定されていません';

  @override
  String mcpServiceList(Object n) {
    return 'MCPサービス一覧 ($n)';
  }

  @override
  String get mcpServiceTitle => 'MCPサービス';

  @override
  String get enabledStatus => '有効';

  @override
  String get disabledStatus => '無効';

  @override
  String commandLabel(Object cmd) {
    return 'コマンド: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return '引数: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return 'ディレクトリ: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return 'タイムアウト: $n秒';
  }

  @override
  String get mcpListHint => 'ヒント：MCPボタンをダブルクリックで一覧、シングルクリックで切替';

  @override
  String get mcpEnabledMsg => 'MCPツールを有効にしました。送信時に自動呼び出します';

  @override
  String get mcpDisabledMsg => 'MCPツールを無効にしました';

  @override
  String get clearMcpService => 'MCPサービスをクリア';

  @override
  String get unbindAction => '紐付け解除';

  @override
  String xTools(Object n) {
    return '$n ツール';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'MCPサービスを選択しました: $name';
  }

  @override
  String get mcpToolsDisabled => 'MCPツールを無効にしました';

  @override
  String get createAction => '作成';

  @override
  String get noModelBound => 'モデルが紐付けられていません';

  @override
  String serviceUnavailable(Object error) {
    return '申し訳ありません、サービスは一時的に利用できません。$error';
  }

  @override
  String get confirmClear => 'クリアの確認';

  @override
  String get clearHistoryConfirmMsg => '本当にすべての会話履歴をクリアしますか？この操作は取り消せません。';

  @override
  String get historyCleared => '履歴をクリアしました';

  @override
  String folderPath(Object path) {
    return 'フォルダ: $path';
  }

  @override
  String toolList(Object n) {
    return 'ツール一覧 ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... 他 $n 件のツール';
  }

  @override
  String get jsonCopied => 'JSONをコピーしました';

  @override
  String get mcpDetail => 'MCP詳細';

  @override
  String toolsRefreshed(Object n) {
    return '$n 件のツールを更新しました';
  }

  @override
  String refreshFailed(Object error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get refreshAction => '更新';

  @override
  String toolsFetched(Object n) {
    return '$n 件のツールを取得しました';
  }

  @override
  String fetchFailed(Object error) {
    return '取得に失敗しました: $error';
  }

  @override
  String get modelConfigNotFound => 'モデル設定が見つかりません';

  @override
  String get modelProviderNotConfigured => 'モデルプロバイダが設定されていません';

  @override
  String get screenshotFailed => 'スクリーンショットに失敗しました：レンダーオブジェクトが見つかりません';

  @override
  String get generateImageFailed => '画像の生成に失敗しました';

  @override
  String get messageScreenshotCopied => 'メッセージのスクリーンショットをクリップボードにコピーしました';

  @override
  String get currentRoundScreenshotCopied => 'ラウンドのスクリーンショットをクリップボードにコピーしました';

  @override
  String get fullConversationScreenshotCopied =>
      '全体の会話のスクリーンショットをクリップボードにコピーしました';

  @override
  String get noMessagesInConversation => '会話にメッセージがありません';

  @override
  String get cannotFindMessage => 'メッセージが見つかりません';

  @override
  String get cannotFindCompleteRound => '完全な会話ラウンドが見つかりません';

  @override
  String partialScreenshot(Object n, Object total) {
    return '一部のメッセージをキャプチャできませんでした（$n/$total 件キャプチャ）';
  }

  @override
  String get renderObjectStillDrawing => 'スクリーンショットに失敗しました：レンダーオブジェクト描画中';

  @override
  String screenshotCopied(Object type) {
    return '$type のスクリーンショットをクリップボードにコピーしました';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return '$type のスクリーンショットに失敗しました: $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return 'スクリーンショットの結合に失敗しました: $error';
  }

  @override
  String copyImageFailed(Object error) {
    return '画像のコピーに失敗しました: $error';
  }

  @override
  String get unsupportedOS => '未対応のOS';

  @override
  String desktopCopyFailed(Object error) {
    return 'デスクトップの画像コピーに失敗しました: $error';
  }

  @override
  String get noClipboardTool => 'クリップボードツールがありません（xclip または wl-copy）';

  @override
  String get cannotFindRenderObject => 'メッセージのレンダーオブジェクトが見つかりません';

  @override
  String get cronExpression => 'Cron式';

  @override
  String get cronFormat => '形式：分 時 日 月 曜日（5フィールド）';

  @override
  String get messageContentLabel => 'メッセージ内容';

  @override
  String get enableTask => 'タスクを有効化';

  @override
  String get pleaseEnterCron => 'Cron式を入力してください';

  @override
  String get cronFormatError => 'Cron形式エラー（5フィールド必要）';

  @override
  String get daily0900 => '毎日 09:00';

  @override
  String get daily1200 => '毎日 12:00';

  @override
  String get daily1800 => '毎日 18:00';

  @override
  String get workday0900 => '平日 09:00';

  @override
  String get every30min => '30分ごと';

  @override
  String get every2h => '2時間ごと';

  @override
  String get processFailedStatus => '処理失敗';

  @override
  String get processingStatus => '処理中';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - 内容プレビュー';
  }

  @override
  String get contentCopiedToClipboard => '内容をクリップボードにコピーしました';

  @override
  String get fileProcessFailed => 'ファイルの処理に失敗しました';

  @override
  String get pleaseReupload => 'ファイルを再アップロードするか、サポートにお問い合わせください';

  @override
  String get processingFileStatus => 'ファイルを処理中...';

  @override
  String get imageFile => '画像ファイル';

  @override
  String get documentFile => 'ドキュメントファイル';

  @override
  String get textFile => 'テキストファイル';

  @override
  String get codeFile => 'コードファイル';

  @override
  String get officeDocument => 'Office文書';

  @override
  String get webLink => 'Webリンク';

  @override
  String get folderType => 'フォルダ';

  @override
  String get otherFile => 'その他のファイル';

  @override
  String get defaultConversation => '一般用会話';

  @override
  String modelCopied(Object name) {
    return 'モデル「$name」をコピーしました';
  }

  @override
  String copyOf(Object name) {
    return '$name のコピー';
  }

  @override
  String copyOfN(Object n, Object name) {
    return '$name のコピー ($n)';
  }

  @override
  String get noModels => 'モデルがありません';

  @override
  String get clickAddModelHint => '「モデルを追加」ボタンをクリックして開始';

  @override
  String modelUpdatedNotify(Object name) {
    return 'モデル「$name」を更新しました。関連するセッション設定を同期しました';
  }

  @override
  String serviceRemoved(Object name) {
    return 'サービスを削除しました: $name';
  }

  @override
  String get connectorManagementTitle => 'コネクタ管理 (MCP)';

  @override
  String get marketplace => 'マーケットプレイス';

  @override
  String get noMcpServices => 'MCPサービスがありません';

  @override
  String get clickToEnterMarketplace => '「+」ボタンをクリックしてマーケットプレイスへ';

  @override
  String fetchToolsFailed(Object error) {
    return 'ツールの取得に失敗しました: $error';
  }

  @override
  String get removeServiceLabel => 'サービスを削除';

  @override
  String get removeServiceConfirm => '本当にサービスを削除しますか';

  @override
  String get removeServiceWarning => '削除後は再追加が必要です';

  @override
  String get jsonConfig => 'JSON設定';

  @override
  String get cannotReadFilePath => 'ファイルパスを読み取れません';

  @override
  String get extractingImport => 'インポートを展開中...';

  @override
  String importFailed(Object error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String get irreversibleAction => 'この操作は取り消せません';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'モデルを削除しました';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'モデル「$name」を削除しました';
  }

  @override
  String get selectOtherModelFromList => '一覧から別のモデルを選択して詳細を表示';

  @override
  String get unnamedModel => '名称未設定のモデル';

  @override
  String get noDescription => '説明なし';

  @override
  String get confirmDeleteModel => '本当にモデルを削除しますか';

  @override
  String modelDeletedToast(Object name) {
    return 'モデル「$name」を削除しました';
  }

  @override
  String get addOnlineModel => 'オンラインモデルを追加';

  @override
  String get selectProvider => 'プロバイダを選択';

  @override
  String get configureParams => 'パラメータを設定';

  @override
  String get checkConfig => '設定を確認';

  @override
  String get setName => '名前を設定';

  @override
  String get nextStep => '次へ';

  @override
  String get selectOnlineProvider => 'オンラインモデルプロバイダを選択';

  @override
  String get customProvider => 'カスタム';

  @override
  String get customProviderDesc => 'アドレス、APIキー、モデル名を手動で入力';

  @override
  String get customProviderConfigTitle => 'カスタムモデル設定';

  @override
  String configureProviderParams(Object provider) {
    return '$provider のパラメータを設定';
  }

  @override
  String get ollamaApiKeyOptional => 'ローカルのOllamaサービスは通常APIキー不要、空のまま可';

  @override
  String get apiAddress => 'APIアドレス';

  @override
  String get defaultApiUrlNote => '公式の既定APIアドレス。ローカルやプライベート環境向けに変更可';

  @override
  String get presetModel => 'プリセットモデル';

  @override
  String get customModel => 'カスタムモデル';

  @override
  String get enterFullModelName => 'プロバイダが対応する完全なモデル名を入力';

  @override
  String get ollamaRunningModels => 'Ollama実行中のモデル';

  @override
  String get refreshModelList => 'モデル一覧を更新';

  @override
  String get ollamaStartHint =>
      '先にOllamaサービスを起動しモデルをダウンロードしてください\nその後、更新をクリックしてモデル一覧を取得';

  @override
  String get modelscopeAvailableModels => 'ModelScopeで利用可能なモデル';

  @override
  String get modelscopeApiKeyHint =>
      'APIキーが正しいことを確認してください\nその後、更新をクリックしてモデル一覧を取得';

  @override
  String get setModelName => 'モデル名を設定';

  @override
  String get configSummary => '設定概要';

  @override
  String get providerLabel => 'プロバイダ';

  @override
  String get platformLabel => 'プラットフォーム';

  @override
  String get notSet => '未設定';

  @override
  String get modelLabel => 'モデル';

  @override
  String get customSuffix => '（カスタム）';

  @override
  String get notSelected => '未選択';

  @override
  String get customModelName => 'カスタムモデル名';

  @override
  String enterModelNameHint(Object provider) {
    return 'モデル名を入力（例：$provider-Chat）';
  }

  @override
  String get modelNameSuggestion => '識別しやすい名前を使用してください';

  @override
  String get testConnectionDesc => 'モデルの接続と応答をテスト';

  @override
  String get waitingForResponse => '応答を待機中...';

  @override
  String get configIncomplete => '設定が不完全です';

  @override
  String get receivedEmptyResponse => '空の応答を受信しました';

  @override
  String get receivedNoResponse => '応答を受信しませんでした';

  @override
  String connectionFailed(Object error) {
    return '接続に失敗しました: $error';
  }

  @override
  String get contextCap => 'コンテキスト';

  @override
  String get thinkingCap => '思考';

  @override
  String get builtinToolsCap => '組み込みツール';

  @override
  String get structuredCap => '構造化';

  @override
  String get batchCap => 'バッチ';

  @override
  String get basicInfo => '基本情報';

  @override
  String get modelParams => 'モデル設定';

  @override
  String get unknown => '不明';

  @override
  String get nameLabel => '名前';

  @override
  String get apiKeyLabel => 'APIキー';

  @override
  String get notSetDoubleClickToEdit => '未設定（ダブルクリックで編集）';

  @override
  String get apiKeySaved => 'APIキーを保存しました';

  @override
  String get modelNameCannotBeEmpty => 'モデル名は空にできません';

  @override
  String get modelNameSaved => 'モデル名を保存しました';

  @override
  String get modelSaved => 'モデルを保存しました';

  @override
  String get temperatureLabel => '温度';

  @override
  String get precise => '正確';

  @override
  String get neutral => '標準';

  @override
  String get creative => '創造的';

  @override
  String get temperatureDescription =>
      '応答のランダム性と創造性を制御します。値が低いほど保守的、高いほど創造的になります。';

  @override
  String get modelRoleSetting => 'モデルロール設定';

  @override
  String get presetRole => 'プリセットロール';

  @override
  String get roleSettingDescription =>
      'ロール設定は各会話の開始時にモデルに送信され、演じるロールと動作を定義します。モデルに演じさせたいロールに合わせて調整してください。';

  @override
  String get selectPresetRole => 'プリセットロールを選択';

  @override
  String get generalAssistant => '一般アシスタント';

  @override
  String get friendlyAssistantDesc => '親しみやすくプロフェッショナルなAIアシスタント';

  @override
  String get spellCheck => 'スペルチェック';

  @override
  String get spellCheckDesc => 'スペルチェックの専門家';

  @override
  String get codeExpert => 'コード専門家';

  @override
  String get codeExpertDesc => 'プログラミングと開発の技術専門家';

  @override
  String get legalExpert => '法律専門家';

  @override
  String get legalExpertDesc => 'プロの法律アドバイザー';

  @override
  String get copywriter => 'コピーライター';

  @override
  String get copywriterDesc => 'クリエイティブなコピーライティングとコンテンツ制作の専門家';

  @override
  String get dataAnalyst => 'データアナリスト';

  @override
  String get dataAnalystDesc => 'データ分析と統計の専門家';

  @override
  String get educationTutor => '教育チューター';

  @override
  String get educationTutorDesc => '忍耐強い指導の専門家';

  @override
  String get businessConsultant => 'ビジネスコンサルタント';

  @override
  String get businessConsultantDesc => '経営と戦略の専門家';

  @override
  String get psychologist => '心理学者';

  @override
  String get psychologistDesc => 'プロのメンタルヘルスコンサルタント';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get workModeSettings => '作業モード';

  @override
  String get workModeBusiness => 'ビジネス';

  @override
  String get workModeBusinessDesc => '商談、契約管理、戦略';

  @override
  String get workModeFinance => 'ファイナンス';

  @override
  String get workModeFinanceDesc => '財務分析、税務計画、原価計算';

  @override
  String get workModeLegal => '法務';

  @override
  String get workModeLegalDesc => '法務文書作成、コンプライアンス審査、リスク評価';

  @override
  String get workModeMarketing => 'マーケティング';

  @override
  String get workModeMarketingDesc => 'マーケティング企画、ブランドプロモーション、競合分析';

  @override
  String get domainSettings => 'ドメイン設定';

  @override
  String get serviceStatus => 'ローカルサービス';

  @override
  String get localService => 'ローカルサービス';

  @override
  String get serviceStopped => 'サービス停止';

  @override
  String get serviceRunning => '稼働中';

  @override
  String get serviceStarting => '起動中...';

  @override
  String get restart => '再起動';

  @override
  String get certificateSettings => '証明書設定';

  @override
  String get httpsStatus => 'HTTPSステータス';

  @override
  String get domainAddress => 'ドメインアドレス';

  @override
  String get domainHint => '例：api.example.com';

  @override
  String get domainDesc =>
      '設定後、セッションサービスのURLはこのアドレスを使用します。HTTP既定ポート80、HTTPS既定ポート443。';

  @override
  String get portSettings => 'ポート設定';

  @override
  String get httpPort => 'HTTPポート';

  @override
  String get httpsPort => 'HTTPSポート';

  @override
  String get portDesc =>
      'HTTP待受ポート、既定80。HTTPS待受ポート、既定443。変更を適用するにはサービスを再起動してください。';

  @override
  String get sslCertificate => 'SSL証明書';

  @override
  String get sslPrivateKey => '秘密鍵';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String get httpsEnabled => 'HTTPS';

  @override
  String get httpsEnabledDesc => '証明書をアップロードし、HTTPSが自動有効化';

  @override
  String get httpsDisabledDesc => '証明書（crt/cert + key）をアップロードするとHTTPSが自動有効化';

  @override
  String get domainInfoDesc =>
      'サービスアドレスを設定後、セッションサービスのURLにこのアドレスが表示されます。外部クライアントはこのアドレスからセッションAPI（/chat/completions など）にアクセスできます。';

  @override
  String get pleaseEnterDomain => 'サービスアドレスを入力してください';

  @override
  String get domainSaved => 'サービス設定を保存しました';

  @override
  String get currencyLabel => '通貨';

  @override
  String get cny => 'CNY';

  @override
  String get usd => 'USD';

  @override
  String get loadingPageSubtitle => 'インテリジェント企業AIワークスペース';

  @override
  String get billingSettings => '課金';

  @override
  String get mcpSettings => 'MCP設定';

  @override
  String get currencyTypeLabel => '通貨タイプ';

  @override
  String get inputPriceLabel => '入力価格';

  @override
  String get outputPriceLabel => '出力価格';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/100万トークン';
  }

  @override
  String priceUnitDescription(Object unit) {
    return '価格: $unit/100万トークン。セッションの累積コスト計算に使用。';
  }

  @override
  String get examplePriceHint => '例：0.14';

  @override
  String get mcpBindingDescription =>
      'モデルにMCPサービスを紐付けると、このモデルを使用するセッションにこれらのMCPツールが自動注入されます。セッションMCPとモデルMCPは自動的に統合・重複排除されます。';

  @override
  String get addMcpServiceButton => 'MCPサービスを追加';

  @override
  String get clearAllMcpBindings => 'すべてのMCP紐付けをクリア';

  @override
  String get selectMcpServiceMultiSelect => 'MCPサービスを選択（複数選択）';

  @override
  String get noMcpServiceAddFirst => 'MCPサービスがありません。先にMCP管理で追加してください';

  @override
  String confirmWithCount(Object count) {
    return 'OK ($count)';
  }

  @override
  String get temperaturePrecise => '正確';

  @override
  String get temperatureConservative => '保守的';

  @override
  String get temperatureNeutral => '標準';

  @override
  String get temperatureCreative => '創造的';

  @override
  String get temperatureRandom => 'ランダム';

  @override
  String xToolsCount(Object n) {
    return '$n ツール';
  }

  @override
  String get newConversationDefault => '新規会話';

  @override
  String get usageDashboard => '使用量ダッシュボード';

  @override
  String get globalUsageDashboard => '全体の使用量ダッシュボード';

  @override
  String sessionUsageTitle(Object name) {
    return '$name の使用量';
  }

  @override
  String get noSessionData => 'セッションデータがありません';

  @override
  String get noUsageData => '使用量データがありません';

  @override
  String get overview => '概要';

  @override
  String get statMessages => 'メッセージ';

  @override
  String get totalMessages => '総メッセージ数';

  @override
  String get inputTokens => '入力トークン';

  @override
  String get outputTokens => '出力トークン';

  @override
  String get totalCostLabel => '総コスト';

  @override
  String get tokenDistribution => 'トークン分布';

  @override
  String get modelInfo => 'モデル情報';

  @override
  String get quotaLimitSection => 'クォータ制限';

  @override
  String get usageCurve => '使用量推移';

  @override
  String get totalSessions => '総セッション数';

  @override
  String get totalTokens => '総トークン数';

  @override
  String get byModel => 'モデル別';

  @override
  String get allSessions => 'すべてのセッション';

  @override
  String moreSessionsNoData(Object count) {
    return '他 $count 件のセッションに使用量データがありません';
  }

  @override
  String get inputLabel => '入力';

  @override
  String get outputLabel => '出力';

  @override
  String get noQuotaLimit => 'クォータ制限は設定されていません';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count セッション';
  }

  @override
  String get granMinute => '分';

  @override
  String get granHour => '時';

  @override
  String get granDay => '日';

  @override
  String get granMonth => '月';

  @override
  String get granYear => '年';

  @override
  String get selectDate => '日付を選択';

  @override
  String get rangeStart => '開始';

  @override
  String get rangeEnd => '終了';

  @override
  String get startDateHelp => '開始日';

  @override
  String get endDateHelp => '終了日';

  @override
  String get tokenToggle => 'トークン';

  @override
  String get costToggle => 'コスト';

  @override
  String chartLegendCost(Object symbol) {
    return 'コスト ($symbol)';
  }

  @override
  String get noSessionConfig => 'セッション設定なし';

  @override
  String get resetApiKey => 'APIキーをリセット';

  @override
  String get resetApiKeyConfirm =>
      'このセッションのAPIキーをリセットしますか？リセット後、古いキーは直ちに無効になり、古いキーを使用する外部リクエストはアクセスできなくなります。';

  @override
  String get confirmReset => 'リセットを確認';

  @override
  String get connectorSkillRelation => 'コネクタとスキルの関連説明';

  @override
  String modelPricing(Object unit) {
    return 'モデル料金 ($unit/100万トークン)';
  }

  @override
  String get billingInfoLabel => '課金情報';

  @override
  String get cumulativeInputTokens => '累積入力トークン';

  @override
  String get cumulativeOutputTokens => '累積出力トークン';

  @override
  String get cumulativeCost => '累積コスト';

  @override
  String get basicInfoLabel => '基本情報';

  @override
  String get sessionName => 'セッション名';

  @override
  String get organization => '組織';

  @override
  String get groupLabel => 'グループ';

  @override
  String get notSpecified => '未指定';

  @override
  String get notGrouped => '未グループ';

  @override
  String get boundModel => '紐付けモデル';

  @override
  String get relatedPrompt => '関連プロンプト';

  @override
  String get messageCountLabel => 'メッセージ数';

  @override
  String get serviceConfigLabel => 'サービス設定';

  @override
  String get serviceAddress => 'サービスアドレス';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => 'モデルMCP';

  @override
  String get sessionMcp => 'セッションMCP';

  @override
  String get notBound => '未紐付け';

  @override
  String get addMcpHint => 'モデル管理またはチャット入力ボックスでMCPサービスを追加できます';

  @override
  String get usageQuotaLabel => '使用量クォータ';

  @override
  String get noAuthAccess => '認証なしアクセス';

  @override
  String get noAuthEnabledDesc => '⚠️ 認証無効、誰でもアクセス可能';

  @override
  String get noAuthDisabledDesc => '有効：APIキーなしでアクセス';

  @override
  String get disableSession => 'セッションを無効化';

  @override
  String get disabledEnabledDesc => '⚠️ 無効化済み、呼び出しはエラーを返します';

  @override
  String get disabledDisabledDesc => '有効：このセッションは呼び出し不可になります';

  @override
  String get systemPromptHint => 'このセッションのロール/動作を設定（例：あなたはプロの法律アドバイザーです...）';

  @override
  String get systemPromptDesc =>
      '最優先の指示として設定され、サードパーティリクエストに自動注入されます。空の場合は注入されません。';

  @override
  String get tokenUsageLimit => 'トークン使用量制限';

  @override
  String costBudgetLimit(Object unit) {
    return 'コスト予算制限 ($unit)';
  }

  @override
  String get requestLimit => 'リクエスト制限';

  @override
  String get noLimit => '制限なし';

  @override
  String get enableUsageLimit => '使用量制限を有効化';

  @override
  String get reachLimitReject => '制限到達後、新しいリクエストは拒否されます';

  @override
  String get resetPeriod => 'リセット周期';

  @override
  String get resetPeriodNever => '自動リセットなし';

  @override
  String get resetPeriodDaily => '毎日リセット';

  @override
  String get resetPeriodMonthly => '毎月リセット';

  @override
  String get quotaExhausted => 'クォータ枯渇';

  @override
  String get currentUsageStatus => '現在の使用量状況';

  @override
  String get quotaTokenLabel => 'トークン';

  @override
  String get quotaCostLabel => 'コスト';

  @override
  String get quotaRequestLabel => 'リクエスト';

  @override
  String get manualResetUsage => '使用量を手動リセット';

  @override
  String get manualResetConfirmDesc => '手動リセットを実行しますか';

  @override
  String get manualResetWarning =>
      'リセット後、現在の期間のトークン使用量、コスト、リクエスト数がクリアされ、期間開始時刻が現在時刻に更新されます。';

  @override
  String get tokenUsage => 'トークン使用量';

  @override
  String get costUsage => 'コスト使用量';

  @override
  String get resetValue => 'リセット';

  @override
  String get apiKeyReset => 'APIキーをリセットしました';

  @override
  String get securitySettings => 'セキュリティ';

  @override
  String get sensitiveInfoMasking => '機微情報のマスキング';

  @override
  String get sensitiveInfoMaskingDesc =>
      '有効にすると、モデルに送信されるメッセージおよびローカルの監査ログ内の該当情報が「*」に置換され、平文のプライバシー漏洩を防ぎます。';

  @override
  String get maskPhoneTitle => '電話番号のマスキング';

  @override
  String get maskPhoneSubtitle => 'メッセージ内の電話番号を「*」に置換';

  @override
  String get maskIdCardTitle => '身分証番号のマスキング';

  @override
  String get maskIdCardSubtitle => 'メッセージ内の身分証番号を「*」に置換';

  @override
  String get sessionDetails => 'セッション詳細';

  @override
  String get modelDetails => 'モデル詳細';

  @override
  String modelDetailsWithPlatform(String platform) {
    return 'モデル詳細 · $platform';
  }

  @override
  String get japanese => '日本語';

  @override
  String get japaneseDesc => '日本語';

  @override
  String get korean => '韓国語';

  @override
  String get koreanDesc => '韓国語';

  @override
  String get thai => 'タイ語';

  @override
  String get thaiDesc => 'タイ語';

  @override
  String get vietnamese => 'ベトナム語';

  @override
  String get vietnameseDesc => 'ベトナム語';

  @override
  String get french => 'フランス語';

  @override
  String get frenchDesc => 'フランス語';

  @override
  String get german => 'ドイツ語';

  @override
  String get germanDesc => 'ドイツ語';
}
