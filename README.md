# Flugx CLI - Flutter API Package Generator

Flugx is a CLI tool that automatically generates a complete Flutter package called `app_api` using GetX, based on a Swagger/OpenAPI specification file.

## Installation

To install Flugx globally from your local directory:

```bash
dart pub global activate flugx_cli
```

## Usage

Generate the `app_api` package using a local or remote Swagger/OpenAPI file:

```bash
# Générer depuis un fichier local
flugx --swagger swagger.json

# Générer depuis une URL
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
import 'package:get/get.dart';
import 'package:app_api/app_api.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: AppBindings(appBaseUrl: 'https://api.example.com'),
      home: MyHomePage(),
    );
  }
}
```

3. Use the generated controllers in your widgets for accessing data and managing state:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_api/app_api.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   final controller = Get.find<UserController>();
    
   return Scaffold(
   appBar: AppBar(title: Text('Users')),
   body: Obx(() {
      if (controller.isLoading.value) {
         return Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
         itemCount: controller.users.length,
         itemBuilder: (context, index) {
         final user = controller.users[index];
         return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
         );
         },
      );
   }),
   );
  }
}