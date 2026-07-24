// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'LLMate';

  @override
  String get appSlogan => 'ผู้ช่วยสนทนาอัจฉริยะ';

  @override
  String get feedback => 'ข้อเสนอแนะ';

  @override
  String get modelManagement => 'การจัดการแบบจำลอง';

  @override
  String get connectorManagement => 'การจัดการตัวเชื่อมต่อ (MCP)';

  @override
  String get domainManagement => 'Service Management';

  @override
  String get otherSettings => 'การตั้งค่าอื่นๆ';

  @override
  String get resetSystem => 'รีเซ็ตระบบ';

  @override
  String get resetAllSessions => 'รีเซ็ตเซสชันทั้งหมด';

  @override
  String get resetAllModels => 'รีเซ็ตโมเดลทั้งหมด';

  @override
  String get resetAllMcp => 'รีเซ็ต MCP ทั้งหมด';

  @override
  String get resetAll => 'รีเซ็ตทั้งหมด';

  @override
  String resetConfirmMsg(Object action) {
    return 'แน่ใจหรือไม่ว่าต้องการ$action? การดำเนินการนี้ไม่สามารถย้อนกลับได้';
  }

  @override
  String get languageSettings => 'การตั้งค่าภาษา';

  @override
  String get skinSettings => 'การตั้งค่าสกิน';

  @override
  String get followSystem => 'ทำตามระบบ';

  @override
  String get followSystemDesc => 'สลับระหว่างโหมดสว่าง/มืดโดยอัตโนมัติ';

  @override
  String get lightMode => 'โหมดแสง';

  @override
  String get lightModeDesc => 'ใช้ธีมสว่างเสมอ';

  @override
  String get darkMode => 'โหมดมืด';

  @override
  String get darkModeDesc => 'ใช้ธีมสีเข้มเสมอ';

  @override
  String get chinese => 'ชาวจีน';

  @override
  String get chineseDesc => 'จีนตัวย่อ';

  @override
  String get english => 'ภาษาอังกฤษ';

  @override
  String get englishDesc => 'ภาษาอังกฤษ';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get delete => 'ลบ';

  @override
  String get save => 'บันทึก';

  @override
  String get edit => 'แก้ไข';

  @override
  String get add => 'เพิ่มไปที่';

  @override
  String get close => 'ปิด';

  @override
  String get remove => 'ลบ';

  @override
  String get clear => 'ชัดเจน';

  @override
  String get search => 'ค้นหา';

  @override
  String get noData => 'ยังไม่มีข้อมูล';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get send => 'ส่ง';

  @override
  String get copy => 'สำเนา';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get copyContent => 'คัดลอกเนื้อหา';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get done => 'เสร็จ';

  @override
  String get back => 'กลับ';

  @override
  String get previousStep => 'ขั้นตอนก่อนหน้า';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get systemPrompt => 'คำแจ้งของระบบ';

  @override
  String get temperature => 'พารามิเตอร์อุณหภูมิ';

  @override
  String get replyLanguage => 'ตอบภาษา';

  @override
  String get newSession => 'เซสชันใหม่';

  @override
  String get sessionList => 'รายการสนทนา';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get shareConversation => 'แบ่งปันการสนทนา';

  @override
  String get exportData => 'ส่งออกข้อมูล';

  @override
  String get importData => 'นำเข้าข้อมูล';

  @override
  String get clearConversation => 'บทสนทนาที่ชัดเจน';

  @override
  String get deleteConversation => 'ลบเซสชัน';

  @override
  String get deleteConfirm => 'ยืนยันการลบ';

  @override
  String get deleteConfirmMsg => 'คุณแน่ใจหรือไม่ว่าต้องการลบมัน?';

  @override
  String removeConfirmMsg(Object name) {
    return 'คุณแน่ใจหรือไม่ว่าต้องการลบ \"$name\"?';
  }

  @override
  String get addModel => 'เพิ่มรุ่น';

  @override
  String get copyModel => 'คัดลอกโมเดล';

  @override
  String get modelName => 'ชื่อรุ่น';

  @override
  String get modelProvider => 'ผู้ให้บริการ';

  @override
  String get modelApiKey => 'คีย์เอพีไอ';

  @override
  String get modelBaseUrl => 'ที่อยู่อินเทอร์เฟซ';

  @override
  String get modelMaxTokens => 'จำนวนโทเค็นสูงสุด';

  @override
  String get thinkTag => 'คิดว่าฉลาก';

  @override
  String get thinkTagDesc => 'แท็กกระบวนการคิดแบบจำลอง';

  @override
  String get addService => 'เพิ่มบริการ';

  @override
  String get removeService => 'ลบบริการ';

  @override
  String get testConnection => 'ทดสอบการเชื่อมต่อ';

  @override
  String get fullTest => 'การทดสอบเต็มรูปแบบ';

  @override
  String get connectAndAdd => 'เชื่อมต่อและเพิ่ม';

  @override
  String get addCustomConnector => 'เพิ่มตัวเชื่อมต่อแบบกำหนดเอง';

  @override
  String get clearKey => 'กุญแจที่ชัดเจน';

  @override
  String get fetchTools => 'รับรายการเครื่องมือ';

  @override
  String get fetchModels => 'รับรายชื่อรุ่น';

  @override
  String get copyMessage => 'คัดลอกข้อความ';

  @override
  String get regenerate => 'สร้างใหม่';

  @override
  String get regenerateFromHere => 'สร้างใหม่จากที่นี่';

  @override
  String get regenerateLastReply => 'สร้างการตอบกลับล่าสุดอีกครั้ง';

  @override
  String get regenerateThisReply => 'สร้างการตอบกลับนี้ใหม่';

  @override
  String get createNewChatFromHere => 'สร้างการสนทนาใหม่จากที่นี่';

  @override
  String get deleteMessage => 'ลบข้อความ';

  @override
  String get deleteReply => 'ลบการตอบกลับ';

  @override
  String get screenshot => 'ภาพหน้าจอ';

  @override
  String get entireConversation => 'บทสนทนาทั้งหมด';

  @override
  String get currentRound => 'รอบปัจจุบัน';

  @override
  String get currentMessage => 'ข่าวปัจจุบัน';

  @override
  String get memoryConfig => 'การกำหนดค่าหน่วยความจำ';

  @override
  String get clearMcpServices => 'ล้างบริการ MCP';

  @override
  String get selectFile => 'เลือกไฟล์';

  @override
  String get selectWorkingDir => 'เลือกไดเร็กทอรีการทำงาน';

  @override
  String get confirmDeleteTitle => 'ยืนยันการลบ';

  @override
  String get deleteSessionTitle => 'ลบเซสชัน';

  @override
  String get favorites => 'เก็บรวบรวม';

  @override
  String get today => 'วันนี้';

  @override
  String get yesterday => 'เมื่อวาน';

  @override
  String get earlier => 'ก่อนหน้านี้';

  @override
  String get removeServiceTitle => 'ลบบริการ';

  @override
  String get removeMcpServiceTitle => 'ลบบริการ MCP';

  @override
  String get noActiveSession => 'ขณะนี้ไม่มีเซสชันที่ใช้งานอยู่';

  @override
  String get presetRoleApplied => 'ใช้บทบาทเริ่มต้นแล้ว';

  @override
  String get fileNotFound => 'ไม่มีไฟล์อยู่';

  @override
  String get fileOpenFailed => 'ไม่สามารถเปิดไฟล์ได้';

  @override
  String get enterMessageContent => 'กรุณากรอกเนื้อหาข้อความ';

  @override
  String get copyMessageContent => 'คัดลอกเนื้อหาข้อความ';

  @override
  String get apiKeyHint => 'กรุณากรอกรหัส API';

  @override
  String get modelNameHint => 'กรุณากรอกชื่อรุ่น';

  @override
  String get messageHint => 'กรุณากรอกเนื้อหาข้อความ...';

  @override
  String get apiUrlHint => 'ป้อนที่อยู่ API';

  @override
  String get commandHint => 'ป้อนเนื้อหาของคำสั่งทางลัด';

  @override
  String get enterCommandContent => 'กรุณากรอกเนื้อหาคำสั่ง';

  @override
  String get modelSearchHint =>
      'ป้อนชื่อรุ่น เช่น gpt-4o-mini, claude-3-haiku เป็นต้น';

  @override
  String get roleDescHint =>
      'กรุณากรอกคำอธิบายชุดอักขระที่ใช้เป็นแนวทางพฤติกรรมและรูปแบบการตอบสนองของโมเดลขนาดใหญ่...';

  @override
  String get toolLogicHint => 'โปรดป้อนคำอธิบายตรรกะการทำงานของเครื่องมือ...';

  @override
  String get typeCommandOrSearch => 'พิมพ์คำสั่งหรือค้นหา...';

  @override
  String get searchMcp => 'ค้นหาบริการ MCP...';

  @override
  String get cronExample => 'ตัวอย่าง: 0 9 * * * (9:00 น. ทุกวัน)';

  @override
  String get config => 'การกำหนดค่า';

  @override
  String get pasteMcpCode => 'กรุณาวางรหัส MCP';

  @override
  String get fileNameLabel => 'ชื่อไฟล์';

  @override
  String get fileSizeLabel => 'ขนาด';

  @override
  String get fileTypeLabel => 'พิมพ์';

  @override
  String get filePathLabel => 'เส้นทาง';

  @override
  String get aliyun => 'อาลีบาบา คลาวด์';

  @override
  String get tencentCloud => 'เทนเซ็นต์ คลาวด์';

  @override
  String get modelscope => 'หอคอยเวทย์มนตร์';

  @override
  String get goToAliyun => 'ไปที่ Alibaba Cloud เพื่อเปิดใช้งาน';

  @override
  String pleaseEnter(Object field) {
    return 'กรุณากรอก $field';
  }

  @override
  String get more => 'มากกว่า';

  @override
  String get copyFailed => 'การคัดลอกล้มเหลว';

  @override
  String get invalidLinkFormat => 'รูปแบบลิงก์ไม่ถูกต้อง';

  @override
  String get cannotOpenLink => 'ไม่สามารถเปิดลิงก์ได้';

  @override
  String get linkOpenedInBrowser => 'ลิงก์เปิดในเบราว์เซอร์';

  @override
  String get cannotOpenThisLinkType => 'ไม่สามารถเปิดลิงก์ประเภทนี้ได้';

  @override
  String get openLinkFailed => 'ไม่สามารถเปิดลิงก์ได้';

  @override
  String get fileOpened => 'เปิดไฟล์แล้ว';

  @override
  String get cannotOpenFile => 'ไม่สามารถเปิดไฟล์ได้';

  @override
  String get openFileFailed => 'ไม่สามารถเปิดไฟล์ได้';

  @override
  String get sessionNotFoundForMessage => 'ไม่พบการสนทนาที่มีข้อความ';

  @override
  String get messageNotFound => 'ไม่มีข้อความนี้';

  @override
  String get regenerateFailed => 'การฟื้นฟูล้มเหลว';

  @override
  String get cannotFindQuestion => 'ไม่พบคำถามที่เกี่ยวข้อง';

  @override
  String get noAiReplyFound => 'ไม่พบคำตอบจาก AI';

  @override
  String get cannotRegenerateInvalidIndex =>
      'ไม่สามารถสร้างใหม่ได้: ดัชนีข้อความไม่ถูกต้อง';

  @override
  String get editMessageTitle => 'แก้ไขข้อความ';

  @override
  String get messageContentCannotBeEmpty =>
      'เนื้อหาข้อความไม่สามารถเว้นว่างได้';

  @override
  String get newChatFromHistory => 'บทสนทนาใหม่ตามประวัติศาสตร์';

  @override
  String get newChatCreatedFromHere => 'มีการสร้างการสนทนาใหม่จากที่นี่';

  @override
  String get createNewChatFailed => 'ไม่สามารถสร้างการสนทนาใหม่ได้';

  @override
  String get thinking => 'กำลังคิด...';

  @override
  String get callingTool => 'เครื่องมือการโทร';

  @override
  String get toolCallRecord => 'บันทึกการโทรของเครื่องมือ';

  @override
  String get messageDeleted => 'ลบข้อความแล้ว';

  @override
  String get deleteMessageFailed => 'ลบข้อความไม่สำเร็จ';

  @override
  String get duration => 'ใช้เวลานาน';

  @override
  String get calculating => 'กำลังคำนวณ...';

  @override
  String get speed => 'ความเร็ว';

  @override
  String get outputTokensLabel => 'สร้างหมายเลขโทเค็น';

  @override
  String get fullscreen => 'เต็มจอ';

  @override
  String get collapseSidebar => 'ยุบแถบด้านข้าง';

  @override
  String get expandSidebar => 'ขยายแถบด้านข้าง';

  @override
  String get collapseRightSidebar => 'ยุบคอลัมน์ทางขวา';

  @override
  String get expandRightSidebar => 'ขยายคอลัมน์ทางขวา';

  @override
  String get unfavorite => 'ยกเลิกรายการโปรด';

  @override
  String get favoriteSession => 'บทสนทนาที่ชอบ';

  @override
  String get user => 'ผู้ใช้';

  @override
  String get assistant => 'ผู้ช่วย';

  @override
  String get noMemory => 'ยังไม่มีความทรงจำ';

  @override
  String get noFiles => 'ยังไม่มีไฟล์';

  @override
  String get fileInfo => 'ข้อมูลไฟล์';

  @override
  String get fileContent => 'เนื้อหาไฟล์';

  @override
  String get noContentPreview => 'ยังไม่มีการแสดงตัวอย่างเนื้อหา';

  @override
  String get fileContentCopied => 'คัดลอกเนื้อหาไฟล์ไปยังคลิปบอร์ดแล้ว';

  @override
  String get selectOrCreateSession => 'โปรดเลือกหรือสร้างเซสชัน';

  @override
  String get invalidSessionIndex => 'ดัชนีเซสชันไม่ถูกต้อง';

  @override
  String get cannotOpenEmailApp => 'ไม่สามารถเปิดแอปอีเมลได้';

  @override
  String get sendEmailFailed => 'ไม่สามารถส่งอีเมลได้';

  @override
  String get memorySummary => 'สรุปหน่วยความจำ';

  @override
  String get recentConversations => 'การสนทนาล่าสุด';

  @override
  String get sessionFiles => 'ไฟล์เซสชัน';

  @override
  String get files => 'เอกสาร';

  @override
  String get memory => 'หน่วยความจำ';

  @override
  String get processed => 'ดำเนินการแล้ว';

  @override
  String todayTime(Object time) {
    return 'วันนี้ $time';
  }

  @override
  String monthDayTime(Object day, Object month, Object time) {
    return '$month/$day $time';
  }

  @override
  String messageCount(Object count) {
    return '$count รายการ';
  }

  @override
  String xFailed(Object action, Object error) {
    return '$action ล้มเหลว: $error';
  }

  @override
  String xDone(Object action) {
    return '$action เสร็จสมบูรณ์';
  }

  @override
  String get copiedToClipboard => 'คัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get replyDeleted => 'การตอบกลับข้อความนี้ทั้งหมดถูกลบแล้ว';

  @override
  String get deleteReplyFailed => 'ลบการตอบกลับไม่สำเร็จ';

  @override
  String get asConversationContinues =>
      'เมื่อการสนทนาดำเนินไป AI โดยอัตโนมัติ\nบันทึกและบีบอัดความทรงจำการสนทนา';

  @override
  String get whenAiCreatesFiles =>
      'เมื่อเครื่องมือ AI สร้างหรือ\nหลังจากแก้ไขไฟล์แล้วจะแสดงที่นี่';

  @override
  String get deleteSessionTitle_warning => 'การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get pleaseSetupModel => 'โปรดสร้างโมเดลขนาดใหญ่';

  @override
  String get clickToSelectModel => 'คลิกด้านบนเพื่อเลือกรูปแบบการสนทนา';

  @override
  String get selectModel => 'เลือกรูปแบบการสนทนา';

  @override
  String get noAvailableModels => 'ยังไม่มีรุ่นให้เลือก';

  @override
  String get sessionNotFoundCannotSelectModel =>
      'ไม่มีเซสชันปัจจุบันและไม่สามารถเลือกโมเดลได้';

  @override
  String get inputHint => 'ป้อนข้อความที่นี่ ↵ เพื่อส่ง Shift+↵ เพื่อตัด';

  @override
  String get stopAnswer => 'หยุดตอบ';

  @override
  String waitingAttachments(Object count) {
    return 'กำลังรอไฟล์แนบ $count ที่จะประมวลผล';
  }

  @override
  String get sendMessageAction => 'ส่งข้อความ';

  @override
  String get deepThinkEnabled => 'การคิดอย่างลึกซึ้ง: เปิดใช้งาน';

  @override
  String get deepThinkDisabled => 'คิดลึก: ปิด';

  @override
  String get deepThink => 'คิดลึก';

  @override
  String get workingDirectoryLabel => 'ไดเร็กทอรีการทำงาน';

  @override
  String workingDirectoryPath(Object path) {
    return 'ไดเร็กทอรีการทำงาน: $path';
  }

  @override
  String get setWorkingDirHint =>
      'ตั้งค่าไดเร็กทอรีการทำงาน (ตำแหน่งเริ่มต้นที่บันทึกไฟล์)';

  @override
  String get workingDirSet => 'ไดเร็กทอรีการทำงานถูกตั้งค่าแล้ว';

  @override
  String get workingDirCleared => 'ล้างไดเร็กทอรีการทำงานแล้ว';

  @override
  String get noWorkingDir => 'กรุณาตั้งค่าไดเรกทอรีไฟล์สัญญาก่อน';

  @override
  String get parseContract => 'วิเคราะห์สัญญา';

  @override
  String get parseContractHint => 'วิเคราะห์ไฟล์สัญญาในไดเรกทอรีการทำงาน';

  @override
  String get parseContractPrompt =>
      'ต่อไปนี้เป็นไฟล์เอกสารในไดเรกทอรีการทำงาน ก่อนอื่นให้ระบุว่าไฟล์ใดเป็นเอกสารสัญญาที่แท้จริง (ไม่ใช่ไฟล์แนบ คำอธิบาย หรือไฟล์ที่ไม่ใช่สัญญาอื่นๆ) จากนั้นสำหรับเฉพาะไฟล์ที่ยืนยันว่าเป็นสัญญา ให้ใช้เครื่องมือ contract_inspect เพื่อเขียนข้อมูลของแต่ละสัญญา\n\nกฎการเขียน:\n- สำหรับแต่ละสัญญา ให้เรียก action=add ก่อนเพื่อสร้างรายการสัญญา (กรอก contractName, contractType, paymentClause, paymentSchedule, breachClause, liabilityClause, startDate, endDate, signingDate ฯลฯ)\n- จากนั้นเรียก action=addParty สำหรับแต่ละฝ่าย โดยเพิ่มฝ่าย ก. ฝ่าย ข. ทีละรายการ\n- และอธิบายสั้นๆ ในคำตอบว่ามีไฟล์ใดบ้างที่ระบุว่าไม่ใช่สัญญาและเหตุผล';

  @override
  String get contractPoints => 'จุดสัญญา';

  @override
  String get noContracts => 'ไม่มีจุดสัญญา';

  @override
  String get contractParsing => 'จุดสัญญาจะปรากฏที่นี่หลังจากการวิเคราะห์';

  @override
  String get contractParty => 'คู่สัญญา';

  @override
  String get contractPaymentClause => 'ข้อกำหนดการชำระเงิน';

  @override
  String get contractPaymentSchedule => 'กำหนดการชำระเงิน';

  @override
  String get contractBreachClause => 'ข้อกำหนดการผิดสัญญา';

  @override
  String get contractLiability => 'ความรับผิดชอบ';

  @override
  String get contractPeriod => 'ระยะเวลาสัญญา';

  @override
  String get contractSigningDate => 'วันที่ลงนาม';

  @override
  String get contractTypeLabel => 'ประเภทสัญญา';

  @override
  String nRounds(Object n) {
    return '$n รอบ';
  }

  @override
  String memoryConfigTooltip(Object label) {
    return 'การกำหนดค่าหน่วยความจำ: เก็บการสนทนา $label ล่าสุดไว้';
  }

  @override
  String get closeMemory => 'ปิดหน่วยความจำ';

  @override
  String get noContext => 'ไม่มีบริบท';

  @override
  String keepXRounds(Object n) {
    return 'เก็บ $n รอบ';
  }

  @override
  String lastXRounds(Object n) {
    return 'ล่าสุด $n รอบ';
  }

  @override
  String get defaultMemory => 'ค่าเริ่มต้น';

  @override
  String get longConversation => 'การสนทนาที่ยาวนาน';

  @override
  String get veryLongConversation => 'บทสนทนาที่ยาวมาก';

  @override
  String get noMatchingResults => 'ไม่มีผลลัพธ์ที่ตรงกัน';

  @override
  String get memoryClosed => 'หน่วยความจำปิดอยู่';

  @override
  String memoryConfigSet(Object n) {
    return 'การกำหนดค่าหน่วยความจำ: $n รอบ';
  }

  @override
  String get attach => 'ภาคผนวก';

  @override
  String get selectMcpTool => 'เลือกตัวเชื่อมต่อ';

  @override
  String get noMcpTool => 'ไม่มีตัวเชื่อมต่อ';

  @override
  String get viewMcpToolDetail => 'ดูรายละเอียดเครื่องมือ MCP';

  @override
  String get clickToSelectMcpTool => 'คลิกเพื่อเลือกเครื่องมือ MCP';

  @override
  String get noMcpToolConfigured =>
      'โมเดลปัจจุบันไม่ได้รับการกำหนดค่าด้วยเครื่องมือ MCP';

  @override
  String toolWorkflowDescLabel(Object desc) {
    return 'คำอธิบายตรรกะการทำงานของเครื่องมือ: $desc';
  }

  @override
  String get clickToDesignWorkflow =>
      'ตั้งค่าตรรกะการใช้ตัวเชื่อมต่อและทักษะร่วมกัน';

  @override
  String get alreadySet => 'ตั้งไว้แล้ว';

  @override
  String get toolWorkflowDescTitle => 'คำอธิบายตรรกะการทำงานของเครื่องมือ';

  @override
  String get enterToolWorkflowDesc =>
      'โปรดป้อนคำอธิบายตรรกะการทำงานของเครื่องมือ...';

  @override
  String get relationDescCleared => 'ล้างคำอธิบายความสัมพันธ์แล้ว';

  @override
  String get relationDescSaved => 'คำอธิบายความสัมพันธ์ที่บันทึกไว้';

  @override
  String get noMcpServiceConfigured =>
      'บริการ MCP ไม่ได้รับการกำหนดค่าในขณะนี้';

  @override
  String mcpBoundTitle(Object count) {
    return 'MCP ที่ผูกแล้ว ($count)';
  }

  @override
  String get mcpViewDetails => 'ดูรายละเอียด MCP ที่ผูกแล้ว';

  @override
  String mcpServiceList(Object n) {
    return 'รายการบริการ MCP ($n)';
  }

  @override
  String get mcpServiceTitle => 'บริการเอ็มซีพี';

  @override
  String get enabledStatus => 'เปิดใช้งานแล้ว';

  @override
  String get disabledStatus => 'พิการ';

  @override
  String commandLabel(Object cmd) {
    return 'คำสั่ง: $cmd';
  }

  @override
  String argsLabel(Object args) {
    return 'พารามิเตอร์: $args';
  }

  @override
  String workingDirLabel(Object dir) {
    return 'ไดเร็กทอรีการทำงาน: $dir';
  }

  @override
  String timeoutSec(Object n) {
    return 'หมดเวลา: $n วินาที';
  }

  @override
  String get mcpListHint =>
      'เคล็ดลับ: ดับเบิลคลิกปุ่ม MCP เพื่อดูรายการนี้ คลิกเพื่อสลับสถานะสวิตช์';

  @override
  String get mcpEnabledMsg =>
      'เครื่องมือ MCP เปิดอยู่ และสามารถเรียกใช้เครื่องมือที่เกี่ยวข้องได้โดยอัตโนมัติเมื่อส่งข้อความ';

  @override
  String get mcpDisabledMsg => 'เครื่องมือ MCP ถูกปิดแล้ว';

  @override
  String get clearMcpService => 'ล้างบริการ MCP';

  @override
  String get unbindAction => 'เลิกผูก';

  @override
  String xTools(Object n) {
    return '$n เครื่องมือ';
  }

  @override
  String mcpServiceSelected(Object name) {
    return 'บริการ MCP ที่เลือก: $name';
  }

  @override
  String get mcpToolsDisabled => 'เครื่องมือ MCP ถูกปิดแล้ว';

  @override
  String get createAction => 'สร้าง';

  @override
  String get noModelBound => 'โมเดลยังไม่ถูกผูกมัด';

  @override
  String serviceUnavailable(Object error) {
    return 'ขออภัย ไม่สามารถให้บริการได้ชั่วคราว $error';
  }

  @override
  String get confirmClear => 'ยืนยันชัดเจน';

  @override
  String get clearHistoryConfirmMsg =>
      'คุณแน่ใจหรือไม่ว่าต้องการล้างประวัติทั้งหมดสำหรับการสนทนาปัจจุบัน การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get historyCleared => 'ล้างประวัติแล้ว';

  @override
  String folderPath(Object path) {
    return 'โฟลเดอร์: $path';
  }

  @override
  String toolList(Object n) {
    return 'รายการเครื่องมือ ($n)';
  }

  @override
  String moreXTools(Object n) {
    return '...และ $n เครื่องมือ';
  }

  @override
  String get jsonCopied => 'คัดลอก JSON แล้ว';

  @override
  String get mcpDetail => 'รายละเอียด MCP';

  @override
  String toolsRefreshed(Object n) {
    return '$n เครื่องมือได้รับการรีเฟรช';
  }

  @override
  String refreshFailed(Object error) {
    return 'รีเฟรชล้มเหลว: $error';
  }

  @override
  String get refreshAction => 'รีเฟรช';

  @override
  String toolsFetched(Object n) {
    return 'มีเครื่องมือ $n ชิ้น';
  }

  @override
  String fetchFailed(Object error) {
    return 'ไม่สามารถรับ: $error';
  }

  @override
  String get modelConfigNotFound => 'ไม่พบการกำหนดค่าโมเดล';

  @override
  String get modelProviderNotConfigured => 'ไม่ได้กำหนดค่าผู้ให้บริการโมเดล';

  @override
  String get screenshotFailed => 'ภาพหน้าจอล้มเหลว: ไม่พบวัตถุการเรนเดอร์';

  @override
  String get generateImageFailed => 'ไม่สามารถสร้างภาพได้';

  @override
  String get messageScreenshotCopied =>
      'คัดลอกภาพหน้าจอข้อความไปยังคลิปบอร์ดแล้ว';

  @override
  String get currentRoundScreenshotCopied =>
      'ภาพหน้าจอของรอบปัจจุบันได้ถูกคัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get fullConversationScreenshotCopied =>
      'คัดลอกภาพหน้าจอของการสนทนาทั้งหมดไปยังคลิปบอร์ดแล้ว';

  @override
  String get noMessagesInConversation => 'ไม่มีข้อความในการสนทนา';

  @override
  String get cannotFindMessage => 'ไม่พบข้อความปัจจุบัน';

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
  String get connectorManagementTitle => 'MCP管理';

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
  String get jsonConfig => 'JSON 配置';

  @override
  String get cannotReadFilePath => '无法读取文件路径';

  @override
  String get extractingImport => '正在解压导入...';

  @override
  String importFailed(Object error) {
    return '导入失败: $error';
  }

  @override
  String get irreversibleAction => '此操作不可撤销';

  @override
  String toolNameDesc(Object desc, Object name) {
    return '$name · $desc';
  }

  @override
  String get modelDeleted => 'ลบแบบจำลองแล้ว';

  @override
  String modelDeletedSuccessfully(Object name) {
    return 'ลบแบบจำลอง \"$name\" สำเร็จแล้ว';
  }

  @override
  String get selectOtherModelFromList =>
      'โปรดเลือกรุ่นอื่นจากรายการด้านซ้ายเพื่อดูรายละเอียด';

  @override
  String get unnamedModel => 'แบบจำลองที่ไม่มีชื่อ';

  @override
  String get noDescription => 'ไม่มีคำอธิบาย';

  @override
  String get confirmDeleteModel => 'คุณแน่ใจหรือไม่ว่าต้องการลบแบบจำลอง';

  @override
  String modelDeletedToast(Object name) {
    return 'แบบจำลอง \"$name\" ถูกลบแล้ว';
  }

  @override
  String get addOnlineModel => 'เพิ่มแบบจำลองออนไลน์';

  @override
  String get selectProvider => 'เลือกผู้ให้บริการ';

  @override
  String get configureParams => 'กำหนดค่าพารามิเตอร์';

  @override
  String get checkConfig => 'ตรวจสอบการกำหนดค่า';

  @override
  String get setName => 'ตั้งชื่อ';

  @override
  String get nextStep => 'ถัดไป';

  @override
  String get selectOnlineProvider => 'เลือกผู้ให้บริการแบบจำลองออนไลน์';

  @override
  String get customProvider => 'กำหนดเอง';

  @override
  String get customProviderDesc =>
      'ป้อนที่อยู่, คีย์ API และชื่อแบบจำลองด้วยตนเอง';

  @override
  String get customProviderConfigTitle => 'การกำหนดค่าแบบจำลองที่กำหนดเอง';

  @override
  String configureProviderParams(Object provider) {
    return 'กำหนดค่าพารามิเตอร์ $provider';
  }

  @override
  String get ollamaApiKeyOptional =>
      'บริการ Ollama ท้องถิ่นมักไม่ต้องใช้คีย์ API สามารถเว้นว่างได้';

  @override
  String get apiAddress => 'ที่อยู่ API';

  @override
  String get defaultApiUrlNote =>
      'ที่อยู่ API อย่างเป็นทางการเริ่มต้น สามารถปรับเปลี่ยนสำหรับการใช้งานท้องถิ่นหรือส่วนตัว';

  @override
  String get presetModel => 'แบบจำลองที่ตั้งไว้ล่วงหน้า';

  @override
  String get customModel => 'แบบจำลองที่กำหนดเอง';

  @override
  String get enterFullModelName =>
      'โปรดป้อนชื่อแบบจำลองที่สมบูรณ์ที่ผู้ให้บริการรองรับ';

  @override
  String get ollamaRunningModels => 'แบบจำลอง Ollama ที่กำลังทำงานอยู่';

  @override
  String get refreshModelList => 'รีเฟรชรายการแบบจำลอง';

  @override
  String get ollamaStartHint =>
      'โปรดเริ่มบริการ Ollama และดาวน์โหลดแบบจำลองก่อน\nจากนั้นคลิกรีเฟรชเพื่อรับรายการแบบจำลอง';

  @override
  String get modelscopeAvailableModels => 'แบบจำลอง ModelScope ที่พร้อมใช้งาน';

  @override
  String get modelscopeApiKeyHint =>
      'โปรดตรวจสอบให้แน่ใจว่าคีย์ API ถูกต้อง\nจากนั้นคลิกรีเฟรชเพื่อรับรายการแบบจำลอง';

  @override
  String get setModelName => 'ตั้งชื่อแบบจำลอง';

  @override
  String get configSummary => 'สรุปการกำหนดค่า';

  @override
  String get providerLabel => 'ผู้ให้บริการ';

  @override
  String get platformLabel => 'แพลตฟอร์ม';

  @override
  String get notSet => 'ไม่ได้ตั้งค่า';

  @override
  String get modelLabel => 'แบบจำลอง';

  @override
  String get customSuffix => '(กำหนดเอง)';

  @override
  String get notSelected => 'ไม่ได้เลือก';

  @override
  String get customModelName => 'ชื่อแบบจำลองที่กำหนดเอง';

  @override
  String enterModelNameHint(Object provider) {
    return 'ป้อนชื่อแบบจำลอง เช่น $provider-Chat';
  }

  @override
  String get modelNameSuggestion => 'ใช้ชื่อที่มีความหมายเพื่อการระบุที่ง่าย';

  @override
  String get testConnectionDesc => 'ทดสอบการเชื่อมต่อและการตอบสนองของแบบจำลอง';

  @override
  String get waitingForResponse => 'กำลังรอการตอบกลับ...';

  @override
  String get configIncomplete => 'การกำหนดค่าไม่สมบูรณ์';

  @override
  String get receivedEmptyResponse => 'ได้รับการตอบกลับว่างเปล่า';

  @override
  String get receivedNoResponse => 'ไม่ได้รับการตอบกลับใดๆ';

  @override
  String connectionFailed(Object error) {
    return 'การเชื่อมต่อล้มเหลว: $error';
  }

  @override
  String get contextCap => 'บริบท';

  @override
  String get thinkingCap => 'การคิด';

  @override
  String get builtinToolsCap => 'เครื่องมือในตัว';

  @override
  String get structuredCap => 'โครงสร้าง';

  @override
  String get batchCap => 'ชุด';

  @override
  String get basicInfo => 'ข้อมูลพื้นฐาน';

  @override
  String get modelParams => 'พารามิเตอร์แบบจำลอง';

  @override
  String get unknown => 'ไม่ทราบ';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String get apiKeyLabel => 'คีย์ API';

  @override
  String get notSetDoubleClickToEdit => 'ไม่ได้ตั้งค่า (ดับเบิลคลิกเพื่อแก้ไข)';

  @override
  String get apiKeySaved => 'บันทึกคีย์ API แล้ว';

  @override
  String get modelNameCannotBeEmpty => 'ชื่อแบบจำลองต้องไม่เว้นว่าง';

  @override
  String get modelNameSaved => 'บันทึกชื่อแบบจำลองแล้ว';

  @override
  String get modelSaved => 'บันทึกแบบจำลองแล้ว';

  @override
  String get temperatureLabel => 'อุณหภูมิ (Temperature)';

  @override
  String get precise => 'แม่นยำ';

  @override
  String get neutral => 'เป็นกลาง';

  @override
  String get creative => 'สร้างสรรค์';

  @override
  String get temperatureDescription =>
      'ควบคุมความสุ่มและความคิดสร้างสรรค์ในการตอบกลับ ค่าต่ำจะอนุรักษ์นิยมมากขึ้น ค่าสูงจะสร้างสรรค์มากขึ้น';

  @override
  String get modelRoleSetting => 'การตั้งค่าบทบาทของแบบจำลอง';

  @override
  String get presetRole => 'บทบาทที่ตั้งไว้ล่วงหน้า';

  @override
  String get roleSettingDescription =>
      'การตั้งค่าบทบาทจะถูกส่งไปยังแบบจำลองเมื่อเริ่มการสนทนาแต่ละครั้ง เพื่อกำหนดบทบาทและพฤติกรรม สามารถปรับเปลี่ยนตามบทบาทที่คุณต้องการให้แบบจำลองแสดง';

  @override
  String get selectPresetRole => 'เลือกบทบาทที่ตั้งไว้ล่วงหน้า';

  @override
  String get generalAssistant => 'ผู้ช่วยทั่วไป';

  @override
  String get friendlyAssistantDesc => 'ผู้ช่วย AI ที่เป็นมิตรและมืออาชีพ';

  @override
  String get spellCheck => 'ตรวจสอบการสะกด';

  @override
  String get spellCheckDesc => 'ผู้เชี่ยวชาญด้านการตรวจสอบการสะกด';

  @override
  String get codeExpert => 'ผู้เชี่ยวชาญด้านโค้ด';

  @override
  String get codeExpertDesc =>
      'ผู้เชี่ยวชาญด้านเทคนิคในการเขียนโปรแกรมและการพัฒนา';

  @override
  String get legalExpert => 'ผู้เชี่ยวชาญด้านกฎหมาย';

  @override
  String get legalExpertDesc => 'ที่ปรึกษากฎหมายมืออาชีพ';

  @override
  String get copywriter => 'นักเขียน文案';

  @override
  String get copywriterDesc =>
      'ผู้เชี่ยวชาญด้านการเขียน文案สร้างสรรค์และการสร้างเนื้อหา';

  @override
  String get dataAnalyst => 'นักวิเคราะห์ข้อมูล';

  @override
  String get dataAnalystDesc => 'ผู้เชี่ยวชาญด้านการวิเคราะห์ข้อมูลและสถิติ';

  @override
  String get educationTutor => 'ติวเตอร์การศึกษา';

  @override
  String get educationTutorDesc => 'ผู้เชี่ยวชาญด้านการสอนที่อดทน';

  @override
  String get businessConsultant => 'ที่ปรึกษาทางธุรกิจ';

  @override
  String get businessConsultantDesc =>
      'ผู้เชี่ยวชาญด้านการจัดการธุรกิจและกลยุทธ์';

  @override
  String get psychologist => 'นักจิตวิทยา';

  @override
  String get psychologistDesc => 'ที่ปรึกษาสุขภาพจิตมืออาชีพ';

  @override
  String get versionLabel => 'รุ่น';

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
  String get domainAddress => 'Service Address';

  @override
  String get domainHint => 'e.g. api.example.com';

  @override
  String get domainDesc =>
      'After setting, the session service URL will use this address. HTTP default port 80, HTTPS default port 443.';

  @override
  String get portSettings => 'การตั้งค่าพอร์ต';

  @override
  String get httpPort => 'พอร์ต HTTP';

  @override
  String get httpsPort => 'พอร์ต HTTPS';

  @override
  String get portDesc =>
      'พอร์ตรับฟัง HTTP ค่าเริ่มต้น 80. พอร์ตรับฟัง HTTPS ค่าเริ่มต้น 443. รีสตาร์ทบริการเพื่อนำไปใช้';

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
  String get loadingPageSubtitle => 'พื้นที่ทำงาน AI องค์กรอัจฉริยะ';

  @override
  String get billingSettings => 'การเรียกเก็บเงิน';

  @override
  String get mcpSettings => 'การตั้งค่า MCP';

  @override
  String get currencyTypeLabel => 'ประเภทสกุลเงิน';

  @override
  String get inputPriceLabel => 'ราคาอินพุต';

  @override
  String get outputPriceLabel => 'ราคาอาท์พุต';

  @override
  String pricePerMillionTokens(Object unit) {
    return '$unit/ล้านโทเค็น';
  }

  @override
  String priceUnitDescription(Object unit) {
    return 'ราคา: $unit/ล้านโทเค็น ใช้สำหรับคำนวณต้นทุนเซสชันสะสม';
  }

  @override
  String get examplePriceHint => 'เช่น 0.14';

  @override
  String get mcpBindingDescription =>
      'หลังจากผูกบริการ MCP เข้ากับโมเดล เซสชันที่ใช้โมเดลนี้จะฉีดเครื่องมือ MCP เหล่านี้โดยอัตโนมัติ เซสชัน MCP และโมเดล MCP จะถูกรวมและลบรายการซ้ำโดยอัตโนมัติ';

  @override
  String get addMcpServiceButton => 'เพิ่มบริการ MCP';

  @override
  String get clearAllMcpBindings => 'ลบการผูก MCP ทั้งหมด';

  @override
  String get selectMcpServiceMultiSelect => 'เลือกบริการ MCP (เลือกหลายรายการ)';

  @override
  String get noMcpServiceAddFirst =>
      'ไม่มีบริการ MCP กรุณาเพิ่มในการจัดการ MCP ก่อน';

  @override
  String confirmWithCount(Object count) {
    return 'ตกลง ($count)';
  }

  @override
  String get temperaturePrecise => 'แม่นยำ';

  @override
  String get temperatureConservative => 'อนุรักษ์นิยม';

  @override
  String get temperatureNeutral => 'เป็นกลาง';

  @override
  String get temperatureCreative => 'สร้างสรรค์';

  @override
  String get temperatureRandom => 'สุ่ม';

  @override
  String xToolsCount(Object n) {
    return '$n เครื่องมือ';
  }

  @override
  String get newConversationDefault => 'การสนทนาใหม่';

  @override
  String get usageDashboard => 'แดชบอร์ดการใช้งาน';

  @override
  String get globalUsageDashboard => 'แดชบอร์ดการใช้งานทั่วทั้งระบบ';

  @override
  String sessionUsageTitle(Object name) {
    return '$name การใช้งาน';
  }

  @override
  String get noSessionData => 'ไม่มีข้อมูลเซสชัน';

  @override
  String get noUsageData => 'ไม่มีข้อมูลการใช้งาน';

  @override
  String get overview => 'ภาพรวม';

  @override
  String get statMessages => 'ข้อความ';

  @override
  String get totalMessages => 'ข้อความทั้งหมด';

  @override
  String get inputTokens => 'โทเค็นนำเข้า';

  @override
  String get outputTokens => 'โทเค็นส่งออก';

  @override
  String get totalCostLabel => 'ค่าใช้จ่ายทั้งหมด';

  @override
  String get tokenDistribution => 'การกระจายโทเค็น';

  @override
  String get modelInfo => 'ข้อมูลโมเดล';

  @override
  String get quotaLimitSection => 'ขีดจำกัดโควตา';

  @override
  String get usageCurve => 'เส้นโค้งการใช้งาน';

  @override
  String get totalSessions => 'เซสชันทั้งหมด';

  @override
  String get totalTokens => 'โทเค็นทั้งหมด';

  @override
  String get byModel => 'ตามโมเดล';

  @override
  String get allSessions => 'ทุกเซสชัน';

  @override
  String moreSessionsNoData(Object count) {
    return 'เซสชันอื่นๆ อีก $count รายการไม่มีข้อมูลการใช้งาน';
  }

  @override
  String get inputLabel => 'นำเข้า';

  @override
  String get outputLabel => 'ส่งออก';

  @override
  String get noQuotaLimit => 'ไม่ได้ตั้งค่าขีดจำกัดโควตา';

  @override
  String sessionsCountSuffix(Object count) {
    return '$count เซสชัน';
  }

  @override
  String get granMinute => 'นาที';

  @override
  String get granHour => 'ชั่วโมง';

  @override
  String get granDay => 'วัน';

  @override
  String get granMonth => 'เดือน';

  @override
  String get granYear => 'ปี';

  @override
  String get selectDate => 'เลือกวันที่';

  @override
  String get rangeStart => 'เริ่ม';

  @override
  String get rangeEnd => 'สิ้นสุด';

  @override
  String get startDateHelp => 'วันที่เริ่ม';

  @override
  String get endDateHelp => 'วันที่สิ้นสุด';

  @override
  String get tokenToggle => 'Token';

  @override
  String get costToggle => 'ค่าใช้จ่าย';

  @override
  String chartLegendCost(Object symbol) {
    return 'ค่าใช้จ่าย ($symbol)';
  }

  @override
  String get noSessionConfig => 'ไม่มีการตั้งค่าเซสชัน';

  @override
  String get resetApiKey => 'รีเซ็ตคีย์ API';

  @override
  String get resetApiKeyConfirm =>
      'รีเซ็ตคีย์ API ของเซสชันนี้หรือไม่? หลังจากรีเซ็ต คีย์เดิมจะใช้ไม่ได้ทันที และคำขอภายนอกที่ใช้คีย์เดิมจะไม่สามารถเข้าถึงได้';

  @override
  String get confirmReset => 'ยืนยันการรีเซ็ต';

  @override
  String get connectorSkillRelation =>
      'คำอธิบายความสัมพันธ์ระหว่างตัวเชื่อมต่อและทักษะ';

  @override
  String modelPricing(Object unit) {
    return 'ราคาโมเดล ($unit/ล้านโทเค็น)';
  }

  @override
  String get billingInfoLabel => 'ข้อมูลการเรียกเก็บเงิน';

  @override
  String get cumulativeInputTokens => 'โทเค็นนำเข้าสะสม';

  @override
  String get cumulativeOutputTokens => 'โทเค็นส่งออกสะสม';

  @override
  String get cumulativeCost => 'ค่าใช้จ่ายสะสม';

  @override
  String get basicInfoLabel => 'ข้อมูลพื้นฐาน';

  @override
  String get sessionName => 'ชื่อเซสชัน';

  @override
  String get organization => 'องค์กร';

  @override
  String get groupLabel => 'กลุ่ม';

  @override
  String get notSpecified => 'ไม่ระบุ';

  @override
  String get notGrouped => 'ไม่ได้จัดกลุ่ม';

  @override
  String get boundModel => 'โมเดลที่ผูกไว้';

  @override
  String get relatedPrompt => 'พรอมต์ที่เกี่ยวข้อง';

  @override
  String get messageCountLabel => 'จำนวนข้อความ';

  @override
  String get serviceConfigLabel => 'การตั้งค่าบริการ';

  @override
  String get serviceAddress => 'ที่อยู่บริการ';

  @override
  String get mcpLabel => 'MCP';

  @override
  String get modelMcp => 'โมเดล MCP';

  @override
  String get sessionMcp => 'เซสชัน MCP';

  @override
  String get notBound => 'ไม่ได้ผูก';

  @override
  String get addMcpHint =>
      'คุณสามารถเพิ่มบริการ MCP ในการจัดการโมเดลหรือช่องป้อนข้อความแชท';

  @override
  String get usageQuotaLabel => 'โควตาการใช้งาน';

  @override
  String get noAuthAccess => 'เข้าถึงโดยไม่ต้องรับรอง';

  @override
  String get noAuthEnabledDesc => '⚠️ ปิดการรับรองแล้ว ทุกคนสามารถเข้าถึงได้';

  @override
  String get noAuthDisabledDesc =>
      'เปิดใช้งาน: เข้าถึงได้โดยไม่ต้องใช้คีย์ API';

  @override
  String get disableSession => 'ปิดใช้งานเซสชัน';

  @override
  String get disabledEnabledDesc =>
      '⚠️ ปิดใช้งานแล้ว การเรียกจะส่งคืนข้อผิดพลาด';

  @override
  String get disabledDisabledDesc =>
      'เปิดใช้งาน: เซสชันนี้จะไม่สามารถถูกเรียกได้';

  @override
  String get systemPromptHint =>
      'กำหนดบทบาท/พฤติกรรมสำหรับเซสชันนี้ เช่น คุณคือที่ปรึกษากฎหมายมืออาชีพ...';

  @override
  String get systemPromptDesc =>
      'จะถูกตั้งเป็นคำสั่งลำดับความสำคัญสูงสุด และถูกแทรกอัตโนมัติสำหรับคำขอของบุคคลที่สาม ปล่อยว่างหากไม่ต้องการแทรก';

  @override
  String get tokenUsageLimit => 'ขีดจำกัดการใช้งานโทเค็น';

  @override
  String costBudgetLimit(Object unit) {
    return 'งบประมาณค่าใช้จ่าย ($unit)';
  }

  @override
  String get requestLimit => 'ขีดจำกัดจำนวนคำขอ';

  @override
  String get noLimit => 'ไม่จำกัด';

  @override
  String get enableUsageLimit => 'เปิดใช้งานขีดจำกัดการใช้งาน';

  @override
  String get reachLimitReject => 'คำขอใหม่จะถูกปฏิเสธเมื่อถึงขีดจำกัด';

  @override
  String get resetPeriod => 'รอบระยะเวลารีเซ็ต';

  @override
  String get resetPeriodNever => 'ไม่รีเซ็ตอัตโนมัติ';

  @override
  String get resetPeriodDaily => 'รีเซ็ตทุกวัน';

  @override
  String get resetPeriodMonthly => 'รีเซ็ตทุกเดือน';

  @override
  String get quotaExhausted => 'โควตาหมดแล้ว';

  @override
  String get currentUsageStatus => 'สถานะการใช้งานปัจจุบัน';

  @override
  String get quotaTokenLabel => 'Token';

  @override
  String get quotaCostLabel => 'ค่าใช้จ่าย';

  @override
  String get quotaRequestLabel => 'คำขอ';

  @override
  String get manualResetUsage => 'รีเซ็ตการใช้งานด้วยตนเอง';

  @override
  String get manualResetConfirmDesc => 'ยืนยันการรีเซ็ตด้วยตนเอง';

  @override
  String get manualResetWarning =>
      'หลังจากรีเซ็ต โทเค็น ค่าใช้จ่าย และจำนวนคำขอในรอบปัจจุบันจะถูกล้าง และเวลาเริ่มรอบจะอัปเดตเป็นเวลาปัจจุบัน';

  @override
  String get tokenUsage => 'การใช้งานโทเค็น';

  @override
  String get costUsage => 'การใช้งานค่าใช้จ่าย';

  @override
  String get resetValue => 'รีเซ็ต';

  @override
  String get apiKeyReset => 'รีเซ็ตคีย์ API แล้ว';

  @override
  String get securitySettings => 'ความปลอดภัย';

  @override
  String get sensitiveInfoMasking => 'การปกปิดข้อมูลที่ละเอียดอ่อน';

  @override
  String get sensitiveInfoMaskingDesc =>
      'เมื่อเปิดใช้งาน ข้อมูลที่เกี่ยวข้องในข้อความที่ส่งถึงโมเดลและในบันทึกการตรวจสอบภายในจะถูกแทนที่ด้วย \'*\' เพื่อป้องกันการรั่วไหลของข้อมูลส่วนบุคคลแบบตัวอักษร';

  @override
  String get maskPhoneTitle => 'ปกปิดเบอร์โทรศัพท์';

  @override
  String get maskPhoneSubtitle => 'แทนที่เบอร์โทรศัพท์ในข้อความด้วย \'*\'';

  @override
  String get maskIdCardTitle => 'ปกปิดเลขบัตรประจำตัวประชาชน';

  @override
  String get maskIdCardSubtitle =>
      'แทนที่เลขบัตรประจำตัวประชาชนในข้อความด้วย \'*\'';

  @override
  String get sessionDetails => 'รายละเอียดเซสชัน';

  @override
  String get modelDetails => 'รายละเอียดโมเดล';

  @override
  String modelDetailsWithPlatform(String platform) {
    return 'รายละเอียดโมเดล · $platform';
  }

  @override
  String get japanese => 'ภาษาญี่ปุ่น';

  @override
  String get japaneseDesc => 'ภาษาญี่ปุ่น';

  @override
  String get korean => 'เกาหลี';

  @override
  String get koreanDesc => 'เกาหลี';

  @override
  String get thai => 'ไทย';

  @override
  String get thaiDesc => 'ไทย';

  @override
  String get vietnamese => 'เวียดนาม';

  @override
  String get vietnameseDesc => 'เวียดนาม';

  @override
  String get french => 'ฝรั่งเศส';

  @override
  String get frenchDesc => 'ฝรั่งเศส';

  @override
  String get german => 'เยอรมัน';

  @override
  String get germanDesc => 'เยอรมัน';
}
