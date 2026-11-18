// Escolhe a implementação conforme a plataforma: onde existe dart:ffi
// (mobile/desktop) usa a versão real; na web, a versão vazia.
export 'sqflite_inicializacao_web.dart'
    if (dart.library.ffi) 'sqflite_inicializacao_ffi.dart';
