import 'package:flutter/material.dart';
import 'api_servico.dart';
import 'main.dart' show kCorPrimaria;

class TelaRecomendacoes extends StatefulWidget {
  final Trabalho trabalho;

  const TelaRecomendacoes({super.key, required this.trabalho});

  @override
  State<TelaRecomendacoes> createState() => _TelaRecomendacoesState();
}

class _TelaRecomendacoesState extends State<TelaRecomendacoes> {
  List<Recomendacao> _recomendacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarRecomendacoes();
  }

  Future<void> _buscarRecomendacoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final recs = await ApiServico.recomendar(widget.trabalho.id, k: 5);
      setState(() => _recomendacoes = recs);
    } catch (e) {
      setState(() => _erro = 'Não foi possível obter recomendações.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabecalho(context),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Temas recomendados',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(child: _construirRecomendacoes()),
        ],
      ),
    );
  }

  Widget _construirCabecalho(BuildContext context) {
    final t = widget.trabalho;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recomendações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_outline,
                        size: 16, color: kCorPrimaria),
                    const SizedBox(width: 6),
                    Text(
                      'TRABALHO DE REFERÊNCIA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: kCorPrimaria,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.area}'
                  '${t.ano > 0 ? ' · ${t.ano}' : ''}'
                  '${t.fonte.isNotEmpty ? ' · ${t.fonte}' : ''}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRecomendacoes() {
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
              Icon(Icons.error_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_erro!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _buscarRecomendacoes,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_recomendacoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Nenhuma recomendação encontrada.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _recomendacoes.length,
      itemBuilder: (context, i) {
        final r = _recomendacoes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kCorPrimaria, Color(0xFF8E6BF0)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.area}'
                        '${r.ano > 0 ? ' · ${r.ano}' : ''}'
                        '${r.fonte.isNotEmpty ? ' · ${r.fonte}' : ''}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Indicador de similaridade (score)
                Column(
                  children: [
                    Text(
                      r.score.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kCorPrimaria,
                      ),
                    ),
                    Text(
                      'score',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
