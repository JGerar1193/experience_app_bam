import 'package:cloud_functions/cloud_functions.dart';

/// Envía una pregunta al agente de soporte (`support_agent`) sobre los pedidos del usuario.
class SupportAgentDatasource {
  final FirebaseFunctions _functions;

  SupportAgentDatasource(this._functions);

  Future<String> ask(String message) async {
    final callable = _functions.httpsCallable('support_agent');

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
      });
      return result.data['answer'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'El asistente no está disponible.');
    }
  }
}
