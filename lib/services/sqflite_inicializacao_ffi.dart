import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// O plugin sqflite só funciona nativamente em Android, iOS e macOS.
/// No Windows e no Linux é preciso usar a implementação via FFI.
void inicializarSqflite() {
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
