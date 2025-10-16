# Flugx CLI - Flutter API Package Generator

Flugx is a highly efficient CLI tool that automatically generates a complete, production-ready Flutter package called `app_api` using GetX state management. It creates a full-layered architecture from OpenAPI/Swagger specifications, including models, APIs, repositories, controllers, and dependency injection bindings.

## Features

- **Complete GetX Architecture**: Generates clean, maintainable code following GetX patterns
- **OpenAPI/Swagger Support**: Processes both local files and remote URLs
- **JSON Serialization**: Auto-generates JSON serialization code using json_annotation
- **Dependency Injection**: Built-in GetX dependency injection with lazy loading
- **Production Ready**: Generates robust error handling and reactive state management
- **Customizable**: Extensible architecture for complex API requirements

## Installation

To install Flugx globally from your local directory:

```bash
dart pub global activate flugx_cli
```

## Usage

Generate the `app_api` package using a local or remote Swagger/OpenAPI file:

```bash
# Generate from a local Swagger file
flugx --swagger swagger.json

# Generate from a remote Swagger URL
flugx --swagger https://api.example.com/swagger.json

```

## Generated Structure

The CLI generates the following structure inside `packages/app_api/` :

```
packages/app_api/
├── lib/
│   ├── app_api.dart                 # Main export file
│   └── src/
│       ├── models/                  # Data models with json_annotation
│       │   ├── models.dart
│       │   ├── user.dart
│       │   └── ...
│       └── data/
│           ├── apis/                # API services using GetConnect
│           │   ├── apis.dart
│           │   ├── user_api.dart
│           │   └── ...
│           ├── repos/               # Repositories to abstract API logic
│           │   ├── repos.dart
│           │   ├── user_repo.dart
│           │   └── ...
│           ├── controllers/         # GetX controllers for state management
│           │   ├── controllers.dart
│           │   ├── user_controller.dart
│           │   └── ...
│           └── bindings/
│               └── app_bindings.dart # Global bindings for dependency injection
├── pubspec.yaml
└── README.md
```

## How to Use in Your Flutter Project

1. Add the generated package as a dependency in your `pubspec.yaml` :

```yaml
dependencies:
  app_api:
    path: packages/app_api
```

2. Set up the initial bindings in your app entry point to configure dependency injection and API base URL:

```dart
import 'package:flutter/material.dart';
import 'package:app_api/app_api.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: AppBindings(),
      home: MyHomePage(),
    );
  }
}
```

## Architecture Overview

The generated package follows a clean, layered architecture:

### 1. API Layer (`apis/`)

Direct HTTP communication using GetConnect. Each service extends `GetConnect` and implements `GetxService` for proper lifecycle management.

### 2. Repository Layer (`repos/`)

Abstracts API logic and provides a clean interface for data operations. Acts as an intermediary between APIs and controllers.

### 3. Controller Layer (`controllers/`)

GetX controllers that manage state and business logic. Includes reactive variables for loading states, errors, and data.

### 4. Model Layer (`models/`)

Data models with JSON serialization support using `json_annotation`. Includes `fromJson` and `toJson` methods.

### 5. Bindings (`bindings/`)

Dependency injection configuration using GetX lazy loading. Ensures proper initialization order and singleton management.

## Error Handling

All generated controllers include comprehensive error handling:
- Network request failures
- Parsing errors
- Loading states management
- Error message propagation

## Advanced Usage

### Custom Base URL Configuration

Pass your API base URL when initializing bindings:

```dart
void main() {
  runApp(GetMaterialApp(
    initialBinding: AppBindings(appBaseUrl: 'https://your-api.com'),
    home: HomePage(),
  ));
}
```

### Reactive State Management

Leverage GetX reactive features:

```dart
class UserController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxList<User> users = <User>[].obs;

  Future<void> fetchUsers() async {
    // Implementation with reactive updates
  }
}
```

### Extending Generated Code

Generated classes are designed to be extensible. Add custom methods, properties, or override existing functionality as needed for your specific requirements.

## Testing

Run tests to ensure the generator works correctly:

```bash
dart test
```

## Contributing

Contributions are welcome! Please ensure code follows Dart best practices and includes tests for new features.

## License

This project is licensed under the same license as specified in the LICENSE file.
