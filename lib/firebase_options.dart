import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class FirebaseOptionsGenerator {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDY3bgpSLSyU2QO5-yOgZa2mk-Mokdx4y8',
        appId: '1:348357608005:web:6bf3b0851281bf66ea592c',
        messagingSenderId: '348357608005',
        projectId: 'kahoot-test-b25d4',
        storageBucket: 'kahoot-test-b25d4.firebasestorage.app',
        authDomain: 'kahoot-test-b25d4.firebaseapp.com',
        measurementId: 'G-2MZTXDEYG7',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDY3bgpSLSyU2QO5-yOgZa2mk-Mokdx4y8',
        appId: '1:348357608005:web:6bf3b0851281bf66ea592c',
        messagingSenderId: '348357608005',
        projectId: 'kahoot-test-b25d4',
        storageBucket: 'kahoot-test-b25d4.firebasestorage.app',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDY3bgpSLSyU2QO5-yOgZa2mk-Mokdx4y8',
        appId: '1:348357608005:web:6bf3b0851281bf66ea592c',
        messagingSenderId: '348357608005',
        projectId: 'kahoot-test-b25d4',
        storageBucket: 'kahoot-test-b25d4.firebasestorage.app',
        iosBundleId: 'com.example.quizzApp',
      );
    }

    return const FirebaseOptions(
      apiKey: 'AIzaSyDY3bgpSLSyU2QO5-yOgZa2mk-Mokdx4y8',
      appId: '1:348357608005:web:6bf3b0851281bf66ea592c',
      messagingSenderId: '348357608005',
      projectId: 'kahoot-test-b25d4',
      storageBucket: 'kahoot-test-b25d4.firebasestorage.app',
    );
  }
}
