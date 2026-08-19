import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/models/model_catalog.dart';

void main() {
  group('ModelCatalog', () {
    test('contains mainstream online provider fallback lists', () {
      expect(ModelCatalog.builtinModels['openai'], contains('gpt-5'));
      expect(ModelCatalog.builtinModels['google'], contains('gemini-2.5-pro'));
      expect(ModelCatalog.builtinModels['zhipu'], contains('glm-4.5'));
    });

    test('picks lightweight and capable models from a provider list', () {
      const models = ['gpt-5-mini', 'gpt-5'];

      expect(ModelCatalog.pickLightweight(models), 'gpt-5-mini');
      expect(ModelCatalog.pickCapable(models), 'gpt-5');
    });

    test('builds readable names for catalog-only model ids', () {
      expect(ModelCatalog.displayName('gpt-4.1-mini'), 'GPT-4.1-Mini');
      expect(ModelCatalog.shortDescription('gpt-5-mini'), contains('快速响应'));
    });
  });
}
