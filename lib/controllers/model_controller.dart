import 'package:get/get.dart';
import '../models/bigmodel/chat_model.dart';

class ModelController extends GetxController {
  var models = <ChatModel>[].obs;
  var selectedModel = ''.obs;
  var apiUrl = ''.obs;

  void setModels(List<ChatModel> newModels) {
    models.value = newModels;
    if (newModels.isNotEmpty && selectedModel.isEmpty) {
      selectedModel.value = newModels.first.name;
    }
  }

  void setSelectedModel(String modelName) {
    selectedModel.value = modelName;
  }

  void setApiUrl(String url) {
    apiUrl.value = url;
  }
}
