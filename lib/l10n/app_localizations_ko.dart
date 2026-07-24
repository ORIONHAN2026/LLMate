// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => '스마트 채팅 어시스턴트';

  @override
  String get feedback => '피드백';

  @override
  String get modelManagement => '모델 관리';

  @override
  String get connectorManagement => '커넥터 (MCP)';

  @override
  String get domainManagement => '서비스 관리';

  @override
  String get otherSettings => '기타 설정';

  @override
  String get resetSystem => '시스템 초기화';

  @override
  String get resetAllSessions => '모든 세션 초기화';

  @override
  String get resetAllModels => '모든 모델 초기화';

  @override
  String get resetAllMcp => '모든 MCP 초기화';

  @override
  String get resetAll => '전체 초기화';

  @override
  String resetConfirmMsg(Object action) {
    return '$action하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get languageSettings => '언어';

  @override
  String get skinSettings => '테마';

  @override
  String get followSystem => '시스템 따르기';

  @override
  String get followSystemDesc => '라이트/다크 모드 자동 전환';

  @override
  String get lightMode => '라이트';

  @override
  String get lightModeDesc => '항상 라이트 테마 사용';

  @override
  String get darkMode => '다크';

  @override
  String get darkModeDesc => '항상 다크 테마 사용';

  @override
  String get chinese => '中文';

  @override
  String get chineseDesc => 'Simplified Chinese';

  @override
  String get english => 'English';

  @override
  String get englishDesc => 'English';

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get edit => '편집';

  @override
  String get add => '추가';

  @override
  String get close => '닫기';

  @override
  String get remove => '제거';

  @override
  String get clear => '지우기';

  @override
  String get search => '검색';

  @override
  String get noData => '데이터 없음';

  @override
  String get loading => '불러오는 중...';

  @override
  String get send => '전송';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사됨';

  @override
  String get copyContent => '내용 복사';

  @override
  String get retry => '다시 시도';

  @override
  String get done => '완료';

  @override
  String get back => '뒤로';

  @override
  String get previousStep => '이전';

  @override
  String get settings => '설정';

  @override
  String get systemPrompt => '시스템 프롬프트';

  @override
  String get temperature => '온도';

  @override
  String get replyLanguage => '답변 언어';

  @override
  String get newSession => '새 세션';

  @override
  String get sessionList => '세션 목록';

  @override
  String get rename => '이름 변경';

  @override
  String get shareConversation => '대화 공유';

  @override
  String get exportData => '데이터 내보내기';

  @override
  String get importData => '데이터 가져오기';

  @override
  String get clearConversation => '대화 지우기';

  @override
  String get deleteConversation => '대화 삭제';

  @override
  String get deleteConfirm => '삭제 확인';

  @override
  String get deleteConfirmMsg => '삭제하시겠습니까?';

  @override
  String removeConfirmMsg(Object name) {
    return '\"$name\"을(를) 제거하시겠습니까?';
  }

  @override
  String get addModel => '모델 추가';

  @override
  String get copyModel => '모델 복사';

  @override
  String get modelName => '모델 이름';

  @override
  String get modelProvider => '공급자';

  @override
  String get modelApiKey => 'API 키';

  @override
  String get modelBaseUrl => 'Base URL';

  @override
  String get modelMaxTokens => '최대 토큰';

  @override
  String get thinkTag => '사고 태그';

  @override
  String get thinkTagDesc => '모델의 사고 과정 태그';

  @override
  String get addService => '서비스 추가';

  @override
  String get removeService => '서비스 제거';

  @override
  String get testConnection => '연결 테스트';

  @override
  String get fullTest => '전체 테스트';

  @override
  String get connectAndAdd => '연결 및 추가';

  @override
  String get addCustomConnector => '사용자 정의 커넥터 추가';

  @override
  String get clearKey => '키 지우기';

  @override
  String get fetchTools => '도구 가져오기';

  @override
  String get fetchModels => '모델 가져오기';

  @override
  String get copyMessage => '메시지 복사';

  @override
  String get regenerate => '다시 생성';

  @override
  String get regenerateFromHere => '여기부터 다시 생성';

  @override
  String get regenerateLastReply => '마지막 답변 다시 생성';

  @override
  String get regenerateThisReply => '이 답변 다시 생성';

  @override
  String get createNewChatFromHere => '여기부터 새 채팅';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get deleteReply => '답변 삭제';

  @override
  String get screenshot => '스크린샷';

  @override
  String get entireConversation => '전체 대화';

  @override
  String get currentRound => '현재 라운드';

  @override
  String get currentMessage => '현재 메시지';

  @override
  String get memoryConfig => '메모리 설정';

  @override
  String get clearMcpServices => 'MCP 서비스 지우기';

  @override
  String get selectFile => '파일 선택';

  @override
  String get selectWorkingDir => '작업 디렉터리 선택';

  @override
  String get confirmDeleteTitle => '삭제 확인';

  @override
  String get deleteSessionTitle => '세션 삭제';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get earlier => '이전';

  @override
  String get removeServiceTitle => '서비스 제거';

  @override
  String get removeMcpServiceTitle => 'MCP 서비스 제거';

  @override
  String get noActiveSession => '활성 세션 없음';

  @override
  String get presetRoleApplied => '프리셋 역할 적용됨';

  @override
  String get fileNotFound => '파일을 찾을 수 없음';

  @override
  String get fileOpenFailed => '파일 열기 실패';

  @override
  String get enterMessageContent => '메시지 내용을 입력하세요';

  @override
  String get copyMessageContent => '메시지 내용 복사';

  @override
  String get apiKeyHint => 'API 키 입력';

  @override
  String get modelNameHint => '모델 이름 입력';

  @override
  String get messageHint => '메시지 내용 입력...';

  @override
  String get apiUrlHint => 'API URL 입력';

  @override
  String get commandHint => '명령 내용 입력';

  @override
  String get enterCommandContent => '명령 내용을 입력하세요';

  @override
  String get modelSearchHint => '모델 이름 입력 (예: gpt-4o-mini, claude-3-haiku)';

  @override
  String get roleDescHint => '모델의 동작 및 답변 스타일을 안내할 역할 설명 입력...';

  @override
  String get toolLogicHint => '도구 로직 설명 입력...';

  @override
  String get typeCommandOrSearch => '명령 입력 또는 검색...';

  @override
  String get searchMcp => 'MCP 서비스 검색...';

  @override
  String get cronExample => '예: 0 9 * * * (매일 09:00)';

  @override
  String get config => '설정';

  @override
  String get pasteMcpCode => 'MCP 코드 붙여넣기';

  @override
  String get fileNameLabel => '파일 이름';

  @override
  String get fileSizeLabel => '크기';

  @override
  String get fileTypeLabel => '유형';

  @override
  String get filePathLabel => '경로';

  @override
  String get aliyun => '알리바바 클라우드';

  @override
  String get tencentCloud => '텐센트 클라우드';

  @override
  String get modelscope => 'ModelScope';

  @override
  String get goToAliyun => '알리바바 클라우드로 이동';

  @override
  String pleaseEnter(Object field) {
    return '$field 입력';
  }

  @override
  String get more => '더 보기';

  @override
  String get copyFailed => '복사 실패';

  @override
  String get invalidLinkFormat => '잘못된 링크 형식';

  @override
  String get cannotOpenLink => '링크를 열 수 없음';

  @override
  String get linkOpenedInBrowser => '브라우저에서 링크 열림';

  @override
  String get cannotOpenThisLinkType => '이 링크 유형을 열 수 없음';

  @override
  String get openLinkFailed => '링크 열기 실패';

  @override
  String get fileOpened => '파일 열림';

  @override
  String get cannotOpenFile => '파일을 열 수 없음';

  @override
  String get openFileFailed => '파일 열기 실패';

  @override
  String get sessionNotFoundForMessage => '이 메시지에 대한 세션을 찾을 수 없음';

  @override
  String get messageNotFound => '메시지를 찾을 수 없음';

  @override
  String get regenerateFailed => '다시 생성 실패';

  @override
  String get cannotFindQuestion => '해당 질문을 찾을 수 없음';

  @override
  String get noAiReplyFound => 'AI 답변을 찾을 수 없음';

  @override
  String get cannotRegenerateInvalidIndex => '다시 생성 불가: 잘못된 메시지 인덱스';

  @override
  String get editMessageTitle => '메시지 편집';

  @override
  String get messageContentCannotBeEmpty => '메시지 내용은 비워둘 수 없음';

  @override
  String get newChatFromHistory => '기록에서 새 채팅';

  @override
  String get newChatCreatedFromHere => '여기에서 새 채팅 생성됨';

  @override
  String get createNewChatFailed => '새 채팅 생성 실패';

  @override
  String get thinking => '생각하는 중...';

  @override
  String get callingTool => '도구 호출 중';

  @override
  String get toolCallRecord => '도구 호출 기록';

  @override
  String get messageDeleted => '메시지 삭제됨';

  @override
  String get deleteMessageFailed => '메시지 삭제 실패';

  @override
  String get duration => '소요 시간';

  @override
  String get calculating => '계산 중...';

  @override
  String get speed => '속도';

  @override
  String get outputTokensLabel => '출력 토큰';

  @override
  String get fullscreen => '전체 화면';

  @override
  String get collapseSidebar => '사이드바 접기';

  @override
  String get expandSidebar => '사이드바 펼치기';

  @override
  String get collapseRightSidebar => '오른쪽 사이드바 접기';

  @override
  String get expandRightSidebar => '오른쪽 사이드바 펼치기';

  @override
  String get unfavorite => '즐겨찾기에서 제거';

  @override
  String get favoriteSession => '즐겨찾기에 추가';

  @override
  String get user => '사용자';

  @override
  String get assistant => '어시스턴트';

  @override
  String get noMemory => '메모리 없음';

  @override
  String get noFiles => '파일 없음';

  @override
  String get fileInfo => '파일 정보';

  @override
  String get fileContent => '파일 내용';

  @override
  String get noContentPreview => '미리보기 내용 없음';

  @override
  String get fileContentCopied => '파일 내용이 클립보드에 복사됨';

  @override
  String get selectOrCreateSession => '세션을 선택하거나 생성하세요';

  @override
  String get invalidSessionIndex => '잘못된 세션 인덱스';

  @override
  String get cannotOpenEmailApp => '이메일 앱을 열 수 없음';

  @override
  String get sendEmailFailed => '이메일 전송 실패';

  @override
  String get memorySummary => '메모리 요약';

  @override
  String get recentConversations => '최근 대화';

  @override
  String get sessionFiles => '세션 파일';

  @override
  String get files => '파일';

  @override
  String get memory => '메모리';

  @override
  String get processed => '처리됨';

  @override
  String todayTime(Object time) {
    return '오늘 $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month/$day $time';
  }

  @override
  String messageCount(Object count) {
    return '$count개 메시지';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action 실패: $error';
  }

  @override
  String xDone(Object action) {
    return '$action 완료됨';
  }

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get replyDeleted => '답변 삭제됨';

  @override
  String get deleteReplyFailed => '답변 삭제 실패';

  @override
  String get asConversationContinues => '대화가 계속됨에 따라 AI가\n자동으로 메모리를 기록하고 압축합니다';

  @override
  String get whenAiCreatesFiles => 'AI 도구가 대화 중 파일을 생성하거나 수정하면\n여기에 표시됩니다';

  @override
  String get deleteSessionTitle_warning => '이 작업은 취소할 수 없습니다';

  @override
  String get pleaseSetupModel => '모델을 설정하세요';

  @override
  String get clickToSelectModel => '위를 클릭하여 채팅 모델 선택';

  @override
  String get selectModel => '모델 선택';

  @override
  String get noAvailableModels => '사용 가능한 모델 없음';

  @override
  String get sessionNotFoundCannotSelectModel => '세션을 찾을 수 없어 모델을 선택할 수 없습니다';

  @override
  String get inputHint => '메시지를 입력하세요. ↵ 전송, Shift+↵ 줄바꿈';

  @override
  String get stopAnswer => '답변 중지';

  @override
  String waitingAttachments(Object count) {
    return '첨부 파일 $count개 처리 대기 중';
  }

  @override
  String get sendMessageAction => '메시지 전송';

  @override
  String get deepThinkEnabled => '심층 사고: 켜짐';

  @override
  String get deepThinkDisabled => '심층 사고: 꺼짐';

  @override
  String get deepThink => '심층 사고';

  @override
  String get workingDirectoryLabel => '작업 디렉터리';

  @override
  String workingDirectoryPath(Object path) {
    return '작업 디렉터리: $path';
  }

  @override
  String get setWorkingDirHint => '작업 디렉터리 설정 (기본 저장 위치)';

  @override
  String get workingDirSet => '작업 디렉터리 설정됨';

  @override
  String get workingDirCleared => '작업 디렉터리 지워짐';

  @override
  String get noWorkingDir => '먼저 계약 파일 디렉터리를 설정하세요';

  @override
  String get parseContract => '계약서 분석';

  @override
  String get parseContractHint => '작업 디렉터리의 계약 파일 분석';

  @override
  String get parseContractPrompt =>
      '다음은 작업 디렉터리에 있는 문서 파일입니다. 먼저 실제 계약 문서인 파일을 판별하세요(첨부파일, 설명, 기타 비계약 파일 제외). 그런 다음 계약으로 확인된 파일에 대해서만 contract_inspect 도구를 사용하여 각 계약의 정보를 작성하세요.\n\n작성 규칙:\n- 각 계약마다 먼저 action=add를 호출하여 계약 항목을 생성하세요(contractName, contractType, paymentClause, paymentSchedule, breachClause, liabilityClause, startDate, endDate, signingDate 등 입력).\n- 그런 다음 각 당사자에 대해 action=addParty를 호출하여 갑, 을 등을 하나씩 추가하세요.\n- 답변에서 어떤 파일이 비계약으로 판별되었고 그 이유도 간략히 설명하세요.';

  @override
  String get contractPoints => '계약 요점';

  @override
  String get noContracts => '계약 요점 없음';

  @override
  String get contractParsing => '분석 후 계약 요점이 여기에 표시됩니다';

  @override
  String get contractParty => '당사자';

  @override
  String get contractPaymentClause => '지급 조항';

  @override
  String get contractPaymentSchedule => '지급 일정';

  @override
  String get contractBreachClause => '위반 조항';

  @override
  String get contractLiability => '책임';

  @override
  String get contractPeriod => '계약 기간';

  @override
  String get contractSigningDate => '체결일';

  @override
  String get contractTypeLabel => '계약 유형';

  @override
  String nRounds(Object n) {
    return '$n 라운드';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return '메모리 설정: 최근 $label회 대화 유지';
  }

  @override
  String get closeMemory => '메모리 닫기';

  @override
  String get noContext => '컨텍스트 없음';

  @override
  String keepXRounds(Object n) {
    return '$n회 유지';
  }

  @override
  String lastXRounds(Object n) {
    return '최근 $n회';
  }

  @override
  String get defaultMemory => '기본';

  @override
  String get longConversation => '긴 대화';

  @override
  String get veryLongConversation => '매우 긴 대화';

  @override
  String get noMatchingResults => '일치하는 결과 없음';

  @override
  String get memoryClosed => '메모리 닫힘';

  @override
  String memoryConfigSet(Object n) {
    return '메모리 설정: $n회';
  }

  @override
  String get attach => '첨부';

  @override
  String get selectMcpTool => '커넥터 선택';

  @override
  String get noMcpTool => '커넥터 없음';

  @override
  String get viewMcpToolDetail => 'MCP 도구 세부정보 보기';

  @override
  String get clickToSelectMcpTool => '클릭하여 MCP 도구 선택';

  @override
  String get noMcpToolConfigured => 'MCP 도구가 구성되지 않았습니다';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return '도구 워크플로: $desc';
  }

  @override
  String get clickToDesignWorkflow => '커넥터와 스킬 공동 사용 로직 설정';

  @override
  String get alreadySet => '설정됨';

  @override
  String get toolWorkflowDescTitle => '도구 워크플로 설명';

  @override
  String get enterToolWorkflowDesc => '도구 워크플로 설명 입력...';

  @override
  String get relationDescCleared => '관계 설명 지워짐';

  @override
  String get relationDescSaved => '관계 설명 저장됨';

  @override
  String get noMcpServiceConfigured => 'MCP 서비스가 구성되지 않았습니다';

  @override
  String mcpBoundTitle(Object count) {
    return '연결된 MCP ($count)';
  }

  @override
  String mcpServiceList(Object n) {
    return 'MCP 서비스 목록 ($n)';
  }

  @override
  String get mcpServiceTitle => 'MCP 서비스';

  @override
  String get enabledStatus => '사용';

  @override
  String get disabledStatus => '사용 안 함';

  @override
  String commandLabel(Object cmd) {
    return '명령: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return '인수: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return '디렉터리: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return '시간 초과: $n초';
  }

  @override
  String get mcpListHint => '팁: MCP 버튼을 두 번 클릭하면 목록, 한 번 클릭하면 전환';

  @override
  String get mcpEnabledMsg => 'MCP 도구 사용, 전송 시 자동 호출';

  @override
  String get mcpDisabledMsg => 'MCP 도구 사용 안 함';

  @override
  String get clearMcpService => 'MCP 서비스 지우기';

  @override
  String get unbindAction => '바인딩 해제';

  @override
  String xTools(Object n) {
    return '$n개 도구';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'MCP 서비스 선택됨: $name';
  }

  @override
  String get mcpToolsDisabled => 'MCP 도구 사용 안 함';

  @override
  String get createAction => '생성';

  @override
  String get noModelBound => '바인딩된 모델 없음';

  @override
  String serviceUnavailable(Object error) {
    return '죄송합니다, 서비스를 일시적으로 사용할 수 없습니다. $error';
  }

  @override
  String get confirmClear => '지우기 확인';

  @override
  String get clearHistoryConfirmMsg => '모든 대화 기록을 지우시겠습니까? 이 작업은 취소할 수 없습니다.';

  @override
  String get historyCleared => '기록 지워짐';

  @override
  String folderPath(Object path) {
    return '폴더: $path';
  }

  @override
  String toolList(Object n) {
    return '도구 목록 ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '... $n개 도구 더';
  }

  @override
  String get jsonCopied => 'JSON 복사됨';

  @override
  String get mcpDetail => 'MCP 세부정보';

  @override
  String toolsRefreshed(Object n) {
    return '$n개 도구 새로고침됨';
  }

  @override
  String refreshFailed(Object error) {
    return '새로고침 실패: $error';
  }

  @override
  String get refreshAction => '새로고침';

  @override
  String toolsFetched(Object n) {
    return '$n개 도구 가져옴';
  }

  @override
  String fetchFailed(Object error) {
    return '가져오기 실패: $error';
  }

  @override
  String get modelConfigNotFound => '모델 구성을 찾을 수 없음';

  @override
  String get modelProviderNotConfigured => '모델 공급자가 구성되지 않았습니다';

  @override
  String get screenshotFailed => '스크린샷 실패: 렌더 객체를 찾을 수 없음';

  @override
  String get generateImageFailed => '이미지 생성 실패';

  @override
  String get messageScreenshotCopied => '메시지 스크린샷이 클립보드에 복사됨';

  @override
  String get currentRoundScreenshotCopied => '라운드 스크린샷이 클립보드에 복사됨';

  @override
  String get fullConversationScreenshotCopied => '전체 대화 스크린샷이 클립보드에 복사됨';

  @override
  String get noMessagesInConversation => '대화에 메시지가 없음';

  @override
  String get cannotFindMessage => '메시지를 찾을 수 없음';

  @override
  String get cannotFindCompleteRound => '완전한 대화 라운드를 찾을 수 없음';

  @override
  String partialScreenshot(Object n, Object total) {
    return '일부 메시지를 캡처할 수 없습니다. $n/$total개 메시지 캡처됨';
  }

  @override
  String get renderObjectStillDrawing => '스크린샷 실패: 렌더 객체가 아직 그리는 중';

  @override
  String screenshotCopied(Object type) {
    return '$type 스크린샷이 클립보드에 복사됨';
  }

  @override
  String screenshotTypeFailed(Object error, Object type) {
    return '$type 스크린샷 실패: $error';
  }

  @override
  String mergeScreenshotFailed(Object error) {
    return '병합 스크린샷 실패: $error';
  }

  @override
  String copyImageFailed(Object error) {
    return '이미지 복사 실패: $error';
  }

  @override
  String get unsupportedOS => '지원되지 않는 OS';

  @override
  String desktopCopyFailed(Object error) {
    return '데스크톱 이미지 복사 실패: $error';
  }

  @override
  String get noClipboardTool => '클립보드 도구 없음 (xclip 또는 wl-copy)';

  @override
  String get cannotFindRenderObject => '메시지 렌더 객체를 찾을 수 없음';

  @override
  String get cronExpression => 'Cron 식';

  @override
  String get cronFormat => '형식: 분 시 일 월 요일 (5개 필드)';

  @override
  String get messageContentLabel => '메시지 내용';

  @override
  String get enableTask => '작업 사용';

  @override
  String get pleaseEnterCron => 'Cron 식을 입력하세요';

  @override
  String get cronFormatError => 'Cron 형식 오류 (5개 필드 필요)';

  @override
  String get daily0900 => '매일 09:00';

  @override
  String get daily1200 => '매일 12:00';

  @override
  String get daily1800 => '매일 18:00';

  @override
  String get workday0900 => '평일 09:00';

  @override
  String get every30min => '30분마다';

  @override
  String get every2h => '2시간마다';

  @override
  String get processFailedStatus => '처리 실패';

  @override
  String get processingStatus => '처리 중';

  @override
  String contentPreviewTitle(Object name) {
    return '$name - 내용 미리보기';
  }

  @override
  String get contentCopiedToClipboard => '내용이 클립보드에 복사됨';

  @override
  String get fileProcessFailed => '파일 처리 실패';

  @override
  String get pleaseReupload => '파일을 다시 업로드하거나 지원에 문의하세요';

  @override
  String get processingFileStatus => '파일 처리 중...';

  @override
  String get imageFile => '이미지 파일';

  @override
  String get documentFile => '문서 파일';

  @override
  String get textFile => '텍스트 파일';

  @override
  String get codeFile => '코드 파일';

  @override
  String get officeDocument => '오피스 문서';

  @override
  String get webLink => '웹 링크';

  @override
  String get folderType => '폴더';

  @override
  String get otherFile => '기타 파일';

  @override
  String get defaultConversation => '일반 대화';

  @override
  String modelCopied(Object name) {
    return '\"$name\"이(가) 복사되었습니다';
  }

  @override
  String copyOf(Object name) {
    return '\"$name 사본\"';
  }

  @override
  String copyOfN(Object n, Object name) {
    return '\"$name 사본 ($n)\"';
  }

  @override
  String get noModels => '모델 없음';

  @override
  String get clickAddModelHint => '\"모델 추가\" 버튼을 클릭하여 시작';

  @override
  String modelUpdatedNotify(Object name) {
    return '\"$name\" 업데이트됨, 관련 세션 설정 동기화됨';
  }

  @override
  String serviceRemoved(Object name) {
    return '서비스 제거됨: $name';
  }

  @override
  String get connectorManagementTitle => '커넥터 관리 (MCP)';

  @override
  String get marketplace => '마켓플레이스';

  @override
  String get noMcpServices => 'MCP 서비스 없음';

  @override
  String get clickToEnterMarketplace => '\"+\" 버튼을 클릭하여 마켓플레이스로 이동';

  @override
  String fetchToolsFailed(Object error) {
    return '도구 가져오기 실패: $error';
  }

  @override
  String get removeServiceLabel => '서비스 제거';

  @override
  String get removeServiceConfirm => '서비스를 제거하시겠습니까';

  @override
  String get removeServiceWarning => '제거 후 다시 추가해야 합니다';

  @override
  String get jsonConfig => 'JSON 설정';

  @override
  String get cannotReadFilePath => '파일 경로를 읽을 수 없음';

  @override
  String get extractingImport => '가져오기 압축 해제 중...';

  @override
  String importFailed(Object error) {
    return '가져오기 실패: $error';
  }

  @override
  String get irreversibleAction => '이 작업은 되돌릴 수 없습니다';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => '모델 삭제됨';

  @override
  String modelDeletedSuccessfully(Object name) {
    return '\"$name\"이(가) 삭제되었습니다';
  }

  @override
  String get selectOtherModelFromList => '다른 모델을 선택하여 세부정보 보기';

  @override
  String get unnamedModel => '이름 없는 모델';

  @override
  String get noDescription => '설명 없음';

  @override
  String get confirmDeleteModel => '모델을 삭제하시겠습니까';

  @override
  String modelDeletedToast(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String get addOnlineModel => '온라인 모델 추가';

  @override
  String get selectProvider => '공급자 선택';

  @override
  String get configureParams => '매개변수 구성';

  @override
  String get checkConfig => '구성 확인';

  @override
  String get setName => '이름 설정';

  @override
  String get nextStep => '다음';

  @override
  String get selectOnlineProvider => '온라인 모델 공급자 선택';

  @override
  String get customProvider => '사용자 정의';

  @override
  String get customProviderDesc => '주소, API 키, 모델 이름을 직접 입력';

  @override
  String get customProviderConfigTitle => '사용자 정의 모델 구성';

  @override
  String configureProviderParams(Object provider) {
    return '$provider 매개변수 구성';
  }

  @override
  String get ollamaApiKeyOptional =>
      '로컬 Ollama 서비스는 보통 API 키가 필요 없으며 비워둘 수 있습니다';

  @override
  String get apiAddress => 'API 주소';

  @override
  String get defaultApiUrlNote => '기본 공식 API 주소, 로컬 또는 프라이빗 배포용으로 수정 가능';

  @override
  String get presetModel => '프리셋 모델';

  @override
  String get customModel => '사용자 정의 모델';

  @override
  String get enterFullModelName => '공급자가 지원하는 전체 모델 이름 입력';

  @override
  String get ollamaRunningModels => 'Ollama 실행 모델';

  @override
  String get refreshModelList => '모델 목록 새로고침';

  @override
  String get ollamaStartHint =>
      '먼저 Ollama 서비스를 시작하고 모델을 다운로드한 후\n새로고침을 클릭하여 모델 목록을 가져오세요';

  @override
  String get modelscopeAvailableModels => 'ModelScope 사용 가능 모델';

  @override
  String get modelscopeApiKeyHint =>
      'API 키가 올바른지 확인한 후\n새로고침을 클릭하여 모델 목록을 가져오세요';

  @override
  String get setModelName => '모델 이름 설정';

  @override
  String get configSummary => '구성 요약';

  @override
  String get providerLabel => '공급자';

  @override
  String get platformLabel => '플랫폼';

  @override
  String get notSet => '설정 안 됨';

  @override
  String get modelLabel => '모델';

  @override
  String get customSuffix => '(사용자 정의)';

  @override
  String get notSelected => '선택 안 됨';

  @override
  String get customModelName => '사용자 정의 모델 이름';

  @override
  String enterModelNameHint(Object provider) {
    return '모델 이름 입력 (예: $provider-Chat)';
  }

  @override
  String get modelNameSuggestion => '식별하기 쉽도록 의미 있는 이름 사용';

  @override
  String get testConnectionDesc => '모델 연결 및 응답 테스트';

  @override
  String get waitingForResponse => '응답 대기 중...';

  @override
  String get configIncomplete => '구성이 불완전함';

  @override
  String get receivedEmptyResponse => '빈 응답 수신';

  @override
  String get receivedNoResponse => '응답 없음';

  @override
  String connectionFailed(Object error) {
    return '연결 실패: $error';
  }

  @override
  String get contextCap => '컨텍스트';

  @override
  String get thinkingCap => '사고';

  @override
  String get builtinToolsCap => '내장 도구';

  @override
  String get structuredCap => '구조화';

  @override
  String get batchCap => '배치';

  @override
  String get basicInfo => '기본 정보';

  @override
  String get modelParams => '모델 설정';

  @override
  String get unknown => '알 수 없음';

  @override
  String get nameLabel => '이름';

  @override
  String get apiKeyLabel => 'API 키';

  @override
  String get notSetDoubleClickToEdit => '설정 안 됨 (두 번 클릭하여 편집)';

  @override
  String get apiKeySaved => 'API 키 저장됨';

  @override
  String get modelNameCannotBeEmpty => '모델 이름은 비워둘 수 없음';

  @override
  String get modelNameSaved => '모델 이름 저장됨';

  @override
  String get modelSaved => '모델 저장됨';

  @override
  String get temperatureLabel => '온도';

  @override
  String get precise => '정밀';

  @override
  String get neutral => '중립';

  @override
  String get creative => '창의적';

  @override
  String get temperatureDescription =>
      '응답의 무작위성과 창의성을 제어합니다. 값이 낮을수록 보수적, 높을수록 창의적입니다.';

  @override
  String get modelRoleSetting => '모델 역할 설정';

  @override
  String get presetRole => '프리셋 역할';

  @override
  String get roleSettingDescription =>
      '역할 설정은 각 대화 시작 시 모델에 전송되어 역할과 동작을 정의합니다. 모델이 수행할 역할에 맞게 조정하세요.';

  @override
  String get selectPresetRole => '프리셋 역할 선택';

  @override
  String get generalAssistant => '일반 어시스턴트';

  @override
  String get friendlyAssistantDesc => '친근하고 전문적인 AI 어시스턴트';

  @override
  String get spellCheck => '맞춤법 검사';

  @override
  String get spellCheckDesc => '맞춤법 검사 전문가';

  @override
  String get codeExpert => '코드 전문가';

  @override
  String get codeExpertDesc => '프로그래밍 및 개발 기술 전문가';

  @override
  String get legalExpert => '법률 전문가';

  @override
  String get legalExpertDesc => '전문 법률 자문';

  @override
  String get copywriter => '카피라이터';

  @override
  String get copywriterDesc => '창의적 카피라이팅 및 콘텐츠 제작 전문가';

  @override
  String get dataAnalyst => '데이터 분석가';

  @override
  String get dataAnalystDesc => '데이터 분석 및 통계 전문가';

  @override
  String get educationTutor => '교육 튜터';

  @override
  String get educationTutorDesc => '인내심 있는 교육 전문가';

  @override
  String get businessConsultant => '비즈니스 컨설턴트';

  @override
  String get businessConsultantDesc => '비즈니스 관리 및 전략 전문가';

  @override
  String get psychologist => '심리학자';

  @override
  String get psychologistDesc => '전문 정신 건강 상담사';

  @override
  String get versionLabel => '버전';

  @override
  String get workModeSettings => '작업 모드';

  @override
  String get workModeBusiness => '비즈니스';

  @override
  String get workModeBusinessDesc => '비즈니스 협상, 계약 관리, 전략';

  @override
  String get workModeFinance => '금융';

  @override
  String get workModeFinanceDesc => '재무 분석, 세금 계획, 원가 회계';

  @override
  String get workModeLegal => '법률';

  @override
  String get workModeLegalDesc => '법률 작성, 규정 준수 검토, 위험 평가';

  @override
  String get workModeMarketing => '마케팅';

  @override
  String get workModeMarketingDesc => '마케팅 기획, 브랜드 홍보, 경쟁 분석';

  @override
  String get domainSettings => '도메인 설정';

  @override
  String get serviceStatus => '로컬 서비스';

  @override
  String get localService => '로컬 서비스';

  @override
  String get serviceStopped => '서비스 중지됨';

  @override
  String get serviceRunning => '실행 중';

  @override
  String get serviceStarting => '시작 중...';

  @override
  String get restart => '다시 시작';

  @override
  String get certificateSettings => '인증서 설정';

  @override
  String get httpsStatus => 'HTTPS 상태';

  @override
  String get domainAddress => '도메인 주소';

  @override
  String get domainHint => '예: api.example.com';

  @override
  String get domainDesc =>
      '설정 후 세션 서비스 URL이 이 주소를 사용합니다. HTTP 기본 포트 80, HTTPS 기본 포트 443.';

  @override
  String get portSettings => '포트 설정';

  @override
  String get httpPort => 'HTTP 포트';

  @override
  String get httpsPort => 'HTTPS 포트';

  @override
  String get portDesc =>
      'HTTP 수신 포트, 기본값 80. HTTPS 수신 포트, 기본값 443. 변경 적용을 위해 서비스를 다시 시작하세요.';

  @override
  String get sslCertificate => 'SSL 인증서';

  @override
  String get sslPrivateKey => '개인 키';

  @override
  String get enabled => '사용';

  @override
  String get disabled => '사용 안 함';

  @override
  String get httpsEnabled => 'HTTPS';

  @override
  String get httpsEnabledDesc => '인증서 업로드됨, HTTPS 자동 사용';

  @override
  String get httpsDisabledDesc => '인증서(crt/cert + key)를 업로드하여 HTTPS 자동 사용';

  @override
  String get domainInfoDesc =>
      '서비스 주소 구성 후 세션 서비스 URL에 이 주소가 표시됩니다. 외부 클라이언트는 이 주소를 통해 세션 API(/chat/completions 등)에 접근할 수 있습니다.';

  @override
  String get pleaseEnterDomain => '서비스 주소를 입력하세요';

  @override
  String get domainSaved => '서비스 구성 저장됨';

  @override
  String get currencyLabel => '통화';

  @override
  String get cny => 'CNY';

  @override
  String get usd => 'USD';

  @override
  String get loadingPageSubtitle => '지능형 기업 AI 작업 공간';

  @override
  String get billingSettings => '청구';

  @override
  String get mcpSettings => 'MCP 설정';

  @override
  String get currencyTypeLabel => '통화 유형';

  @override
  String get inputPriceLabel => '입력 가격';

  @override
  String get outputPriceLabel => '출력 가격';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/백만 토큰';
  }

  @override
  String priceUnitDescription(Object unit) {
    return '가격: $unit/백만 토큰. 누적 세션 비용 계산에 사용됩니다.';
  }

  @override
  String get examplePriceHint => '예: 0.14';

  @override
  String get mcpBindingDescription =>
      '모델에 MCP 서비스를 바인딩하면 이 모델을 사용하는 세션에서 이러한 MCP 도구가 자동으로 주입됩니다. 세션 MCP와 모델 MCP는 자동으로 병합 및 중복 제거됩니다.';

  @override
  String get addMcpServiceButton => 'MCP 서비스 추가';

  @override
  String get clearAllMcpBindings => '모든 MCP 바인딩 지우기';

  @override
  String get selectMcpServiceMultiSelect => 'MCP 서비스 선택 (다중 선택)';

  @override
  String get noMcpServiceAddFirst => 'MCP 서비스 없음, 먼저 MCP 관리에서 추가하세요';

  @override
  String confirmWithCount(Object count) {
    return '확인 ($count)';
  }

  @override
  String get temperaturePrecise => '정밀';

  @override
  String get temperatureConservative => '보수적';

  @override
  String get temperatureNeutral => '중립';

  @override
  String get temperatureCreative => '창의적';

  @override
  String get temperatureRandom => '무작위';

  @override
  String xToolsCount(Object n) {
    return '$n개 도구';
  }

  @override
  String get newConversationDefault => '새 대화';

  @override
  String get usageDashboard => '사용량 대시보드';

  @override
  String get globalUsageDashboard => '전체 사용량 대시보드';

  @override
  String sessionUsageTitle(Object name) {
    return '$name 사용량';
  }

  @override
  String get noSessionData => '세션 데이터 없음';

  @override
  String get noUsageData => '사용량 데이터 없음';

  @override
  String get overview => '개요';

  @override
  String get statMessages => '메시지';

  @override
  String get totalMessages => '총 메시지';

  @override
  String get inputTokens => '입력 토큰';

  @override
  String get outputTokens => '출력 토큰';

  @override
  String get totalCostLabel => '총 비용';

  @override
  String get tokenDistribution => '토큰 분포';

  @override
  String get modelInfo => '모델 정보';

  @override
  String get quotaLimitSection => '할당량 제한';

  @override
  String get usageCurve => '사용량 곡선';

  @override
  String get totalSessions => '총 세션';

  @override
  String get totalTokens => '총 토큰';

  @override
  String get byModel => '모델별';

  @override
  String get allSessions => '모든 세션';

  @override
  String moreSessionsNoData(Object count) {
    return '다른 $count개 세션에 사용량 데이터 없음';
  }

  @override
  String get inputLabel => '입력';

  @override
  String get outputLabel => '출력';

  @override
  String get noQuotaLimit => '할당량 제한 미설정';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count개 세션';
  }

  @override
  String get granMinute => '분';

  @override
  String get granHour => '시간';

  @override
  String get granDay => '일';

  @override
  String get granMonth => '월';

  @override
  String get granYear => '년';

  @override
  String get selectDate => '날짜 선택';

  @override
  String get rangeStart => '시작';

  @override
  String get rangeEnd => '종료';

  @override
  String get startDateHelp => '시작 날짜';

  @override
  String get endDateHelp => '종료 날짜';

  @override
  String get tokenToggle => '토큰';

  @override
  String get costToggle => '비용';

  @override
  String chartLegendCost(Object symbol) {
    return '비용 ($symbol)';
  }

  @override
  String get noSessionConfig => '세션 구성 없음';

  @override
  String get resetApiKey => 'API 키 재설정';

  @override
  String get resetApiKeyConfirm =>
      '이 세션의 API 키를 재설정하시겠습니까? 재설정 후 이전 키는 즉시 무효화되며 이전 키를 사용하는 외부 요청은 접근할 수 없습니다.';

  @override
  String get confirmReset => '재설정 확인';

  @override
  String get connectorSkillRelation => '커넥터와 스킬 관계 설명';

  @override
  String modelPricing(Object unit) {
    return '모델 가격 ($unit/백만 토큰)';
  }

  @override
  String get billingInfoLabel => '청구 정보';

  @override
  String get cumulativeInputTokens => '누적 입력 토큰';

  @override
  String get cumulativeOutputTokens => '누적 출력 토큰';

  @override
  String get cumulativeCost => '누적 비용';

  @override
  String get basicInfoLabel => '기본 정보';

  @override
  String get sessionName => '세션 이름';

  @override
  String get organization => '조직';

  @override
  String get groupLabel => '그룹';

  @override
  String get notSpecified => '지정 안 됨';

  @override
  String get notGrouped => '그룹 없음';

  @override
  String get boundModel => '바인딩된 모델';

  @override
  String get relatedPrompt => '관련 프롬프트';

  @override
  String get messageCountLabel => '메시지 수';

  @override
  String get serviceConfigLabel => '서비스 구성';

  @override
  String get serviceAddress => '서비스 주소';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => '모델 MCP';

  @override
  String get sessionMcp => '세션 MCP';

  @override
  String get notBound => '바인딩 안 됨';

  @override
  String get addMcpHint => '모델 관리 또는 채팅 입력 상자에서 MCP 서비스를 추가할 수 있습니다';

  @override
  String get usageQuotaLabel => '사용량 할당량';

  @override
  String get noAuthAccess => '인증 없음 접근';

  @override
  String get noAuthEnabledDesc => '⚠️ 인증 비활성화, 누구나 접근 가능';

  @override
  String get noAuthDisabledDesc => '사용: API 키 없이 접근';

  @override
  String get disableSession => '세션 비활성화';

  @override
  String get disabledEnabledDesc => '⚠️ 비활성화됨, 호출 시 오류 반환';

  @override
  String get disabledDisabledDesc => '사용: 이 세션을 호출할 수 없음';

  @override
  String get systemPromptHint => '이 세션의 역할/동작 설정 (예: 전문 법률 자문입니다...)';

  @override
  String get systemPromptDesc => '최우선 명령으로 설정, 타사 요청 시 자동 주입. 비우면 주입하지 않음.';

  @override
  String get tokenUsageLimit => '토큰 사용량 제한';

  @override
  String costBudgetLimit(Object unit) {
    return '비용 예산 제한 ($unit)';
  }

  @override
  String get requestLimit => '요청 제한';

  @override
  String get noLimit => '제한 없음';

  @override
  String get enableUsageLimit => '사용량 제한 사용';

  @override
  String get reachLimitReject => '제한 도달 후 새 요청이 거부됩니다';

  @override
  String get resetPeriod => '재설정 주기';

  @override
  String get resetPeriodNever => '자동 재설정 안 함';

  @override
  String get resetPeriodDaily => '매일 재설정';

  @override
  String get resetPeriodMonthly => '매월 재설정';

  @override
  String get quotaExhausted => '할당량 소진';

  @override
  String get currentUsageStatus => '현재 사용 상태';

  @override
  String get quotaTokenLabel => '토큰';

  @override
  String get quotaCostLabel => '비용';

  @override
  String get quotaRequestLabel => '요청';

  @override
  String get manualResetUsage => '수동 사용량 재설정';

  @override
  String get manualResetConfirmDesc => '수동 재설정 확인';

  @override
  String get manualResetWarning =>
      '재설정 후 현재 기간의 토큰 사용량, 비용, 요청 수가 지워지고 기간 시작 시간이 현재 시간으로 업데이트됩니다.';

  @override
  String get tokenUsage => '토큰 사용량';

  @override
  String get costUsage => '비용 사용량';

  @override
  String get resetValue => '재설정';

  @override
  String get apiKeyReset => 'API 키 재설정됨';

  @override
  String get securitySettings => '보안';

  @override
  String get sensitiveInfoMasking => '민감 정보 마스킹';

  @override
  String get sensitiveInfoMaskingDesc =>
      '사용하면 모델에 전송되는 메시지 및 로컬 감사 로그의 해당 정보가 \'*\'로 대체되어 평문 개인정보 유출을 방지합니다.';

  @override
  String get maskPhoneTitle => '전화번호 마스킹';

  @override
  String get maskPhoneSubtitle => '메시지의 전화번호를 \'*\'로 대체';

  @override
  String get maskIdCardTitle => '신분증 번호 마스킹';

  @override
  String get maskIdCardSubtitle => '메시지의 신분증 번호를 \'*\'로 대체';

  @override
  String get sessionDetails => '세션 세부정보';

  @override
  String get modelDetails => '모델 세부정보';

  @override
  String modelDetailsWithPlatform(String platform) {
    return '모델 세부정보 · $platform';
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
