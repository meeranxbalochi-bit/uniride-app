import 'package:firebase_core/firebase_core.dart';

/// Manual Firebase configuration for UniRide.
///
/// This project uses a custom Firestore Database ID, which means
/// we cannot use the default `FirebaseFirestore.instance`. Instead,
/// all Firestore access must go through `FirestoreService.db`.
class DefaultFirebaseOptions {

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnUBWuaLAQJFejEwwepRmofFG_wxvtcfM',
    appId: '1:757229807744:android:50e4c56015c1beb87a5e65',
    messagingSenderId: '757229807744',
    projectId: 'gen-lang-client-0559318477',
    storageBucket: 'gen-lang-client-0559318477.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7trqLJr5z5grl0wXDP1qD79P3e2jXUus',
    appId: '1:757229807744:ios:f0dc45fc7ee187ff7a5e65',
    messagingSenderId: '757229807744',
    projectId: 'gen-lang-client-0559318477',
    storageBucket: 'gen-lang-client-0559318477.firebasestorage.app',
    iosClientId: '757229807744-8dkud1e810hehl59kctvqst0kv8v6uon.apps.googleusercontent.com',
    iosBundleId: 'com.university.unirideApp',
  );
  static FirebaseOptions get currentPlatform {
    // For now, return Android options. Platform detection can be added later.
    return android;
  }
}
