import 'hint_level.dart';
import 'hint_request.dart';
import 'hint_result.dart';

abstract class HintEngine {
  const HintEngine();

  HintResult generate({required HintRequest request, required HintLevel level});
}
