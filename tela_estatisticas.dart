import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'api_servico.dart';
import 'main.dart' show kCorPrimaria;

class TelaEstatisticas extends StatefulWidget {
  const TelaEstatisticas({super.key});

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  Estatisticas? _dados;
  bool _carregando = true;
  String? _erro;

  static const List<Color> _cores = [
    Color(0xFF5B4BE1),
    Color(0xFF8E6BF0),
    Color(0xFF00A3A3),
    Color(0xFFF2A516),
    Color(0xFFE2566E),
    Color(0xFF3FA796),
    Color(0xFF7D5BA6),
    Color(0xFF55A630),
    Color(0xFF9E9E9E),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await ApiServico.estatisticas();
      setState(() => _dados = dados);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar as estatísticas.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Color _corDe(int i) => _cores[i % _cores.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabecalho(context),
          Expanded(child: _construirConteudo()),
        ],
      ),
    );
  }

  Widget _construirCabecalho(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCorPrimaria, Color(0xFF8E6BF0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.pie_chart_outline, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          const Text(
            'Estatísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_erro!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final dados = _dados!;
    if (dados.porArea.isEmpty) {
      return const Center(child: Text('Sem dados para exibir.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Distribuição por grande área',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${dados.total} trabalhos no acervo',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _PizzaPainter(
                valores: dados.porArea.map((e) => e.quantidade).toList(),
                cores: [
                  for (int i = 0; i < dados.porArea.length; i++) _corDe(i),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Legenda com percentuais
        ...List.generate(dados.porArea.length, (i) {
          final item = dados.porArea[i];
          final pct = dados.total > 0
              ? 100 * item.quantidade / dados.total
              : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _corDe(i),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.area,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${item.quantidade}  (${pct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final List<int> valores;
  final List<Color> cores;

  _PizzaPainter({required this.valores, required this.cores});

  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold<int>(0, (soma, v) => soma + v);
    if (total == 0) return;

    final centro = Offset(size.width / 2, size.height / 2);
    final raio = math.min(size.width, size.height) / 2;
    final retangulo = Rect.fromCircle(center: centro, radius: raio);

    double inicio = -math.pi / 2; 
    for (int i = 0; i < valores.length; i++) {
      final varredura = 2 * math.pi * valores[i] / total;
      final tinta = Paint()
        ..style = PaintingStyle.fill
        ..color = cores[i % cores.length];
      canvas.drawArc(retangulo, inicio, varredura, true, tinta);
      inicio += varredura;
    }

    final furo = Paint()..color = Colors.white;
    canvas.drawCircle(centro, raio * 0.55, furo);
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter old) {
    return old.valores != valores || old.cores != cores;
  }
}
