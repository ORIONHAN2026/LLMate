// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => 'Assistant de conversation intelligent';

  @override
  String get feedback => 'Retour';

  @override
  String get modelManagement => 'Gestion des modèles';

  @override
  String get connectorManagement => 'Connecteur (MCP)';

  @override
  String get domainManagement => 'Gestion des services';

  @override
  String get otherSettings => 'Autres paramètres';

  @override
  String get resetSystem => 'Réinitialiser le système';

  @override
  String get resetAllSessions => 'Réinitialiser toutes les sessions';

  @override
  String get resetAllModels => 'Réinitialiser tous les modèles';

  @override
  String get resetAllMcp => 'Réinitialiser tous les MCP';

  @override
  String get resetAll => 'Tout réinitialiser';

  @override
  String resetConfirmMsg(Object action) {
    return 'Voulez-vous vraiment $action ? Cette action est irréversible.';
  }

  @override
  String get languageSettings => 'Langue';

  @override
  String get skinSettings => 'Thème';

  @override
  String get followSystem => 'Suivre le système';

  @override
  String get followSystemDesc => 'Bascule automatique clair/sombre';

  @override
  String get lightMode => 'Clair';

  @override
  String get lightModeDesc => 'Toujours utiliser le thème clair';

  @override
  String get darkMode => 'Sombre';

  @override
  String get darkModeDesc => 'Toujours utiliser le thème sombre';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => 'Chinois simplifié';

  @override
  String get english => 'English';

  @override
  String get englishDesc => 'English';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get remove => 'Retirer';

  @override
  String get clear => 'Effacer';

  @override
  String get search => 'Rechercher';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get loading => 'Chargement...';

  @override
  String get send => 'Envoyer';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get copyContent => 'Copier le contenu';

  @override
  String get retry => 'Réessayer';

  @override
  String get done => 'Terminé';

  @override
  String get back => 'Retour';

  @override
  String get previousStep => 'Précédent';

  @override
  String get settings => 'Paramètres';

  @override
  String get systemPrompt => 'Invite système';

  @override
  String get temperature => 'Température';

  @override
  String get replyLanguage => 'Langue de réponse';

  @override
  String get newSession => 'Nouvelle session';

  @override
  String get sessionList => 'Liste des sessions';

  @override
  String get rename => 'Renommer';

  @override
  String get shareConversation => 'Partager la conversation';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get importData => 'Importer les données';

  @override
  String get clearConversation => 'Effacer la conversation';

  @override
  String get deleteConversation => 'Supprimer la conversation';

  @override
  String get deleteConfirm => 'Confirmation de suppression';

  @override
  String get deleteConfirmMsg => 'Voulez-vous vraiment supprimer ?';

  @override
  String removeConfirmMsg(Object name) {
    return 'Voulez-vous vraiment retirer « $name » ?';
  }

  @override
  String get addModel => 'Ajouter un modèle';

  @override
  String get copyModel => 'Copier le modèle';

  @override
  String get modelName => 'Nom du modèle';

  @override
  String get modelProvider => 'Fournisseur';

  @override
  String get modelApiKey => 'Clé API';

  @override
  String get modelBaseUrl => 'URL de base';

  @override
  String get modelMaxTokens => 'Tokens max';

  @override
  String get thinkTag => 'Balise de réflexion';

  @override
  String get thinkTagDesc => 'Balise du processus de réflexion du modèle';

  @override
  String get addService => 'Ajouter un service';

  @override
  String get removeService => 'Retirer le service';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get fullTest => 'Test complet';

  @override
  String get connectAndAdd => 'Connecter et ajouter';

  @override
  String get addCustomConnector => 'Ajouter un connecteur personnalisé';

  @override
  String get clearKey => 'Effacer la clé';

  @override
  String get fetchTools => 'Récupérer les outils';

  @override
  String get fetchModels => 'Récupérer les modèles';

  @override
  String get copyMessage => 'Copier le message';

  @override
  String get regenerate => 'Régénérer';

  @override
  String get regenerateFromHere => 'Régénérer à partir d\'ici';

  @override
  String get regenerateLastReply => 'Régénérer la dernière réponse';

  @override
  String get regenerateThisReply => 'Régénérer cette réponse';

  @override
  String get createNewChatFromHere => 'Nouveau chat à partir d\'ici';

  @override
  String get deleteMessage => 'Supprimer le message';

  @override
  String get deleteReply => 'Supprimer la réponse';

  @override
  String get screenshot => 'Capture d\'écran';

  @override
  String get entireConversation => 'Conversation entière';

  @override
  String get currentRound => 'Tour actuel';

  @override
  String get currentMessage => 'Message actuel';

  @override
  String get memoryConfig => 'Config. mémoire';

  @override
  String get clearMcpServices => 'Effacer les services MCP';

  @override
  String get selectFile => 'Sélectionner un fichier';

  @override
  String get selectWorkingDir => 'Sélectionner le répertoire de travail';

  @override
  String get confirmDeleteTitle => 'Confirmer la suppression';

  @override
  String get deleteSessionTitle => 'Supprimer la session';

  @override
  String get favorites => 'Favoris';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get earlier => 'Antérieur';

  @override
  String get removeServiceTitle => 'Retirer le service';

  @override
  String get removeMcpServiceTitle => 'Retirer le service MCP';

  @override
  String get noActiveSession => 'Aucune session active';

  @override
  String get presetRoleApplied => 'Rôle prédéfini appliqué';

  @override
  String get fileNotFound => 'Fichier introuvable';

  @override
  String get fileOpenFailed => 'Échec de l\'ouverture du fichier';

  @override
  String get enterMessageContent => 'Veuillez saisir le contenu du message';

  @override
  String get copyMessageContent => 'Copier le contenu du message';

  @override
  String get apiKeyHint => 'Saisir la clé API';

  @override
  String get modelNameHint => 'Saisir le nom du modèle';

  @override
  String get messageHint => 'Saisir le contenu du message...';

  @override
  String get apiUrlHint => 'Saisir l\'URL de l\'API';

  @override
  String get commandHint => 'Saisir le contenu de la commande';

  @override
  String get enterCommandContent => 'Veuillez saisir le contenu de la commande';

  @override
  String get modelSearchHint =>
      'Saisir le nom du modèle, ex. gpt-4o-mini, claude-3-haiku';

  @override
  String get roleDescHint =>
      'Saisir la description du rôle pour guider le comportement et le style de réponse du modèle...';

  @override
  String get toolLogicHint =>
      'Saisir la description de la logique de l\'outil...';

  @override
  String get typeCommandOrSearch => 'Saisir une commande ou rechercher...';

  @override
  String get searchMcp => 'Rechercher des services MCP...';

  @override
  String get cronExample => 'ex. 0 9 * * * (tous les jours à 9h00)';

  @override
  String get config => 'Config';

  @override
  String get pasteMcpCode => 'Coller le code MCP';

  @override
  String get fileNameLabel => 'Nom du fichier';

  @override
  String get fileSizeLabel => 'Taille';

  @override
  String get fileTypeLabel => 'Type';

  @override
  String get filePathLabel => 'Chemin';

  @override
  String get aliyun => 'Alibaba Cloud';

  @override
  String get tencentCloud => 'Tencent Cloud';

  @override
  String get modelscope => 'ModelScope';

  @override
  String get goToAliyun => 'Aller à Alibaba Cloud';

  @override
  String pleaseEnter(Object field) {
    return 'Veuillez saisir $field';
  }

  @override
  String get more => 'Plus';

  @override
  String get copyFailed => 'Échec de la copie';

  @override
  String get invalidLinkFormat => 'Format de lien invalide';

  @override
  String get cannotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get linkOpenedInBrowser => 'Lien ouvert dans le navigateur';

  @override
  String get cannotOpenThisLinkType => 'Impossible d\'ouvrir ce type de lien';

  @override
  String get openLinkFailed => 'Échec de l\'ouverture du lien';

  @override
  String get fileOpened => 'Fichier ouvert';

  @override
  String get cannotOpenFile => 'Impossible d\'ouvrir le fichier';

  @override
  String get openFileFailed => 'Échec de l\'ouverture du fichier';

  @override
  String get sessionNotFoundForMessage => 'Session introuvable pour ce message';

  @override
  String get messageNotFound => 'Message introuvable';

  @override
  String get regenerateFailed => 'Échec de la régénération';

  @override
  String get cannotFindQuestion =>
      'Impossible de trouver la question correspondante';

  @override
  String get noAiReplyFound => 'Aucune réponse IA trouvée';

  @override
  String get cannotRegenerateInvalidIndex =>
      'Impossible de régénérer : index de message invalide';

  @override
  String get editMessageTitle => 'Modifier le message';

  @override
  String get messageContentCannotBeEmpty =>
      'Le contenu du message ne peut pas être vide';

  @override
  String get newChatFromHistory => 'Nouveau chat depuis l\'historique';

  @override
  String get newChatCreatedFromHere => 'Nouveau chat créé à partir d\'ici';

  @override
  String get createNewChatFailed => 'Échec de la création du nouveau chat';

  @override
  String get thinking => 'Réflexion...';

  @override
  String get callingTool => 'Appel de l\'outil';

  @override
  String get toolCallRecord => 'Historique des appels d\'outil';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get deleteMessageFailed => 'Échec de la suppression du message';

  @override
  String get duration => 'Durée';

  @override
  String get calculating => 'Calcul...';

  @override
  String get speed => 'Vitesse';

  @override
  String get outputTokensLabel => 'Tokens de sortie';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get collapseSidebar => 'Réduire la barre latérale';

  @override
  String get expandSidebar => 'Développer la barre latérale';

  @override
  String get collapseRightSidebar => 'Réduire la barre latérale droite';

  @override
  String get expandRightSidebar => 'Développer la barre latérale droite';

  @override
  String get unfavorite => 'Retirer des favoris';

  @override
  String get favoriteSession => 'Ajouter aux favoris';

  @override
  String get user => 'Utilisateur';

  @override
  String get assistant => 'Assistant';

  @override
  String get noMemory => 'Aucune mémoire';

  @override
  String get noFiles => 'Aucun fichier';

  @override
  String get fileInfo => 'Infos fichier';

  @override
  String get fileContent => 'Contenu du fichier';

  @override
  String get noContentPreview => 'Aucun aperçu du contenu';

  @override
  String get fileContentCopied =>
      'Contenu du fichier copié dans le presse-papiers';

  @override
  String get selectOrCreateSession =>
      'Veuillez sélectionner ou créer une session';

  @override
  String get invalidSessionIndex => 'Index de session invalide';

  @override
  String get cannotOpenEmailApp =>
      'Impossible d\'ouvrir l\'application de messagerie';

  @override
  String get sendEmailFailed => 'Échec de l\'envoi de l\'e-mail';

  @override
  String get memorySummary => 'Résumé mémoire';

  @override
  String get recentConversations => 'Conversations récentes';

  @override
  String get sessionFiles => 'Fichiers de session';

  @override
  String get files => 'Fichiers';

  @override
  String get memory => 'Mémoire';

  @override
  String get processed => 'Traité';

  @override
  String todayTime(Object time) {
    return 'Aujourd\'hui $time';
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
    return '$action échoué : $error';
  }

  @override
  String xDone(Object action) {
    return '$action terminé';
  }

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get replyDeleted => 'Réponses supprimées';

  @override
  String get deleteReplyFailed => 'Échec de la suppression des réponses';

  @override
  String get asConversationContinues =>
      'Au fil de la conversation, l\'IA va\nenregistrer et compresser automatiquement la mémoire';

  @override
  String get whenAiCreatesFiles =>
      'Lorsque les outils IA créent ou modifient\ndes fichiers dans la conversation, ils apparaîtront ici';

  @override
  String get deleteSessionTitle_warning => 'Cette action est irréversible';

  @override
  String get pleaseSetupModel => 'Veuillez configurer un modèle';

  @override
  String get clickToSelectModel =>
      'Cliquez ci-dessus pour sélectionner un modèle de chat';

  @override
  String get selectModel => 'Sélectionner un modèle';

  @override
  String get noAvailableModels => 'Aucun modèle disponible';

  @override
  String get sessionNotFoundCannotSelectModel =>
      'Session introuvable, impossible de sélectionner un modèle';

  @override
  String get inputHint =>
      'Saisir un message ici, ↵ pour envoyer, Maj+↵ pour un saut de ligne';

  @override
  String get stopAnswer => 'Arrêter la réponse';

  @override
  String waitingAttachments(Object count) {
    return 'En attente du traitement de $count pièces jointes';
  }

  @override
  String get sendMessageAction => 'Envoyer le message';

  @override
  String get deepThinkEnabled => 'Réflexion profonde : Activée';

  @override
  String get deepThinkDisabled => 'Réflexion profonde : Désactivée';

  @override
  String get deepThink => 'Réflexion profonde';

  @override
  String get workingDirectoryLabel => 'Répertoire de travail';

  @override
  String workingDirectoryPath(Object path) {
    return 'Répertoire de travail : $path';
  }

  @override
  String get setWorkingDirHint =>
      'Définir le répertoire de travail (emplacement d\'enregistrement par défaut)';

  @override
  String get workingDirSet => 'Répertoire de travail défini';

  @override
  String get workingDirCleared => 'Répertoire de travail effacé';

  @override
  String get noWorkingDir =>
      'Veuillez d\'abord définir le répertoire des fichiers de contrat';

  @override
  String get parseContract => 'Analyser le contrat';

  @override
  String get parseContractHint =>
      'Analyser les fichiers de contrat dans le répertoire de travail';

  @override
  String get parseContractPrompt =>
      'Voici les fichiers de documents dans le répertoire de travail. Déterminez d\'abord quels fichiers sont de vrais documents contractuels (et non des pièces jointes, descriptions ou autres fichiers non contractuels). Ensuite, pour les seuls fichiers confirmés comme contrats, utilisez l\'outil contract_inspect pour écrire les informations de chaque contrat.\n\nRègles d\'écriture :\n- Pour chaque contrat, appelez d\'abord action=add pour créer une entrée de contrat (renseignez contractName, contractType, paymentClause, paymentSchedule, breachClause, liabilityClause, startDate, endDate, signingDate, etc.)\n- Puis appelez action=addParty pour chaque partie, en ajoutant successivement la partie A, la partie B, etc.\n- Expliquez également brièvement dans votre réponse quels fichiers ont été déterminés comme non contractuels et pourquoi.';

  @override
  String get contractPoints => 'Points du contrat';

  @override
  String get noContracts => 'Aucun point de contrat';

  @override
  String get contractParsing =>
      'Les points du contrat apparaîtront ici après l\'analyse';

  @override
  String get contractParty => 'Parties';

  @override
  String get contractPaymentClause => 'Clause de paiement';

  @override
  String get contractPaymentSchedule => 'Calendrier de paiement';

  @override
  String get contractBreachClause => 'Clause de rupture';

  @override
  String get contractLiability => 'Responsabilité';

  @override
  String get contractPeriod => 'Période du contrat';

  @override
  String get contractSigningDate => 'Date de signature';

  @override
  String get contractTypeLabel => 'Type de contrat';

  @override
  String nRounds(Object n) {
    return '$n tours';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return 'Config mémoire : conserver les $label dernières conversations';
  }

  @override
  String get closeMemory => 'Fermer la mémoire';

  @override
  String get noContext => 'Aucun contexte';

  @override
  String keepXRounds(Object n) {
    return 'Conserver $n tours';
  }

  @override
  String lastXRounds(Object n) {
    return 'Les $n derniers tours';
  }

  @override
  String get defaultMemory => 'Par défaut';

  @override
  String get longConversation => 'Longue conversation';

  @override
  String get veryLongConversation => 'Très longue conversation';

  @override
  String get noMatchingResults => 'Aucun résultat correspondant';

  @override
  String get memoryClosed => 'Mémoire fermée';

  @override
  String memoryConfigSet(Object n) {
    return 'Config mémoire : $n tours';
  }

  @override
  String get attach => 'Pièce jointe';

  @override
  String get selectMcpTool => 'Sélectionner un connecteur';

  @override
  String get noMcpTool => 'Aucun connecteur';

  @override
  String get viewMcpToolDetail => 'Voir les détails de l\'outil MCP';

  @override
  String get clickToSelectMcpTool => 'Cliquez pour sélectionner un outil MCP';

  @override
  String get noMcpToolConfigured => 'Aucun outil MCP configuré';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return 'Workflow de l\'outil : $desc';
  }

  @override
  String get clickToDesignWorkflow =>
      'Définir la logique d\'utilisation conjointe du connecteur et des compétences';

  @override
  String get alreadySet => 'Défini';

  @override
  String get toolWorkflowDescTitle => 'Description du workflow de l\'outil';

  @override
  String get enterToolWorkflowDesc =>
      'Saisir la description du workflow de l\'outil...';

  @override
  String get relationDescCleared => 'Description de la relation effacée';

  @override
  String get relationDescSaved => 'Description de la relation enregistrée';

  @override
  String get noMcpServiceConfigured => 'Aucun service MCP configuré';

  @override
  String mcpBoundTitle(Object count) {
    return 'MCP liés ($count)';
  }

  @override
  String get mcpViewDetails => 'Voir les détails des MCP liés';

  @override
  String mcpServiceList(Object n) {
    return 'Liste des services MCP ($n)';
  }

  @override
  String get mcpServiceTitle => 'Service MCP';

  @override
  String get enabledStatus => 'Activé';

  @override
  String get disabledStatus => 'Désactivé';

  @override
  String commandLabel(Object cmd) {
    return 'Commande : $cmd';
  }

  @override
  String argsLabel(Object args) {
    return 'Arguments : $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return 'Répertoire : $dir';
  }

  @override
  String timeoutSec(Object n) {
    return 'Délai : ${n}s';
  }

  @override
  String get mcpListHint =>
      'Astuce : double-cliquez sur le bouton MCP pour la liste, simple clic pour basculer';

  @override
  String get mcpEnabledMsg =>
      'Outils MCP activés, seront invoqués automatiquement à l\'envoi';

  @override
  String get mcpDisabledMsg => 'Outils MCP désactivés';

  @override
  String get clearMcpService => 'Effacer le service MCP';

  @override
  String get unbindAction => 'Dissocier';

  @override
  String xTools(Object n) {
    return '$n outils';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'Service MCP sélectionné : $name';
  }

  @override
  String get mcpToolsDisabled => 'Outils MCP désactivés';

  @override
  String get createAction => 'Créer';

  @override
  String get noModelBound => 'Aucun modèle lié';

  @override
  String serviceUnavailable(Object error) {
    return 'Désolé, service temporairement indisponible, $error';
  }

  @override
  String get confirmClear => 'Confirmer l\'effacement';

  @override
  String get clearHistoryConfirmMsg =>
      'Voulez-vous vraiment effacer tout l\'historique des conversations ? Cette action est irréversible.';

  @override
  String get historyCleared => 'Historique effacé';

  @override
  String folderPath(Object path) {
    return 'Dossier : $path';
  }

  @override
  String toolList(Object n) {
    return 'Liste des outils ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... $n outils de plus';
  }

  @override
  String get jsonCopied => 'JSON copié';

  @override
  String get mcpDetail => 'Détail MCP';

  @override
  String toolsRefreshed(Object n) {
    return '$n outils actualisés';
  }

  @override
  String refreshFailed(Object error) {
    return 'Échec de l\'actualisation : $error';
  }

  @override
  String get refreshAction => 'Actualiser';

  @override
  String toolsFetched(Object n) {
    return '$n outils récupérés';
  }

  @override
  String fetchFailed(Object error) {
    return 'Échec de la récupération : $error';
  }

  @override
  String get modelConfigNotFound => 'Configuration du modèle introuvable';

  @override
  String get modelProviderNotConfigured =>
      'Fournisseur du modèle non configuré';

  @override
  String get screenshotFailed =>
      'Échec de la capture : objet de rendu introuvable';

  @override
  String get generateImageFailed => 'Échec de la génération de l\'image';

  @override
  String get messageScreenshotCopied =>
      'Capture du message copiée dans le presse-papiers';

  @override
  String get currentRoundScreenshotCopied =>
      'Capture du tour copiée dans le presse-papiers';

  @override
  String get fullConversationScreenshotCopied =>
      'Capture de la conversation complète copiée dans le presse-papiers';

  @override
  String get noMessagesInConversation => 'Aucun message dans la conversation';

  @override
  String get cannotFindMessage => 'Impossible de trouver le message';

  @override
  String get cannotFindCompleteRound =>
      'Impossible de trouver un tour de conversation complet';

  @override
  String partialScreenshot(Object n, Object total) {
    return 'Certains messages n\'ont pas pu être capturés, $n/$total messages capturés';
  }

  @override
  String get renderObjectStillDrawing =>
      'Échec de la capture : l\'objet de rendu est encore en cours de dessin';

  @override
  String screenshotCopied(Object type) {
    return 'Capture $type copiée dans le presse-papiers';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return 'Capture $type échouée : $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return 'Échec de la fusion de la capture : $error';
  }

  @override
  String copyImageFailed(Object error) {
    return 'Échec de la copie de l\'image : $error';
  }

  @override
  String get unsupportedOS => 'Système d\'exploitation non pris en charge';

  @override
  String desktopCopyFailed(Object error) {
    return 'Échec de la copie de l\'image sur le bureau : $error';
  }

  @override
  String get noClipboardTool =>
      'Aucun outil de presse-papiers disponible (xclip ou wl-copy)';

  @override
  String get cannotFindRenderObject =>
      'Impossible de trouver l\'objet de rendu du message';

  @override
  String get cronExpression => 'Expression Cron';

  @override
  String get cronFormat =>
      'Format : minute heure jour mois jour-semaine (5 champs)';

  @override
  String get messageContentLabel => 'Contenu du message';

  @override
  String get enableTask => 'Activer la tâche';

  @override
  String get pleaseEnterCron => 'Veuillez saisir l\'expression cron';

  @override
  String get cronFormatError => 'Erreur de format cron (5 champs requis)';

  @override
  String get daily0900 => 'Tous les jours 09h00';

  @override
  String get daily1200 => 'Tous les jours 12h00';

  @override
  String get daily1800 => 'Tous les jours 18h00';

  @override
  String get workday0900 => 'Jours ouvrés 09h00';

  @override
  String get every30min => 'Toutes les 30 min';

  @override
  String get every2h => 'Toutes les 2 heures';

  @override
  String get processFailedStatus => 'Échec du processus';

  @override
  String get processingStatus => 'En cours de traitement';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - Aperçu du contenu';
  }

  @override
  String get contentCopiedToClipboard => 'Contenu copié dans le presse-papiers';

  @override
  String get fileProcessFailed => 'Échec du traitement du fichier';

  @override
  String get pleaseReupload =>
      'Veuillez re-téléverser le fichier ou contacter le support';

  @override
  String get processingFileStatus => 'Traitement du fichier...';

  @override
  String get imageFile => 'Fichier image';

  @override
  String get documentFile => 'Fichier document';

  @override
  String get textFile => 'Fichier texte';

  @override
  String get codeFile => 'Fichier code';

  @override
  String get officeDocument => 'Document bureautique';

  @override
  String get webLink => 'Lien web';

  @override
  String get folderType => 'Dossier';

  @override
  String get otherFile => 'Autre fichier';

  @override
  String get defaultConversation => 'Conversation générale';

  @override
  String modelCopied(Object name) {
    return 'Modèle « $name » copié avec succès';
  }

  @override
  String copyOf(Object name) {
    return 'Copie de $name';
  }

  @override
  String copyOfN(Object n, Object name) {
    return 'Copie de $name ($n)';
  }

  @override
  String get noModels => 'Aucun modèle';

  @override
  String get clickAddModelHint =>
      'Cliquez sur le bouton « Ajouter un modèle » pour commencer';

  @override
  String modelUpdatedNotify(Object name) {
    return 'Modèle « $name » mis à jour, paramètres de session associés synchronisés';
  }

  @override
  String serviceRemoved(Object name) {
    return 'Service retiré : $name';
  }

  @override
  String get connectorManagementTitle => 'Gestion des connecteurs (MCP)';

  @override
  String get marketplace => 'Place de marché';

  @override
  String get noMcpServices => 'Aucun service MCP';

  @override
  String get clickToEnterMarketplace =>
      'Cliquez sur le bouton + pour accéder à la place de marché';

  @override
  String fetchToolsFailed(Object error) {
    return 'Échec de la récupération des outils : $error';
  }

  @override
  String get removeServiceLabel => 'Retirer le service';

  @override
  String get removeServiceConfirm => 'Voulez-vous vraiment retirer le service';

  @override
  String get removeServiceWarning => 'Doit être rajouté après suppression';

  @override
  String get jsonConfig => 'Config JSON';

  @override
  String get cannotReadFilePath => 'Impossible de lire le chemin du fichier';

  @override
  String get extractingImport => 'Extraction de l\'importation...';

  @override
  String importFailed(Object error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get irreversibleAction => 'Cette action est irréversible';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'Modèle supprimé';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'Modèle « $name » supprimé avec succès';
  }

  @override
  String get selectOtherModelFromList =>
      'Sélectionnez un autre modèle dans la liste pour voir les détails';

  @override
  String get unnamedModel => 'Modèle sans nom';

  @override
  String get noDescription => 'Aucune description';

  @override
  String get confirmDeleteModel => 'Voulez-vous vraiment supprimer le modèle';

  @override
  String modelDeletedToast(Object name) {
    return 'Modèle « $name » supprimé';
  }

  @override
  String get addOnlineModel => 'Ajouter un modèle en ligne';

  @override
  String get selectProvider => 'Sélectionner un fournisseur';

  @override
  String get configureParams => 'Configurer les paramètres';

  @override
  String get checkConfig => 'Vérifier la configuration';

  @override
  String get setName => 'Définir le nom';

  @override
  String get nextStep => 'Suivant';

  @override
  String get selectOnlineProvider =>
      'Sélectionner un fournisseur de modèle en ligne';

  @override
  String get customProvider => 'Personnalisé';

  @override
  String get customProviderDesc =>
      'Saisir manuellement l\'adresse, la clé API et le nom du modèle';

  @override
  String get customProviderConfigTitle =>
      'Configuration du modèle personnalisé';

  @override
  String configureProviderParams(Object provider) {
    return 'Configurer les paramètres de $provider';
  }

  @override
  String get ollamaApiKeyOptional =>
      'Le service Ollama local ne nécessite généralement pas de clé API, peut rester vide';

  @override
  String get apiAddress => 'Adresse API';

  @override
  String get defaultApiUrlNote =>
      'Adresse API officielle par défaut, modifiable pour un déploiement local ou privé';

  @override
  String get presetModel => 'Modèles prédéfinis';

  @override
  String get customModel => 'Modèle personnalisé';

  @override
  String get enterFullModelName =>
      'Saisir le nom complet du modèle pris en charge par le fournisseur';

  @override
  String get ollamaRunningModels => 'Modèles Ollama en cours d\'exécution';

  @override
  String get refreshModelList => 'Actualiser la liste des modèles';

  @override
  String get ollamaStartHint =>
      'Veuillez d\'abord démarrer le service Ollama et télécharger les modèles\npuis cliquez sur actualiser pour obtenir la liste des modèles';

  @override
  String get modelscopeAvailableModels => 'Modèles disponibles sur ModelScope';

  @override
  String get modelscopeApiKeyHint =>
      'Veuillez vous assurer que la clé API est correcte\npuis cliquez sur actualiser pour obtenir la liste des modèles';

  @override
  String get setModelName => 'Définir le nom du modèle';

  @override
  String get configSummary => 'Résumé de la configuration';

  @override
  String get providerLabel => 'Fournisseur';

  @override
  String get platformLabel => 'Plateforme';

  @override
  String get notSet => 'Non défini';

  @override
  String get modelLabel => 'Modèle';

  @override
  String get customSuffix => '(Personnalisé)';

  @override
  String get notSelected => 'Non sélectionné';

  @override
  String get customModelName => 'Nom du modèle personnalisé';

  @override
  String enterModelNameHint(Object provider) {
    return 'Saisir le nom du modèle, ex. $provider-Chat';
  }

  @override
  String get modelNameSuggestion =>
      'Utilisez un nom explicite pour faciliter l\'identification';

  @override
  String get testConnectionDesc =>
      'Tester la connexion et la réponse du modèle';

  @override
  String get waitingForResponse => 'En attente de réponse...';

  @override
  String get configIncomplete => 'Configuration incomplète';

  @override
  String get receivedEmptyResponse => 'Réponse vide reçue';

  @override
  String get receivedNoResponse => 'Aucune réponse reçue';

  @override
  String connectionFailed(Object error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get contextCap => 'Contexte';

  @override
  String get thinkingCap => 'Réflexion';

  @override
  String get builtinToolsCap => 'Outils intégrés';

  @override
  String get structuredCap => 'Structuré';

  @override
  String get batchCap => 'Lot';

  @override
  String get basicInfo => 'Informations de base';

  @override
  String get modelParams => 'Paramètres du modèle';

  @override
  String get unknown => 'Inconnu';

  @override
  String get nameLabel => 'Nom';

  @override
  String get apiKeyLabel => 'Clé API';

  @override
  String get notSetDoubleClickToEdit =>
      'Non défini (double-cliquez pour modifier)';

  @override
  String get apiKeySaved => 'Clé API enregistrée';

  @override
  String get modelNameCannotBeEmpty => 'Le nom du modèle ne peut pas être vide';

  @override
  String get modelNameSaved => 'Nom du modèle enregistré';

  @override
  String get modelSaved => 'Modèle enregistré';

  @override
  String get temperatureLabel => 'Température';

  @override
  String get precise => 'Précis';

  @override
  String get neutral => 'Neutre';

  @override
  String get creative => 'Créatif';

  @override
  String get temperatureDescription =>
      'Contrôle l\'aléatoire et la créativité des réponses. Les valeurs basses sont plus conservatrices, les valeurs élevées plus créatives.';

  @override
  String get modelRoleSetting => 'Paramètre du rôle du modèle';

  @override
  String get presetRole => 'Rôle prédéfini';

  @override
  String get roleSettingDescription =>
      'Le paramètre de rôle est envoyé au modèle au début de chaque conversation pour définir le rôle et le comportement. Ajustez selon le rôle que vous souhaitez voir jouer par le modèle.';

  @override
  String get selectPresetRole => 'Sélectionner un rôle prédéfini';

  @override
  String get generalAssistant => 'Assistant général';

  @override
  String get friendlyAssistantDesc => 'Assistant IA amical et professionnel';

  @override
  String get spellCheck => 'Vérification orthographique';

  @override
  String get spellCheckDesc => 'Expert en vérification orthographique';

  @override
  String get codeExpert => 'Expert en code';

  @override
  String get codeExpertDesc =>
      'Expert technique en programmation et développement';

  @override
  String get legalExpert => 'Expert juridique';

  @override
  String get legalExpertDesc => 'Conseiller juridique professionnel';

  @override
  String get copywriter => 'Rédacteur';

  @override
  String get copywriterDesc => 'Expert en rédaction et création de contenu';

  @override
  String get dataAnalyst => 'Analyste de données';

  @override
  String get dataAnalystDesc => 'Expert en analyse de données et statistiques';

  @override
  String get educationTutor => 'Tuteur en éducation';

  @override
  String get educationTutorDesc => 'Expert en enseignement patient';

  @override
  String get businessConsultant => 'Consultant en affaires';

  @override
  String get businessConsultantDesc =>
      'Expert en gestion et stratégie d\'entreprise';

  @override
  String get psychologist => 'Psychologue';

  @override
  String get psychologistDesc => 'Consultant professionnel en santé mentale';

  @override
  String get versionLabel => 'Version';

  @override
  String get workModeSettings => 'Mode de travail';

  @override
  String get workModeBusiness => 'Affaires';

  @override
  String get workModeBusinessDesc =>
      'Négociation commerciale, gestion de contrats, stratégie';

  @override
  String get workModeFinance => 'Finance';

  @override
  String get workModeFinanceDesc =>
      'Analyse financière, planification fiscale, comptabilité des coûts';

  @override
  String get workModeLegal => 'Juridique';

  @override
  String get workModeLegalDesc =>
      'Rédaction juridique, révision de conformité, évaluation des risques';

  @override
  String get workModeMarketing => 'Marketing';

  @override
  String get workModeMarketingDesc =>
      'Planification marketing, promotion de marque, analyse concurrentielle';

  @override
  String get domainSettings => 'Paramètres de domaine';

  @override
  String get serviceStatus => 'Service local';

  @override
  String get localService => 'Service local';

  @override
  String get serviceStopped => 'Service arrêté';

  @override
  String get serviceRunning => 'En cours d\'exécution';

  @override
  String get serviceStarting => 'Démarrage...';

  @override
  String get restart => 'Redémarrer';

  @override
  String get certificateSettings => 'Paramètres de certificat';

  @override
  String get httpsStatus => 'Statut HTTPS';

  @override
  String get domainAddress => 'Adresse de domaine';

  @override
  String get domainHint => 'ex. api.example.com';

  @override
  String get domainDesc =>
      'Une fois défini, l\'URL du service de session utilisera cette adresse. Port HTTP par défaut 80, port HTTPS par défaut 443.';

  @override
  String get portSettings => 'Paramètres de port';

  @override
  String get httpPort => 'Port HTTP';

  @override
  String get httpsPort => 'Port HTTPS';

  @override
  String get portDesc =>
      'Port d\'écoute HTTP, défaut 80. Port d\'écoute HTTPS, défaut 443. Redémarrez le service pour appliquer les changements.';

  @override
  String get sslCertificate => 'Certificat SSL';

  @override
  String get sslPrivateKey => 'Clé privée';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get httpsEnabled => 'HTTPS';

  @override
  String get httpsEnabledDesc =>
      'Certificat téléversé, HTTPS activé automatiquement';

  @override
  String get httpsDisabledDesc =>
      'Téléversez le certificat (crt/cert + key) pour activer HTTPS automatiquement';

  @override
  String get domainInfoDesc =>
      'Après configuration de l\'adresse du service, l\'URL du service de session affichera cette adresse. Les clients externes peuvent accéder à l\'API de session (/chat/completions, etc.) via cette adresse.';

  @override
  String get pleaseEnterDomain => 'Veuillez saisir l\'adresse du service';

  @override
  String get domainSaved => 'Configuration du service enregistrée';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get cny => 'CNY';

  @override
  String get usd => 'USD';

  @override
  String get loadingPageSubtitle =>
      'Espace de travail IA d\'entreprise intelligent';

  @override
  String get billingSettings => 'Facturation';

  @override
  String get mcpSettings => 'Paramètres MCP';

  @override
  String get currencyTypeLabel => 'Type de devise';

  @override
  String get inputPriceLabel => 'Prix d\'entrée';

  @override
  String get outputPriceLabel => 'Prix de sortie';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/M tokens';
  }

  @override
  String priceUnitDescription(Object unit) {
    return 'Prix : $unit/million de tokens. Utilisé pour le calcul du coût cumulé de session.';
  }

  @override
  String get examplePriceHint => 'ex. 0,14';

  @override
  String get mcpBindingDescription =>
      'Après avoir lié des services MCP au modèle, les sessions utilisant ce modèle injecteront automatiquement ces outils MCP. Les MCP de session et de modèle seront fusionnés et dédupliqués automatiquement.';

  @override
  String get addMcpServiceButton => 'Ajouter un service MCP';

  @override
  String get clearAllMcpBindings => 'Effacer tous les liens MCP';

  @override
  String get selectMcpServiceMultiSelect =>
      'Sélectionner un service MCP (multi-sélection)';

  @override
  String get noMcpServiceAddFirst =>
      'Aucun service MCP, veuillez d\'abord ajouter dans la gestion MCP';

  @override
  String confirmWithCount(Object count) {
    return 'OK ($count)';
  }

  @override
  String get temperaturePrecise => 'Précis';

  @override
  String get temperatureConservative => 'Conservateur';

  @override
  String get temperatureNeutral => 'Neutre';

  @override
  String get temperatureCreative => 'Créatif';

  @override
  String get temperatureRandom => 'Aléatoire';

  @override
  String xToolsCount(Object n) {
    return '$n outils';
  }

  @override
  String get newConversationDefault => 'Nouvelle conversation';

  @override
  String get usageDashboard => 'Tableau de bord d\'utilisation';

  @override
  String get globalUsageDashboard => 'Tableau de bord d\'utilisation global';

  @override
  String sessionUsageTitle(Object name) {
    return 'Utilisation de $name';
  }

  @override
  String get noSessionData => 'Aucune donnée de session';

  @override
  String get noUsageData => 'Aucune donnée d\'utilisation';

  @override
  String get overview => 'Aperçu';

  @override
  String get statMessages => 'Messages';

  @override
  String get totalMessages => 'Total des messages';

  @override
  String get inputTokens => 'Tokens d\'entrée';

  @override
  String get outputTokens => 'Tokens de sortie';

  @override
  String get totalCostLabel => 'Coût total';

  @override
  String get tokenDistribution => 'Distribution des tokens';

  @override
  String get modelInfo => 'Infos modèle';

  @override
  String get quotaLimitSection => 'Limite de quota';

  @override
  String get usageCurve => 'Courbe d\'utilisation';

  @override
  String get totalSessions => 'Total des sessions';

  @override
  String get totalTokens => 'Total des tokens';

  @override
  String get byModel => 'Par modèle';

  @override
  String get allSessions => 'Toutes les sessions';

  @override
  String moreSessionsNoData(Object count) {
    return 'Encore $count sessions n\'ont pas de données d\'utilisation';
  }

  @override
  String get inputLabel => 'Entrée';

  @override
  String get outputLabel => 'Sortie';

  @override
  String get noQuotaLimit => 'Aucune limite de quota définie';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count sessions';
  }

  @override
  String get granMinute => 'Minute';

  @override
  String get granHour => 'Heure';

  @override
  String get granDay => 'Jour';

  @override
  String get granMonth => 'Mois';

  @override
  String get granYear => 'Année';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get rangeStart => 'Début';

  @override
  String get rangeEnd => 'Fin';

  @override
  String get startDateHelp => 'Date de début';

  @override
  String get endDateHelp => 'Date de fin';

  @override
  String get tokenToggle => 'Token';

  @override
  String get costToggle => 'Coût';

  @override
  String chartLegendCost(Object symbol) {
    return 'Coût ($symbol)';
  }

  @override
  String get noSessionConfig => 'Aucune configuration de session';

  @override
  String get resetApiKey => 'Réinitialiser la clé API';

  @override
  String get resetApiKeyConfirm =>
      'Voulez-vous réinitialiser la clé API de cette session ? Après réinitialisation, l\'ancienne clé sera immédiatement invalidée et les requêtes externes utilisant l\'ancienne clé ne pourront plus accéder.';

  @override
  String get confirmReset => 'Confirmer la réinitialisation';

  @override
  String get connectorSkillRelation =>
      'Description de la relation connecteur et compétence';

  @override
  String modelPricing(Object unit) {
    return 'Tarif du modèle ($unit/M tokens)';
  }

  @override
  String get billingInfoLabel => 'Infos de facturation';

  @override
  String get cumulativeInputTokens => 'Tokens d\'entrée cumulés';

  @override
  String get cumulativeOutputTokens => 'Tokens de sortie cumulés';

  @override
  String get cumulativeCost => 'Coût cumulé';

  @override
  String get basicInfoLabel => 'Informations de base';

  @override
  String get sessionName => 'Nom de session';

  @override
  String get organization => 'Organisation';

  @override
  String get groupLabel => 'Groupe';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get notGrouped => 'Non groupé';

  @override
  String get boundModel => 'Modèle lié';

  @override
  String get relatedPrompt => 'Invite associée';

  @override
  String get messageCountLabel => 'Nombre de messages';

  @override
  String get serviceConfigLabel => 'Config du service';

  @override
  String get serviceAddress => 'Adresse du service';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => 'MCP du modèle';

  @override
  String get sessionMcp => 'MCP de session';

  @override
  String get notBound => 'Non lié';

  @override
  String get addMcpHint =>
      'Vous pouvez ajouter des services MCP dans la gestion des modèles ou la zone de saisie de chat';

  @override
  String get usageQuotaLabel => 'Quota d\'utilisation';

  @override
  String get noAuthAccess => 'Accès sans authentification';

  @override
  String get noAuthEnabledDesc =>
      '⚠️ Auth désactivée, tout le monde peut accéder';

  @override
  String get noAuthDisabledDesc => 'Activé : accès sans clé API';

  @override
  String get disableSession => 'Désactiver la session';

  @override
  String get disabledEnabledDesc =>
      '⚠️ Désactivée, les appels renverront une erreur';

  @override
  String get disabledDisabledDesc =>
      'Activé : cette session ne pourra pas être appelée';

  @override
  String get systemPromptHint =>
      'Définir le rôle/comportement de cette session, ex. vous êtes un conseiller juridique professionnel...';

  @override
  String get systemPromptDesc =>
      'Défini comme instruction de priorité maximale, injectée automatiquement pour les requêtes tierces. Laisser vide pour ne pas injecter.';

  @override
  String get tokenUsageLimit => 'Limite d\'utilisation des tokens';

  @override
  String costBudgetLimit(Object unit) {
    return 'Limite de budget de coût ($unit)';
  }

  @override
  String get requestLimit => 'Limite de requêtes';

  @override
  String get noLimit => 'Aucune limite';

  @override
  String get enableUsageLimit => 'Activer la limite d\'utilisation';

  @override
  String get reachLimitReject =>
      'Les nouvelles requêtes seront rejetées après avoir atteint la limite';

  @override
  String get resetPeriod => 'Période de réinitialisation';

  @override
  String get resetPeriodNever => 'Pas de réinitialisation auto';

  @override
  String get resetPeriodDaily => 'Réinitialisation quotidienne';

  @override
  String get resetPeriodMonthly => 'Réinitialisation mensuelle';

  @override
  String get quotaExhausted => 'Quota épuisé';

  @override
  String get currentUsageStatus => 'État d\'utilisation actuel';

  @override
  String get quotaTokenLabel => 'Token';

  @override
  String get quotaCostLabel => 'Coût';

  @override
  String get quotaRequestLabel => 'Requêtes';

  @override
  String get manualResetUsage => 'Réinitialisation manuelle de l\'utilisation';

  @override
  String get manualResetConfirmDesc => 'Confirmer la réinitialisation manuelle';

  @override
  String get manualResetWarning =>
      'Après réinitialisation, l\'utilisation des tokens, le coût et le nombre de requêtes de la période en cours seront effacés, et l\'heure de début de période sera mise à jour à l\'heure actuelle.';

  @override
  String get tokenUsage => 'Utilisation des tokens';

  @override
  String get costUsage => 'Utilisation du coût';

  @override
  String get resetValue => 'Réinitialiser';

  @override
  String get apiKeyReset => 'Clé API réinitialisée';

  @override
  String get securitySettings => 'Sécurité';

  @override
  String get sensitiveInfoMasking => 'Masquage des informations sensibles';

  @override
  String get sensitiveInfoMaskingDesc =>
      'Lorsqu\'il est activé, les informations correspondantes dans les messages envoyés au modèle et dans les journaux d\'audit locaux sont remplacées par \'*\' afin d\'éviter la fuite de données personnelles en clair.';

  @override
  String get maskPhoneTitle => 'Masquer les numéros de téléphone';

  @override
  String get maskPhoneSubtitle =>
      'Remplacer les numéros de téléphone dans les messages par \'*\'';

  @override
  String get maskIdCardTitle => 'Masquer les numéros de carte d\'identité';

  @override
  String get maskIdCardSubtitle =>
      'Remplacer les numéros de carte d\'identité dans les messages par \'*\'';

  @override
  String get sessionDetails => 'Détails de la session';

  @override
  String get modelDetails => 'Détails du modèle';

  @override
  String modelDetailsWithPlatform(String platform) {
    return 'Détails du modèle · $platform';
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
