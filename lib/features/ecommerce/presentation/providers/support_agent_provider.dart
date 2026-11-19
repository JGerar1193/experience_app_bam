import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/support_agent_datasource.dart';

final supportAgentDatasourceProvider = Provider<SupportAgentDatasource>((ref) {
  return SupportAgentDatasource(FirebaseFunctions.instance);
});
