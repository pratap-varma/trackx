import 'package:trackx/features/ai_assistant/domain/models/ai_request.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_response.dart';

abstract class AiProvider {
  Future<AiResponse> generate(AiRequest request);
}
