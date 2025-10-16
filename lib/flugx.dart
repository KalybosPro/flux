// Core Flugx exports
export 'src/code_generators/flugx_structure_generator.dart';
export 'src/code_generators/advanced_structure_generator.dart';
export 'src/flugx_generator.dart';
export 'src/recase.dart';
export 'src/constants.dart';
export 'src/utils.dart';

// Essential features exports (avec gestion des conflits VoidCallback)
export 'src/auth_manager.dart';
export 'src/interceptors.dart';
export 'src/error_handling.dart' hide VoidCallback;
export 'src/offline_sync.dart';
export 'src/pagination.dart' hide VoidCallback;
export 'src/websockets.dart' hide VoidCallback;
export 'src/file_manager.dart';
export 'src/environment_config.dart' hide VoidCallback;
