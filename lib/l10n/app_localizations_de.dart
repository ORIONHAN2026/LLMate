// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => 'Intelligenter Chat-Assistent';

  @override
  String get feedback => 'Feedback';

  @override
  String get modelManagement => 'Modellverwaltung';

  @override
  String get connectorManagement => 'Connector (MCP)';

  @override
  String get domainManagement => 'Dienstverwaltung';

  @override
  String get otherSettings => 'Weitere Einstellungen';

  @override
  String get languageSettings => 'Sprache';

  @override
  String get skinSettings => 'Design';

  @override
  String get followSystem => 'System folgen';

  @override
  String get followSystemDesc => 'Helles/Dunkles Modus automatisch umschalten';

  @override
  String get lightMode => 'Hell';

  @override
  String get lightModeDesc => 'Immer helles Design verwenden';

  @override
  String get darkMode => 'Dunkel';

  @override
  String get darkModeDesc => 'Immer dunkles Design verwenden';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => 'Vereinfachtes Chinesisch';

  @override
  String get english => 'English';

  @override
  String get englishDesc => 'English';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get close => 'Schließen';

  @override
  String get remove => 'Entfernen';

  @override
  String get clear => 'Leeren';

  @override
  String get search => 'Suchen';

  @override
  String get noData => 'Keine Daten';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get send => 'Senden';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get copyContent => 'Inhalt kopieren';

  @override
  String get retry => 'Wiederholen';

  @override
  String get done => 'Fertig';

  @override
  String get back => 'Zurück';

  @override
  String get previousStep => 'Zurück';

  @override
  String get settings => 'Einstellungen';

  @override
  String get systemPrompt => 'System-Prompt';

  @override
  String get temperature => 'Temperatur';

  @override
  String get replyLanguage => 'Antwortsprache';

  @override
  String get newSession => 'Neue Sitzung';

  @override
  String get sessionList => 'Sitzungsliste';

  @override
  String get rename => 'Umbenennen';

  @override
  String get shareConversation => 'Konversation teilen';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get importData => 'Daten importieren';

  @override
  String get clearConversation => 'Konversation löschen';

  @override
  String get deleteConversation => 'Konversation löschen';

  @override
  String get deleteConfirm => 'Löschbestätigung';

  @override
  String get deleteConfirmMsg => 'Möchten Sie wirklich löschen?';

  @override
  String removeConfirmMsg(Object name) {
    return 'Möchten Sie „$name“ wirklich entfernen?';
  }

  @override
  String get addModel => 'Modell hinzufügen';

  @override
  String get copyModel => 'Modell kopieren';

  @override
  String get modelName => 'Modellname';

  @override
  String get modelProvider => 'Anbieter';

  @override
  String get modelApiKey => 'API-Schlüssel';

  @override
  String get modelBaseUrl => 'Basis-URL';

  @override
  String get modelMaxTokens => 'Max. Tokens';

  @override
  String get thinkTag => 'Denk-Tag';

  @override
  String get thinkTagDesc => 'Denkprozess-Tag des Modells';

  @override
  String get addService => 'Dienst hinzufügen';

  @override
  String get removeService => 'Dienst entfernen';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get fullTest => 'Volltest';

  @override
  String get connectAndAdd => 'Verbinden & Hinzufügen';

  @override
  String get addCustomConnector => 'Benutzerdefinierten Connector hinzufügen';

  @override
  String get clearKey => 'Schlüssel löschen';

  @override
  String get fetchTools => 'Tools abrufen';

  @override
  String get fetchModels => 'Modelle abrufen';

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get regenerate => 'Neu generieren';

  @override
  String get regenerateFromHere => 'Hier neu generieren';

  @override
  String get regenerateLastReply => 'Letzte Antwort neu generieren';

  @override
  String get regenerateThisReply => 'Diese Antwort neu generieren';

  @override
  String get createNewChatFromHere => 'Neuer Chat ab hier';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteReply => 'Antwort löschen';

  @override
  String get screenshot => 'Bildschirmfoto';

  @override
  String get entireConversation => 'Gesamte Konversation';

  @override
  String get currentRound => 'Aktuelle Runde';

  @override
  String get currentMessage => 'Aktuelle Nachricht';

  @override
  String get memoryConfig => 'Speicherkonfiguration';

  @override
  String get clearMcpServices => 'MCP-Dienste löschen';

  @override
  String get selectFile => 'Datei auswählen';

  @override
  String get selectWorkingDir => 'Arbeitsverzeichnis auswählen';

  @override
  String get confirmDeleteTitle => 'Löschen bestätigen';

  @override
  String get deleteSessionTitle => 'Sitzung löschen';

  @override
  String get favorites => 'Favoriten';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get earlier => 'Früher';

  @override
  String get removeServiceTitle => 'Dienst entfernen';

  @override
  String get removeMcpServiceTitle => 'MCP-Dienst entfernen';

  @override
  String get noActiveSession => 'Keine aktive Sitzung';

  @override
  String get presetRoleApplied => 'Vordefinierte Rolle angewendet';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get fileOpenFailed => 'Datei konnte nicht geöffnet werden';

  @override
  String get enterMessageContent => 'Bitte Nachrichteninhalt eingeben';

  @override
  String get copyMessageContent => 'Nachrichteninhalt kopieren';

  @override
  String get apiKeyHint => 'API-Schlüssel eingeben';

  @override
  String get modelNameHint => 'Modellname eingeben';

  @override
  String get messageHint => 'Nachrichteninhalt eingeben...';

  @override
  String get apiUrlHint => 'API-URL eingeben';

  @override
  String get commandHint => 'Befehlsinhalt eingeben';

  @override
  String get enterCommandContent => 'Bitte Befehlsinhalt eingeben';

  @override
  String get modelSearchHint =>
      'Modellname eingeben, z. B. gpt-4o-mini, claude-3-haiku';

  @override
  String get roleDescHint =>
      'Rollenbeschreibung eingeben, um das Verhalten und den Antwortstil des Modells zu leiten...';

  @override
  String get toolLogicHint => 'Beschreibung der Tool-Logik eingeben...';

  @override
  String get typeCommandOrSearch => 'Befehl eingeben oder suchen...';

  @override
  String get searchMcp => 'MCP-Dienste suchen...';

  @override
  String get cronExample => 'z. B. 0 9 * * * (täglich um 9:00)';

  @override
  String get config => 'Konfig';

  @override
  String get pasteMcpCode => 'MCP-Code einfügen';

  @override
  String get fileNameLabel => 'Dateiname';

  @override
  String get fileSizeLabel => 'Größe';

  @override
  String get fileTypeLabel => 'Typ';

  @override
  String get filePathLabel => 'Pfad';

  @override
  String get aliyun => 'Alibaba Cloud';

  @override
  String get tencentCloud => 'Tencent Cloud';

  @override
  String get modelscope => 'ModelScope';

  @override
  String get goToAliyun => 'Zu Alibaba Cloud';

  @override
  String pleaseEnter(Object field) {
    return '$field eingeben';
  }

  @override
  String get more => 'Mehr';

  @override
  String get copyFailed => 'Kopieren fehlgeschlagen';

  @override
  String get invalidLinkFormat => 'Ungültiges Linkformat';

  @override
  String get cannotOpenLink => 'Link kann nicht geöffnet werden';

  @override
  String get linkOpenedInBrowser => 'Link im Browser geöffnet';

  @override
  String get cannotOpenThisLinkType =>
      'Dieser Linktyp kann nicht geöffnet werden';

  @override
  String get openLinkFailed => 'Öffnen des Links fehlgeschlagen';

  @override
  String get fileOpened => 'Datei geöffnet';

  @override
  String get cannotOpenFile => 'Datei kann nicht geöffnet werden';

  @override
  String get openFileFailed => 'Öffnen der Datei fehlgeschlagen';

  @override
  String get sessionNotFoundForMessage =>
      'Sitzung für diese Nachricht nicht gefunden';

  @override
  String get messageNotFound => 'Nachricht nicht gefunden';

  @override
  String get regenerateFailed => 'Neugenerierung fehlgeschlagen';

  @override
  String get cannotFindQuestion =>
      'Die entsprechende Frage konnte nicht gefunden werden';

  @override
  String get noAiReplyFound => 'Keine KI-Antwort gefunden';

  @override
  String get cannotRegenerateInvalidIndex =>
      'Kann nicht neu generieren: Ungültiger Nachrichtenindex';

  @override
  String get editMessageTitle => 'Nachricht bearbeiten';

  @override
  String get messageContentCannotBeEmpty =>
      'Nachrichteninhalt darf nicht leer sein';

  @override
  String get newChatFromHistory => 'Neuer Chat aus dem Verlauf';

  @override
  String get newChatCreatedFromHere => 'Neuer Chat ab hier erstellt';

  @override
  String get createNewChatFailed => 'Erstellen des neuen Chats fehlgeschlagen';

  @override
  String get thinking => 'Denkt...';

  @override
  String get callingTool => 'Tool wird aufgerufen';

  @override
  String get toolCallRecord => 'Tool-Aufrufprotokoll';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get deleteMessageFailed => 'Löschen der Nachricht fehlgeschlagen';

  @override
  String get duration => 'Dauer';

  @override
  String get calculating => 'Berechnen...';

  @override
  String get speed => 'Geschwindigkeit';

  @override
  String get outputTokensLabel => 'Ausgabe-Tokens';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get collapseSidebar => 'Seitenleiste einklappen';

  @override
  String get expandSidebar => 'Seitenleiste ausklappen';

  @override
  String get collapseRightSidebar => 'Rechte Seitenleiste einklappen';

  @override
  String get expandRightSidebar => 'Rechte Seitenleiste ausklappen';

  @override
  String get unfavorite => 'Aus Favoriten entfernen';

  @override
  String get favoriteSession => 'Zu Favoriten hinzufügen';

  @override
  String get user => 'Benutzer';

  @override
  String get assistant => 'Assistent';

  @override
  String get noMemory => 'Kein Speicher';

  @override
  String get noFiles => 'Keine Dateien';

  @override
  String get fileInfo => 'Dateiinfo';

  @override
  String get fileContent => 'Dateiinhalt';

  @override
  String get noContentPreview => 'Keine Inhaltsvorschau';

  @override
  String get fileContentCopied => 'Dateiinhalt in Zwischenablage kopiert';

  @override
  String get selectOrCreateSession => 'Bitte Sitzung auswählen oder erstellen';

  @override
  String get invalidSessionIndex => 'Ungültiger Sitzungsindex';

  @override
  String get cannotOpenEmailApp => 'E-Mail-App kann nicht geöffnet werden';

  @override
  String get sendEmailFailed => 'E-Mail senden fehlgeschlagen';

  @override
  String get memorySummary => 'Speicherzusammenfassung';

  @override
  String get recentConversations => 'Kürzliche Konversationen';

  @override
  String get sessionFiles => 'Sitzungsdateien';

  @override
  String get files => 'Dateien';

  @override
  String get memory => 'Speicher';

  @override
  String get processed => 'Verarbeitet';

  @override
  String todayTime(Object time) {
    return 'Heute $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month/$day $time';
  }

  @override
  String messageCount(Object count) {
    return '$count Nachrichten';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action fehlgeschlagen: $error';
  }

  @override
  String xDone(Object action) {
    return '$action abgeschlossen';
  }

  @override
  String get copiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String get replyDeleted => 'Antworten gelöscht';

  @override
  String get deleteReplyFailed => 'Löschen der Antworten fehlgeschlagen';

  @override
  String get asConversationContinues =>
      'Wenn die Konversation fortschreitet, zeichnet die KI\nden Speicher automatisch auf und komprimiert ihn';

  @override
  String get whenAiCreatesFiles =>
      'Wenn KI-Tools Dateien in der Konversation erstellen oder ändern,\nerscheinen sie hier';

  @override
  String get deleteSessionTitle_warning =>
      'Diese Aktion kann nicht rückgängig gemacht werden';

  @override
  String get pleaseSetupModel => 'Bitte ein Modell einrichten';

  @override
  String get clickToSelectModel =>
      'Klicken Sie oben, um ein Chat-Modell auszuwählen';

  @override
  String get selectModel => 'Modell auswählen';

  @override
  String get noAvailableModels => 'Keine verfügbaren Modelle';

  @override
  String get sessionNotFoundCannotSelectModel =>
      'Sitzung nicht gefunden, Modell kann nicht ausgewählt werden';

  @override
  String get inputHint =>
      'Nachricht hier eingeben, ↵ zum Senden, Umschalt+↵ für neue Zeile';

  @override
  String get stopAnswer => 'Antwort stoppen';

  @override
  String waitingAttachments(Object count) {
    return 'Warten auf Verarbeitung von $count Anhängen';
  }

  @override
  String get sendMessageAction => 'Nachricht senden';

  @override
  String get deepThinkEnabled => 'Tiefes Denken: An';

  @override
  String get deepThinkDisabled => 'Tiefes Denken: Aus';

  @override
  String get deepThink => 'Tiefes Denken';

  @override
  String get workingDirectoryLabel => 'Arbeitsverzeichnis';

  @override
  String workingDirectoryPath(Object path) {
    return 'Arbeitsverzeichnis: $path';
  }

  @override
  String get setWorkingDirHint =>
      'Arbeitsverzeichnis festlegen (Standard-Speicherort)';

  @override
  String get workingDirSet => 'Arbeitsverzeichnis festgelegt';

  @override
  String get workingDirCleared => 'Arbeitsverzeichnis geleert';

  @override
  String get noWorkingDir =>
      'Bitte zuerst das Vertragsdatei-Verzeichnis festlegen';

  @override
  String get parseContract => 'Vertrag analysieren';

  @override
  String get parseContractHint =>
      'Vertragsdateien im Arbeitsverzeichnis analysieren';

  @override
  String get parseContractPrompt =>
      'Folgende Dokumentdateien befinden sich im Arbeitsverzeichnis. Bestimmen Sie zuerst, welche Dateien tatsächliche Vertragsdokumente sind (keine Anhänge, Beschreibungen oder andere Nicht-Vertragsdateien). Verwenden Sie dann nur für als Verträge bestätigte Dateien das Tool contract_inspect, um die Informationen jedes Vertrags zu schreiben.\n\nSchreibregeln:\n- Rufen Sie für jeden Vertrag zuerst action=add auf, um einen Vertragseintrag zu erstellen (füllen Sie contractName, contractType, paymentClause, paymentSchedule, breachClause, liabilityClause, startDate, endDate, signingDate usw.)\n- Rufen Sie dann für jede Partei action=addParty auf und fügen Sie nacheinander Partei A, Partei B usw. hinzu.\n- Erläutern Sie in Ihrer Antwort auch kurz, welche Dateien als Nicht-Verträge bestimmt wurden und warum.';

  @override
  String get contractPoints => 'Vertragspunkte';

  @override
  String get noContracts => 'Keine Vertragspunkte';

  @override
  String get contractParsing =>
      'Vertragspunkte erscheinen hier nach der Analyse';

  @override
  String get contractParty => 'Parteien';

  @override
  String get contractPaymentClause => 'Zahlungsklausel';

  @override
  String get contractPaymentSchedule => 'Zahlungsplan';

  @override
  String get contractBreachClause => 'Vertragsverletzungsklausel';

  @override
  String get contractLiability => 'Haftung';

  @override
  String get contractPeriod => 'Vertragslaufzeit';

  @override
  String get contractSigningDate => 'Unterzeichnungsdatum';

  @override
  String get contractTypeLabel => 'Vertragstyp';

  @override
  String nRounds(Object n) {
    return '$n Runden';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return 'Speicherkonfiguration: Letzte $label Konversationen behalten';
  }

  @override
  String get closeMemory => 'Speicher schließen';

  @override
  String get noContext => 'Kein Kontext';

  @override
  String keepXRounds(Object n) {
    return '$n Runden behalten';
  }

  @override
  String lastXRounds(Object n) {
    return 'Letzte $n Runden';
  }

  @override
  String get defaultMemory => 'Standard';

  @override
  String get longConversation => 'Lange Konversation';

  @override
  String get veryLongConversation => 'Sehr lange Konversation';

  @override
  String get noMatchingResults => 'Keine übereinstimmenden Ergebnisse';

  @override
  String get memoryClosed => 'Speicher geschlossen';

  @override
  String memoryConfigSet(Object n) {
    return 'Speicherkonfiguration: $n Runden';
  }

  @override
  String get attach => 'Anhang';

  @override
  String get selectMcpTool => 'Connector auswählen';

  @override
  String get noMcpTool => 'Kein Connector';

  @override
  String get viewMcpToolDetail => 'MCP-Tool-Details anzeigen';

  @override
  String get clickToSelectMcpTool => 'Klicken, um MCP-Tool auszuwählen';

  @override
  String get noMcpToolConfigured => 'Kein MCP-Tool konfiguriert';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return 'Tool-Workflow: $desc';
  }

  @override
  String get clickToDesignWorkflow =>
      'Gemeinsame Nutzungslogik von Connector und Skill festlegen';

  @override
  String get alreadySet => 'Festgelegt';

  @override
  String get toolWorkflowDescTitle => 'Tool-Workflow-Beschreibung';

  @override
  String get enterToolWorkflowDesc => 'Tool-Workflow-Beschreibung eingeben...';

  @override
  String get relationDescCleared => 'Beziehungsbeschreibung geleert';

  @override
  String get relationDescSaved => 'Beziehungsbeschreibung gespeichert';

  @override
  String get noMcpServiceConfigured => 'Kein MCP-Dienst konfiguriert';

  @override
  String mcpServiceList(Object n) {
    return 'MCP-Dienstliste ($n)';
  }

  @override
  String get mcpServiceTitle => 'MCP-Dienst';

  @override
  String get enabledStatus => 'Aktiviert';

  @override
  String get disabledStatus => 'Deaktiviert';

  @override
  String commandLabel(Object cmd) {
    return 'Befehl: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return 'Argumente: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return 'Verzeichnis: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return 'Zeitüberschreitung: ${n}s';
  }

  @override
  String get mcpListHint =>
      'Tipp: Doppelklick auf MCP-Button für Liste, einfacher Klick zum Umschalten';

  @override
  String get mcpEnabledMsg =>
      'MCP-Tools aktiviert, werden beim Senden automatisch aufgerufen';

  @override
  String get mcpDisabledMsg => 'MCP-Tools deaktiviert';

  @override
  String get clearMcpService => 'MCP-Dienst löschen';

  @override
  String get unbindAction => 'Trennen';

  @override
  String xTools(Object n) {
    return '$n Tools';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'MCP-Dienst ausgewählt: $name';
  }

  @override
  String get mcpToolsDisabled => 'MCP-Tools deaktiviert';

  @override
  String get createAction => 'Erstellen';

  @override
  String get noModelBound => 'Kein Modell gebunden';

  @override
  String serviceUnavailable(Object error) {
    return 'Entschuldigung, Dienst vorübergehend nicht verfügbar, $error';
  }

  @override
  String get confirmClear => 'Leeren bestätigen';

  @override
  String get clearHistoryConfirmMsg =>
      'Möchten Sie wirklich den gesamten Konversationsverlauf löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get historyCleared => 'Verlauf geleert';

  @override
  String folderPath(Object path) {
    return 'Ordner: $path';
  }

  @override
  String toolList(Object n) {
    return 'Tool-Liste ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... $n weitere Tools';
  }

  @override
  String get jsonCopied => 'JSON kopiert';

  @override
  String get mcpDetail => 'MCP-Detail';

  @override
  String toolsRefreshed(Object n) {
    return '$n Tools aktualisiert';
  }

  @override
  String refreshFailed(Object error) {
    return 'Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get refreshAction => 'Aktualisieren';

  @override
  String toolsFetched(Object n) {
    return '$n Tools abgerufen';
  }

  @override
  String fetchFailed(Object error) {
    return 'Abrufen fehlgeschlagen: $error';
  }

  @override
  String get modelConfigNotFound => 'Modellkonfiguration nicht gefunden';

  @override
  String get modelProviderNotConfigured => 'Modellanbieter nicht konfiguriert';

  @override
  String get screenshotFailed =>
      'Bildschirmfoto fehlgeschlagen: Render-Objekt nicht gefunden';

  @override
  String get generateImageFailed => 'Bildgenerierung fehlgeschlagen';

  @override
  String get messageScreenshotCopied =>
      'Nachrichten-Screenshot in Zwischenablage kopiert';

  @override
  String get currentRoundScreenshotCopied =>
      'Runden-Screenshot in Zwischenablage kopiert';

  @override
  String get fullConversationScreenshotCopied =>
      'Screenshot der gesamten Konversation in Zwischenablage kopiert';

  @override
  String get noMessagesInConversation =>
      'Keine Nachrichten in der Konversation';

  @override
  String get cannotFindMessage => 'Nachricht konnte nicht gefunden werden';

  @override
  String get cannotFindCompleteRound =>
      'Keine vollständige Konversationsrunde gefunden';

  @override
  String partialScreenshot(Object n, Object total) {
    return 'Einige Nachrichten konnten nicht erfasst werden, $n/$total Nachrichten erfasst';
  }

  @override
  String get renderObjectStillDrawing =>
      'Bildschirmfoto fehlgeschlagen: Render-Objekt wird noch gezeichnet';

  @override
  String screenshotCopied(Object type) {
    return '$type-Screenshot in Zwischenablage kopiert';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return '$type-Screenshot fehlgeschlagen: $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return 'Zusammenführung des Screenshots fehlgeschlagen: $error';
  }

  @override
  String copyImageFailed(Object error) {
    return 'Bild kopieren fehlgeschlagen: $error';
  }

  @override
  String get unsupportedOS => 'Nicht unterstütztes Betriebssystem';

  @override
  String desktopCopyFailed(Object error) {
    return 'Desktop-Bildkopie fehlgeschlagen: $error';
  }

  @override
  String get noClipboardTool =>
      'Kein Zwischenablage-Tool verfügbar (xclip oder wl-copy)';

  @override
  String get cannotFindRenderObject =>
      'Nachrichten-Render-Objekt nicht gefunden';

  @override
  String get cronExpression => 'Cron-Ausdruck';

  @override
  String get cronFormat =>
      'Format: Minute Stunde Tag Monat Wochentag (5 Felder)';

  @override
  String get messageContentLabel => 'Nachrichteninhalt';

  @override
  String get enableTask => 'Aufgabe aktivieren';

  @override
  String get pleaseEnterCron => 'Bitte Cron-Ausdruck eingeben';

  @override
  String get cronFormatError => 'Cron-Formatfehler (5 Felder erforderlich)';

  @override
  String get daily0900 => 'Täglich 09:00';

  @override
  String get daily1200 => 'Täglich 12:00';

  @override
  String get daily1800 => 'Täglich 18:00';

  @override
  String get workday0900 => 'Werktags 09:00';

  @override
  String get every30min => 'Alle 30 Min';

  @override
  String get every2h => 'Alle 2 Stunden';

  @override
  String get processFailedStatus => 'Verarbeitung fehlgeschlagen';

  @override
  String get processingStatus => 'Wird verarbeitet';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - Inhaltsvorschau';
  }

  @override
  String get contentCopiedToClipboard => 'Inhalt in Zwischenablage kopiert';

  @override
  String get fileProcessFailed => 'Dateiverarbeitung fehlgeschlagen';

  @override
  String get pleaseReupload =>
      'Bitte Datei erneut hochladen oder Support kontaktieren';

  @override
  String get processingFileStatus => 'Datei wird verarbeitet...';

  @override
  String get imageFile => 'Bilddatei';

  @override
  String get documentFile => 'Dokumentdatei';

  @override
  String get textFile => 'Textdatei';

  @override
  String get codeFile => 'Codedatei';

  @override
  String get officeDocument => 'Bürodokument';

  @override
  String get webLink => 'Web-Link';

  @override
  String get folderType => 'Ordner';

  @override
  String get otherFile => 'Andere Datei';

  @override
  String get defaultConversation => 'Allgemeine Konversation';

  @override
  String modelCopied(Object name) {
    return 'Modell „$name“ erfolgreich kopiert';
  }

  @override
  String copyOf(Object name) {
    return 'Kopie von $name';
  }

  @override
  String copyOfN(Object n, Object name) {
    return 'Kopie von $name ($n)';
  }

  @override
  String get noModels => 'Keine Modelle';

  @override
  String get clickAddModelHint =>
      'Klicken Sie auf die Schaltfläche „Modell hinzufügen“, um zu beginnen';

  @override
  String modelUpdatedNotify(Object name) {
    return 'Modell „$name“ aktualisiert, zugehörige Sitzungseinstellungen synchronisiert';
  }

  @override
  String serviceRemoved(Object name) {
    return 'Dienst entfernt: $name';
  }

  @override
  String get connectorManagementTitle => 'Connector-Verwaltung (MCP)';

  @override
  String get marketplace => 'Marktplatz';

  @override
  String get noMcpServices => 'Keine MCP-Dienste';

  @override
  String get clickToEnterMarketplace =>
      'Klicken Sie auf die +-Schaltfläche, um zum Marktplatz zu gelangen';

  @override
  String fetchToolsFailed(Object error) {
    return 'Tools abrufen fehlgeschlagen: $error';
  }

  @override
  String get removeServiceLabel => 'Dienst entfernen';

  @override
  String get removeServiceConfirm =>
      'Möchten Sie den Dienst wirklich entfernen';

  @override
  String get removeServiceWarning =>
      'Nach dem Entfernen erneut hinzufügen erforderlich';

  @override
  String get jsonConfig => 'JSON-Konfig';

  @override
  String get cannotReadFilePath => 'Dateipfad kann nicht gelesen werden';

  @override
  String get extractingImport => 'Import wird extrahiert...';

  @override
  String importFailed(Object error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get irreversibleAction => 'Diese Aktion ist nicht umkehrbar';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'Modell gelöscht';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'Modell „$name“ erfolgreich gelöscht';
  }

  @override
  String get selectOtherModelFromList =>
      'Wählen Sie ein anderes Modell aus der Liste aus, um Details anzuzeigen';

  @override
  String get unnamedModel => 'Unbenanntes Modell';

  @override
  String get noDescription => 'Keine Beschreibung';

  @override
  String get confirmDeleteModel => 'Möchten Sie das Modell wirklich löschen';

  @override
  String modelDeletedToast(Object name) {
    return 'Modell „$name“ gelöscht';
  }

  @override
  String get addOnlineModel => 'Online-Modell hinzufügen';

  @override
  String get selectProvider => 'Anbieter auswählen';

  @override
  String get configureParams => 'Parameter konfigurieren';

  @override
  String get checkConfig => 'Konfiguration prüfen';

  @override
  String get setName => 'Name festlegen';

  @override
  String get nextStep => 'Weiter';

  @override
  String get selectOnlineProvider => 'Online-Modellanbieter auswählen';

  @override
  String get customProvider => 'Benutzerdefiniert';

  @override
  String get customProviderDesc =>
      'Adresse, API-Schlüssel und Modellname manuell eingeben';

  @override
  String get customProviderConfigTitle =>
      'Benutzerdefinierte Modellkonfiguration';

  @override
  String configureProviderParams(Object provider) {
    return '$provider-Parameter konfigurieren';
  }

  @override
  String get ollamaApiKeyOptional =>
      'Der lokale Ollama-Dienst benötigt normalerweise keinen API-Schlüssel und kann leer bleiben';

  @override
  String get apiAddress => 'API-Adresse';

  @override
  String get defaultApiUrlNote =>
      'Standardmäßige offizielle API-Adresse, kann für lokale oder private Bereitstellungen geändert werden';

  @override
  String get presetModel => 'Vordefinierte Modelle';

  @override
  String get customModel => 'Benutzerdefiniertes Modell';

  @override
  String get enterFullModelName =>
      'Vollständigen Modellnamen eingeben, der vom Anbieter unterstützt wird';

  @override
  String get ollamaRunningModels => 'Ausgeführte Ollama-Modelle';

  @override
  String get refreshModelList => 'Modellliste aktualisieren';

  @override
  String get ollamaStartHint =>
      'Bitte starten Sie zuerst den Ollama-Dienst und laden Sie Modelle herunter,\nklicken Sie dann auf Aktualisieren, um die Modellliste abzurufen';

  @override
  String get modelscopeAvailableModels => 'Verfügbare Modelle auf ModelScope';

  @override
  String get modelscopeApiKeyHint =>
      'Bitte stellen Sie sicher, dass der API-Schlüssel korrekt ist,\nklicken Sie dann auf Aktualisieren, um die Modellliste abzurufen';

  @override
  String get setModelName => 'Modellname festlegen';

  @override
  String get configSummary => 'Konfigurationsübersicht';

  @override
  String get providerLabel => 'Anbieter';

  @override
  String get platformLabel => 'Plattform';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get modelLabel => 'Modell';

  @override
  String get customSuffix => '(Benutzerdefiniert)';

  @override
  String get notSelected => 'Nicht ausgewählt';

  @override
  String get customModelName => 'Benutzerdefinierter Modellname';

  @override
  String enterModelNameHint(Object provider) {
    return 'Modellname eingeben, z. B. $provider-Chat';
  }

  @override
  String get modelNameSuggestion =>
      'Verwenden Sie einen aussagekräftigen Namen zur leichten Identifizierung';

  @override
  String get testConnectionDesc => 'Modellverbindung und -antwort testen';

  @override
  String get waitingForResponse => 'Warten auf Antwort...';

  @override
  String get configIncomplete => 'Konfiguration unvollständig';

  @override
  String get receivedEmptyResponse => 'Leere Antwort erhalten';

  @override
  String get receivedNoResponse => 'Keine Antwort erhalten';

  @override
  String connectionFailed(Object error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String get contextCap => 'Kontext';

  @override
  String get thinkingCap => 'Denken';

  @override
  String get builtinToolsCap => 'Integrierte Tools';

  @override
  String get structuredCap => 'Strukturiert';

  @override
  String get batchCap => 'Stapel';

  @override
  String get basicInfo => 'Grundinformationen';

  @override
  String get modelParams => 'Modellparameter';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get nameLabel => 'Name';

  @override
  String get apiKeyLabel => 'API-Schlüssel';

  @override
  String get notSetDoubleClickToEdit =>
      'Nicht festgelegt (zum Bearbeiten doppelklicken)';

  @override
  String get apiKeySaved => 'API-Schlüssel gespeichert';

  @override
  String get modelNameCannotBeEmpty => 'Modellname darf nicht leer sein';

  @override
  String get modelNameSaved => 'Modellname gespeichert';

  @override
  String get modelSaved => 'Modell gespeichert';

  @override
  String get temperatureLabel => 'Temperatur';

  @override
  String get precise => 'Präzise';

  @override
  String get neutral => 'Neutral';

  @override
  String get creative => 'Kreativ';

  @override
  String get temperatureDescription =>
      'Steuert Zufälligkeit und Kreativität der Antworten. Niedrigere Werte sind konservativer, höhere Werte kreativer.';

  @override
  String get modelRoleSetting => 'Modellrollen-Einstellung';

  @override
  String get presetRole => 'Vordefinierte Rolle';

  @override
  String get roleSettingDescription =>
      'Die Rolleneinstellung wird zu Beginn jeder Konversation an das Modell gesendet, um Rolle und Verhalten zu definieren. Passen Sie sie an die Rolle an, die das Modell spielen soll.';

  @override
  String get selectPresetRole => 'Vordefinierte Rolle auswählen';

  @override
  String get generalAssistant => 'Allgemeiner Assistent';

  @override
  String get friendlyAssistantDesc =>
      'Freundlicher, professioneller KI-Assistent';

  @override
  String get spellCheck => 'Rechtschreibprüfung';

  @override
  String get spellCheckDesc => 'Experte für Rechtschreibprüfung';

  @override
  String get codeExpert => 'Code-Experte';

  @override
  String get codeExpertDesc =>
      'Technischer Experte für Programmierung und Entwicklung';

  @override
  String get legalExpert => 'Rechtsexperte';

  @override
  String get legalExpertDesc => 'Professioneller Rechtsberater';

  @override
  String get copywriter => 'Texter';

  @override
  String get copywriterDesc =>
      'Experte für kreatives Schreiben und Inhaltserstellung';

  @override
  String get dataAnalyst => 'Datenanalyst';

  @override
  String get dataAnalystDesc => 'Experte für Datenanalyse und Statistik';

  @override
  String get educationTutor => 'Lernbetreuer';

  @override
  String get educationTutorDesc => 'Geduldiger Lehrexperte';

  @override
  String get businessConsultant => 'Unternehmensberater';

  @override
  String get businessConsultantDesc =>
      'Experte für Unternehmensführung und Strategie';

  @override
  String get psychologist => 'Psychologe';

  @override
  String get psychologistDesc => 'Professioneller psychologischer Berater';

  @override
  String get versionLabel => 'Version';

  @override
  String get workModeSettings => 'Arbeitsmodus';

  @override
  String get workModeBusiness => 'Unternehmen';

  @override
  String get workModeBusinessDesc =>
      'Unternehmensverhandlung, Vertragsverwaltung, Strategie';

  @override
  String get workModeFinance => 'Finanzen';

  @override
  String get workModeFinanceDesc =>
      'Finanzanalyse, Steuerplanung, Kostenrechnung';

  @override
  String get workModeLegal => 'Recht';

  @override
  String get workModeLegalDesc =>
      'Rechtserstellung, Compliance-Prüfung, Risikobewertung';

  @override
  String get workModeMarketing => 'Marketing';

  @override
  String get workModeMarketingDesc =>
      'Marketingplanung, Markenpflege, Wettbewerbsanalyse';

  @override
  String get domainSettings => 'Domain-Einstellungen';

  @override
  String get serviceStatus => 'Lokaler Dienst';

  @override
  String get localService => 'Lokaler Dienst';

  @override
  String get serviceStopped => 'Dienst gestoppt';

  @override
  String get serviceRunning => 'Wird ausgeführt';

  @override
  String get serviceStarting => 'Startet...';

  @override
  String get restart => 'Neu starten';

  @override
  String get certificateSettings => 'Zertifikatseinstellungen';

  @override
  String get httpsStatus => 'HTTPS-Status';

  @override
  String get domainAddress => 'Domain-Adresse';

  @override
  String get domainHint => 'z. B. api.example.com';

  @override
  String get domainDesc =>
      'Nach der Einstellung verwendet die Sitzungsdienst-URL diese Adresse. HTTP-Standardport 80, HTTPS-Standardport 443.';

  @override
  String get portSettings => 'Port-Einstellungen';

  @override
  String get httpPort => 'HTTP-Port';

  @override
  String get httpsPort => 'HTTPS-Port';

  @override
  String get portDesc =>
      'HTTP-Lauschport, Standard 80. HTTPS-Lauschport, Standard 443. Dienst neu starten, um Änderungen zu übernehmen.';

  @override
  String get sslCertificate => 'SSL-Zertifikat';

  @override
  String get sslPrivateKey => 'Privater Schlüssel';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get httpsEnabled => 'HTTPS';

  @override
  String get httpsEnabledDesc =>
      'Zertifikat hochgeladen, HTTPS automatisch aktiviert';

  @override
  String get httpsDisabledDesc =>
      'Zertifikat (crt/cert + key) hochladen, um HTTPS automatisch zu aktivieren';

  @override
  String get domainInfoDesc =>
      'Nach Konfiguration der Dienstadresse zeigt die Sitzungsdienst-URL diese Adresse an. Externe Clients können über diese Adresse auf die Sitzungs-API (/chat/completions usw.) zugreifen.';

  @override
  String get pleaseEnterDomain => 'Bitte Dienstadresse eingeben';

  @override
  String get domainSaved => 'Dienstkonfiguration gespeichert';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get cny => 'CNY';

  @override
  String get usd => 'USD';

  @override
  String get loadingPageSubtitle => 'Intelligenter Enterprise-KI-Arbeitsplatz';

  @override
  String get billingSettings => 'Abrechnung';

  @override
  String get mcpSettings => 'MCP-Einstellungen';

  @override
  String get currencyTypeLabel => 'Währungstyp';

  @override
  String get inputPriceLabel => 'Eingabepreis';

  @override
  String get outputPriceLabel => 'Ausgabepreis';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/M Tokens';
  }

  @override
  String priceUnitDescription(Object unit) {
    return 'Preis: $unit/Million Tokens. Wird für die kumulative Sitzungskostenberechnung verwendet.';
  }

  @override
  String get examplePriceHint => 'z. B. 0,14';

  @override
  String get mcpBindingDescription =>
      'Nach dem Binden von MCP-Diensten an das Modell werden Sitzungen, die dieses Modell verwenden, diese MCP-Tools automatisch injizieren. Sitzungs-MCP und Modell-MCP werden automatisch zusammengeführt und dedupliziert.';

  @override
  String get addMcpServiceButton => 'MCP-Dienst hinzufügen';

  @override
  String get clearAllMcpBindings => 'Alle MCP-Bindungen löschen';

  @override
  String get selectMcpServiceMultiSelect =>
      'MCP-Dienst auswählen (Mehrfachauswahl)';

  @override
  String get noMcpServiceAddFirst =>
      'Keine MCP-Dienste, bitte zuerst in der MCP-Verwaltung hinzufügen';

  @override
  String confirmWithCount(Object count) {
    return 'OK ($count)';
  }

  @override
  String get temperaturePrecise => 'Präzise';

  @override
  String get temperatureConservative => 'Konservativ';

  @override
  String get temperatureNeutral => 'Neutral';

  @override
  String get temperatureCreative => 'Kreativ';

  @override
  String get temperatureRandom => 'Zufällig';

  @override
  String xToolsCount(Object n) {
    return '$n Tools';
  }

  @override
  String get newConversationDefault => 'Neue Konversation';

  @override
  String get usageDashboard => 'Nutzungs-Dashboard';

  @override
  String get globalUsageDashboard => 'Globales Nutzungs-Dashboard';

  @override
  String sessionUsageTitle(Object name) {
    return 'Nutzung von $name';
  }

  @override
  String get noSessionData => 'Keine Sitzungsdaten';

  @override
  String get noUsageData => 'Keine Nutzungsdaten';

  @override
  String get overview => 'Übersicht';

  @override
  String get statMessages => 'Nachrichten';

  @override
  String get totalMessages => 'Gesamtnachrichten';

  @override
  String get inputTokens => 'Eingabe-Tokens';

  @override
  String get outputTokens => 'Ausgabe-Tokens';

  @override
  String get totalCostLabel => 'Gesamtkosten';

  @override
  String get tokenDistribution => 'Token-Verteilung';

  @override
  String get modelInfo => 'Modellinfo';

  @override
  String get quotaLimitSection => 'Kontingentlimit';

  @override
  String get usageCurve => 'Nutzungskurve';

  @override
  String get totalSessions => 'Gesamtsitzungen';

  @override
  String get totalTokens => 'Gesamttokens';

  @override
  String get byModel => 'Nach Modell';

  @override
  String get allSessions => 'Alle Sitzungen';

  @override
  String moreSessionsNoData(Object count) {
    return 'Weitere $count Sitzungen haben keine Nutzungsdaten';
  }

  @override
  String get inputLabel => 'Eingabe';

  @override
  String get outputLabel => 'Ausgabe';

  @override
  String get noQuotaLimit => 'Kein Kontingentlimit festgelegt';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count Sitzungen';
  }

  @override
  String get granMinute => 'Minute';

  @override
  String get granHour => 'Stunde';

  @override
  String get granDay => 'Tag';

  @override
  String get granMonth => 'Monat';

  @override
  String get granYear => 'Jahr';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get rangeStart => 'Start';

  @override
  String get rangeEnd => 'Ende';

  @override
  String get startDateHelp => 'Startdatum';

  @override
  String get endDateHelp => 'Enddatum';

  @override
  String get tokenToggle => 'Token';

  @override
  String get costToggle => 'Kosten';

  @override
  String chartLegendCost(Object symbol) {
    return 'Kosten ($symbol)';
  }

  @override
  String get noSessionConfig => 'Keine Sitzungskonfiguration';

  @override
  String get resetApiKey => 'API-Schlüssel zurücksetzen';

  @override
  String get resetApiKeyConfirm =>
      'Möchten Sie den API-Schlüssel dieser Sitzung zurücksetzen? Nach dem Zurücksetzen wird der alte Schlüssel sofort ungültig und externe Anfragen mit dem alten Schlüssel können nicht mehr zugreifen.';

  @override
  String get confirmReset => 'Zurücksetzen bestätigen';

  @override
  String get connectorSkillRelation =>
      'Beschreibung der Connector- und Skill-Beziehung';

  @override
  String modelPricing(Object unit) {
    return 'Modellpreis ($unit/M Tokens)';
  }

  @override
  String get billingInfoLabel => 'Abrechnungsinfo';

  @override
  String get cumulativeInputTokens => 'Kumulative Eingabe-Tokens';

  @override
  String get cumulativeOutputTokens => 'Kumulative Ausgabe-Tokens';

  @override
  String get cumulativeCost => 'Kumulative Kosten';

  @override
  String get basicInfoLabel => 'Grundinformationen';

  @override
  String get sessionName => 'Sitzungsname';

  @override
  String get organization => 'Organisation';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get notSpecified => 'Nicht angegeben';

  @override
  String get notGrouped => 'Nicht gruppiert';

  @override
  String get boundModel => 'Gebundenes Modell';

  @override
  String get relatedPrompt => 'Zugehöriger Prompt';

  @override
  String get messageCountLabel => 'Nachrichtenanzahl';

  @override
  String get serviceConfigLabel => 'Dienstkonfig';

  @override
  String get serviceAddress => 'Dienstadresse';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => 'Modell-MCP';

  @override
  String get sessionMcp => 'Sitzungs-MCP';

  @override
  String get notBound => 'Nicht gebunden';

  @override
  String get addMcpHint =>
      'Sie können MCP-Dienste in der Modellverwaltung oder im Chat-Eingabefeld hinzufügen';

  @override
  String get usageQuotaLabel => 'Nutzungskontingent';

  @override
  String get noAuthAccess => 'Zugriff ohne Authentifizierung';

  @override
  String get noAuthEnabledDesc => '⚠️ Auth deaktiviert, jeder kann zugreifen';

  @override
  String get noAuthDisabledDesc => 'Aktiviert: Zugriff ohne API-Schlüssel';

  @override
  String get disableSession => 'Sitzung deaktivieren';

  @override
  String get disabledEnabledDesc =>
      '⚠️ Deaktiviert, Aufrufe geben einen Fehler zurück';

  @override
  String get disabledDisabledDesc =>
      'Aktiviert: Diese Sitzung kann nicht aufgerufen werden';

  @override
  String get systemPromptHint =>
      'Rolle/Verhalten für diese Sitzung festlegen, z. B. Sie sind ein professioneller Rechtsberater...';

  @override
  String get systemPromptDesc =>
      'Als höchstpriorisierte Anweisung festgelegt, automatisch für Drittanbieter-Anfragen injiziert. Leer lassen, um nicht zu injizieren.';

  @override
  String get tokenUsageLimit => 'Token-Nutzungslimit';

  @override
  String costBudgetLimit(Object unit) {
    return 'Kostenbudget-Limit ($unit)';
  }

  @override
  String get requestLimit => 'Anfragenlimit';

  @override
  String get noLimit => 'Kein Limit';

  @override
  String get enableUsageLimit => 'Nutzungslimit aktivieren';

  @override
  String get reachLimitReject =>
      'Neue Anfragen werden nach Erreichen des Limits abgelehnt';

  @override
  String get resetPeriod => 'Zurücksetzungszeitraum';

  @override
  String get resetPeriodNever => 'Keine automatische Zurücksetzung';

  @override
  String get resetPeriodDaily => 'Täglich zurücksetzen';

  @override
  String get resetPeriodMonthly => 'Monatlich zurücksetzen';

  @override
  String get quotaExhausted => 'Kontingent erschöpft';

  @override
  String get currentUsageStatus => 'Aktueller Nutzungsstatus';

  @override
  String get quotaTokenLabel => 'Token';

  @override
  String get quotaCostLabel => 'Kosten';

  @override
  String get quotaRequestLabel => 'Anfragen';

  @override
  String get manualResetUsage => 'Nutzung manuell zurücksetzen';

  @override
  String get manualResetConfirmDesc => 'Manuelles Zurücksetzen bestätigen';

  @override
  String get manualResetWarning =>
      'Nach dem Zurücksetzen werden Token-Nutzung, Kosten und Anzahl der Anfragen der aktuellen Periode gelöscht und der Startzeitpunkt der Periode auf die aktuelle Zeit aktualisiert.';

  @override
  String get tokenUsage => 'Token-Nutzung';

  @override
  String get costUsage => 'Kostennutzung';

  @override
  String get resetValue => 'Zurücksetzen';

  @override
  String get apiKeyReset => 'API-Schlüssel zurückgesetzt';

  @override
  String get securitySettings => 'Sicherheit';

  @override
  String get sensitiveInfoMasking => 'Maskierung sensibler Informationen';

  @override
  String get sensitiveInfoMaskingDesc =>
      'Wenn aktiviert, werden die entsprechenden Informationen in Nachrichten an das Modell und in lokalen Audit-Logs durch \'*\' ersetzt, um Klartext-Datenlecks zu verhindern.';

  @override
  String get maskPhoneTitle => 'Telefonnummern maskieren';

  @override
  String get maskPhoneSubtitle =>
      'Telefonnummern in Nachrichten durch \'*\' ersetzen';

  @override
  String get maskIdCardTitle => 'Ausweisnummern maskieren';

  @override
  String get maskIdCardSubtitle =>
      'Ausweisnummern in Nachrichten durch \'*\' ersetzen';

  @override
  String get sessionDetails => 'Sitzungsdetails';

  @override
  String get modelDetails => 'Modelldetails';

  @override
  String modelDetailsWithPlatform(String platform) {
    return 'Modelldetails · $platform';
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
