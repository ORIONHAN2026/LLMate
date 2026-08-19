/// Shared keys used in [Request.context] by the local HTTP proxy pipeline.
class HttpContextKeys {
  HttpContextKeys._();

  static const originBody = 'originBody';
  static const session = 'session';
  static const apiKey = 'apiKey';
  static const body = 'body';
  static const clientProvidedTools = 'clientProvidedTools';
  static const promptInsertCount = 'promptInsertCount';
  static const routeDecision = 'routeDecision';
  static const riskControl = 'riskControl';
  static const auditCallback = 'auditCallback';
  static const requestId = 'requestId';
  static const userMessage = 'userMessage';
  static const streamComplete = 'streamComplete';
}
