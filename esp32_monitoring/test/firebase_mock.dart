import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

Future<void> setupFirebaseCoreMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = kMockFirebasePlatform;
}

// Setup Firebase mocks for testing
Future<void> setupFirebaseMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase Core
  FirebasePlatform.instance = kMockFirebasePlatform;

  // Initialize Firebase with mock
  await Firebase.initializeApp();
}

class MockFirebasePlatform extends Mock implements FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return [MockFirebaseApp()];
  }
}

class MockFirebaseApp extends Mock implements FirebaseAppPlatform {
  @override
  String get name => defaultFirebaseAppName;

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      );
}

final kMockFirebasePlatform = MockFirebasePlatform();
