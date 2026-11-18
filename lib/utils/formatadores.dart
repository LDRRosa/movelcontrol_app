/// Funções de formatação para exibição e envio de dados.
class Formatadores {
  static String somenteDigitos(String texto) =>
      texto.replaceAll(RegExp(r'\D'), '');

  static String cpf(String valor) {
    final d = somenteDigitos(valor);
    if (d.length != 11) return valor;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.'
        '${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String cnpj(String valor) {
    final d = somenteDigitos(valor);
    if (d.length != 14) return valor;
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
        '${d.substring(8, 12)}-${d.substring(12)}';
  }

  /// A API aceita "12345-678" ou "12345678"; enviamos com hífen.
  static String cep(String valor) {
    final d = somenteDigitos(valor);
    if (d.length != 8) return valor;
    return '${d.substring(0, 5)}-${d.substring(5)}';
  }

  static String moeda(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  /// dd/MM/aaaa
  static String data(DateTime? data) {
    if (data == null) return '--/--/----';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year}';
  }

  /// Converte "12,50" ou "12.50" em double.
  static double? parseDecimal(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));
}
