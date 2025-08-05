import 'package:app_api/app_api.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flux Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      home: const Home(),
    );
  }
}

class Home extends GetView<UsersController> {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flux example', style: TextStyle(color: Colors.white54)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Obx(
          () => controller.isGetUser.value
              ? CircularProgressIndicator.adaptive()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: controller.scrollController,
                        itemCount: controller.users.length,
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.network(
                                    controller
                                        .users[index]['picture']['thumbnail'],
                                  ),
                                ),
                              ),
                              title: Text(_getName(controller.users[index])),
                              subtitle: Text(_gender(controller.users[index])),
                              trailing: Text(_phone(controller.users[index])),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => controller.isLoading.value
                          ? CircularProgressIndicator.adaptive()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getName(dynamic user) =>
      "${user['name']['title']} ${user['name']['first']} ${user['name']['last']}";
  String _gender(dynamic user) => "${user['gender']}";
  String _phone(dynamic user) => "${user['phone']}";
}
