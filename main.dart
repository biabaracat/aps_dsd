import 'package:flutter/material.dart';
import 'api_servico.dart';
import 'tela_detalhes.dart';
import 'tela_estatisticas.dart';

const Color kCorPrimaria = Color(0xFF5B4BE1);
void main() {
  runApp(const AppRecomendador());
}

class AppRecomendador extends StatelessWidget {
  const AppRecomendador({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(
      seedColor: kCorPrimaria,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Recomendador de Temas de TCC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: esquema,
        scaffoldBackgroundColor: const Color(0xFFF5F5FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kCorPrimaria, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const TelaBusca(),
    );
  }
}

class TelaBusca extends StatefulWidget {
  const TelaBusca({super.key});

  @override
  State<TelaBusca> createState() => _TelaBuscaState();
}

class _TelaBuscaState extends State<TelaBusca> {
  final _controladorBusca = TextEditingController();

  List<String> _areas = ['Todas'];
  String _areaSelecionada = 'Todas';

  List<Trabalho> _resultados = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAreas();
    _buscar(); // carrega uma lista inicial ao abrir
  }

  Future<void> _carregarAreas() async {
    try {
      final areas = await ApiServico.listarAreas();
      setState(() => _areas = ['Todas', ...areas]);
    } catch (_) {
    }
  }

  Future<void> _buscar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await ApiServico.buscar(
        q: _controladorBusca.text.trim(),
        area: _areaSelecionada,
      );
      setState(() => _resultados = resultados);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar ao servidor.\n'
          'Verifique se o servidor está rodando e se o endereço está correto.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _construirCabecalho(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controladorBusca,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por título',
                      hintText: 'Ex.: gestão',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _areaSelecionada,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Área',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _areas
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _areaSelecionada = v ?? 'Todas'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _buscar,
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!_carregando && _erro == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _resultados.isEmpty
                              ? 'Nenhum trabalho'
                              : '${_resultados.length} trabalho(s) encontrado(s)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  Expanded(child: _construirResultados()),
                ],
              ),
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
          20, MediaQuery.of(context).padding.top + 20, 20, 24),
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
              const Icon(Icons.school_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Temas de TCC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Estatísticas',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TelaEstatisticas(),
                    ),
                  );
                },
                icon: const Icon(Icons.pie_chart_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Busque trabalhos e descubra temas semelhantes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResultados() {
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
              const SizedBox(height: 14),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Nenhum trabalho encontrado.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _resultados.length,
      itemBuilder: (context, i) {
        final t = _resultados[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaDetalhes(trabalho: t),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar com a inicial da área
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: kCorPrimaria.withValues(alpha: 0.12),
                    child: Icon(Icons.description_outlined,
                        color: kCorPrimaria, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _etiqueta(t.area, Icons.category_outlined),
                            if (t.ano > 0)
                              _etiqueta('${t.ano}', Icons.calendar_today_outlined),
                            if (t.fonte.isNotEmpty)
                              _etiqueta(t.fonte, Icons.account_balance_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _etiqueta(String texto, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

