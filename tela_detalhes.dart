import 'package:flutter/material.dart';
import 'api_servico.dart';
import 'tela_recomendacoes.dart';
import 'main.dart' show kCorPrimaria;

class TelaDetalhes extends StatelessWidget {
  final Trabalho trabalho;

  const TelaDetalhes({super.key, required this.trabalho});

  @override
  Widget build(BuildContext context) {
    final t = trabalho;
    final temResumo = t.resumo.trim().isNotEmpty;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabecalho(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Etiquetas de metadados (área, ano, fonte)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _etiqueta(t.area, Icons.category_outlined),
                    if (t.ano > 0)
                      _etiqueta('${t.ano}', Icons.calendar_today_outlined),
                    if (t.fonte.isNotEmpty)
                      _etiqueta(t.fonte, Icons.account_balance_outlined),
                  ],
                ),
                const SizedBox(height: 20),

                // Resumo
                Row(
                  children: [
                    Icon(Icons.notes_outlined, size: 18, color: kCorPrimaria),
                    const SizedBox(width: 6),
                    Text(
                      'Resumo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    temResumo
                        ? t.resumo
                        : 'Resumo não disponível para este trabalho.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: temResumo ? Colors.grey.shade800 : Colors.grey,
                      fontStyle: temResumo ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão para ver recomendações
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaRecomendacoes(trabalho: t),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Ver temas semelhantes'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecalho(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 22),
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
                'Detalhes do trabalho',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            trabalho.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kCorPrimaria.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: kCorPrimaria),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: kCorPrimaria,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
