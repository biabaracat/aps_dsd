import 'dart:convert';
import 'package:http/http.dart' as http;

class Trabalho {
  final String id;
  final String titulo;
  final String resumo;
  final String area;
  final int ano;
  final String fonte;

  Trabalho({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.area,
    required this.ano,
    required this.fonte,
  });

  factory Trabalho.fromJson(Map<String, dynamic> json) {
    return Trabalho(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      resumo: json['resumo'] ?? '',
      area: json['area'] ?? '',
      ano: json['ano'] ?? 0,
      fonte: json['fonte'] ?? '',
    );
  }
}

class Recomendacao {
  final String titulo;
  final String area;
  final int ano;
  final double score;
  final String fonte;

  Recomendacao({
    required this.titulo,
    required this.area,
    required this.ano,
    required this.score,
    required this.fonte,
  });

  factory Recomendacao.fromJson(Map<String, dynamic> json) {
    return Recomendacao(
      titulo: json['titulo'] ?? '',
      area: json['area'] ?? '',
      ano: json['ano'] ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      fonte: json['fonte'] ?? '',
    );
  }
}

class AreaContagem {
  final String area;
  final int quantidade;

  AreaContagem({required this.area, required this.quantidade});

  factory AreaContagem.fromJson(Map<String, dynamic> json) {
    return AreaContagem(
      area: json['area'] ?? 'Outras',
      quantidade: json['quantidade'] ?? 0,
    );
  }
}

class Estatisticas {
  final int total;
  final List<AreaContagem> porArea;

  Estatisticas({required this.total, required this.porArea});

  factory Estatisticas.fromJson(Map<String, dynamic> json) {
    final lista = (json['por_area'] as List? ?? [])
        .map((e) => AreaContagem.fromJson(e))
        .toList();
    return Estatisticas(total: json['total'] ?? 0, porArea: lista);
  }
}

class ApiServico {
  static const String baseUrl = 'http://10.156.48.135:8000';

  static Future<List<Trabalho>> buscar({String q = '', String area = ''}) async {
    final params = <String, String>{'q': q, 'limite': '30'};
    if (area.isNotEmpty && area != 'Todas') {
      params['area'] = area;
    }
    final uri = Uri.parse('$baseUrl/buscar').replace(queryParameters: params);

    final resposta = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ao buscar (HTTP ${resposta.statusCode})');
    }
    final List dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    return dados.map((e) => Trabalho.fromJson(e)).toList();
  }

  static Future<List<String>> listarAreas() async {
    final uri = Uri.parse('$baseUrl/areas');
    final resposta = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ao listar áreas (HTTP ${resposta.statusCode})');
    }
    final List dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    return dados.map((e) => e.toString()).toList();
  }

  static Future<List<Recomendacao>> recomendar(String id, {int k = 5}) async {
    final uri = Uri.parse('$baseUrl/recomendar')
        .replace(queryParameters: {'id': id, 'k': '$k'});

    final resposta = await http.get(uri).timeout(const Duration(seconds: 20));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ao recomendar (HTTP ${resposta.statusCode})');
    }
    final List dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    return dados.map((e) => Recomendacao.fromJson(e)).toList();
  }

  static Future<Estatisticas> estatisticas() async {
    final uri = Uri.parse('$baseUrl/estatisticas');
    final resposta = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ao obter estatísticas (HTTP ${resposta.statusCode})');
    }
    final Map<String, dynamic> dados =
        jsonDecode(utf8.decode(resposta.bodyBytes));
    return Estatisticas.fromJson(dados);
  }
}
