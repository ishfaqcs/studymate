import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AiAssistantService {
  bool get isEnabled;
}

class DisabledAiAssistantService implements AiAssistantService {
  const DisabledAiAssistantService();
  @override
  bool get isEnabled => false;
}

final aiAssistantServiceProvider =
    Provider<AiAssistantService>((ref) => const DisabledAiAssistantService());
