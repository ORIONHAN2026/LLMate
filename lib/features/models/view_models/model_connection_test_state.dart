class ModelConnectionTestState {
  bool isTesting = false;
  bool completed = false;
  bool passed = false;
  String response = '';

  void start() {
    isTesting = true;
    completed = false;
    passed = false;
    response = '';
  }

  void reset() {
    isTesting = false;
    completed = false;
    passed = false;
    response = '';
  }

  void resetIfCompleted() {
    if (completed) reset();
  }

  void fail(String message) {
    isTesting = false;
    completed = true;
    passed = false;
    response = message;
  }

  void stream(String message) {
    response = message;
    completed = false;
  }

  void finish({
    required bool hasReceived,
    required String accumulatedResponse,
    required String emptyResponseMessage,
    required String noResponseMessage,
  }) {
    isTesting = false;
    completed = true;
    passed = hasReceived && accumulatedResponse.isNotEmpty;
    response =
        hasReceived
            ? accumulatedResponse.isEmpty
                ? emptyResponseMessage
                : accumulatedResponse
            : noResponseMessage;
  }
}
