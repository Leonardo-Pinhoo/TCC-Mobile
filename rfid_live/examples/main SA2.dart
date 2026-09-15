import 'package:flutter/material.dart';

void main() {
  runApp(const FinancasApp());
}

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanças Pessoais',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF15151F),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

/// -------------------- MODELO DE DADOS --------------------

class Transacao {
  final String titulo;
  final String data;
  final double valor;
  final bool isReceita;
  final IconData icone;
  final Color corIcone;

  const Transacao({
    required this.titulo,
    required this.data,
    required this.valor,
    required this.isReceita,
    required this.icone,
    required this.corIcone,
  });
}

/// Categorias pré-definidas: cada uma já carrega seu ícone e cor,
/// exatamente como usado nos itens de transação da lista.
class Categoria {
  final String nome;
  final IconData icone;
  final Color cor;

  const Categoria({required this.nome, required this.icone, required this.cor});
}

const List<Categoria> categoriasDisponiveis = [
  Categoria(
    nome: 'Salário',
    icone: Icons.account_balance_wallet_rounded,
    cor: Color(0xFFE8A03D),
  ),
  Categoria(
    nome: 'Aluguel',
    icone: Icons.house_rounded,
    cor: Color(0xFF9B6BF2),
  ),
  Categoria(
    nome: 'Supermercado',
    icone: Icons.shopping_cart_rounded,
    cor: Color(0xFF4CAF7D),
  ),
  Categoria(
    nome: 'Internet',
    icone: Icons.wifi_rounded,
    cor: Color(0xFF4FA8E0),
  ),
  Categoria(
    nome: 'Combustível',
    icone: Icons.local_gas_station_rounded,
    cor: Color(0xFFE0C93F),
  ),
  Categoria(
    nome: 'Restaurante',
    icone: Icons.restaurant_rounded,
    cor: Color(0xFFE0608F),
  ),
  Categoria(
    nome: 'Saúde',
    icone: Icons.favorite_rounded,
    cor: Color(0xFFE0608F),
  ),
  Categoria(
    nome: 'Transporte',
    icone: Icons.directions_car_rounded,
    cor: Color(0xFF4FA8E0),
  ),
  Categoria(
    nome: 'Lazer',
    icone: Icons.sports_esports_rounded,
    cor: Color(0xFF9B6BF2),
  ),
  Categoria(
    nome: 'Outros',
    icone: Icons.more_horiz_rounded,
    cor: Color(0xFF8A8A9A),
  ),
];

/// -------------------- TELA PRINCIPAL --------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceSelecionado = 0;

  // Deixa de ser 'const' pois agora a lista é alterada dinamicamente
  // quando o usuário adiciona novas transações pelo formulário.
  final List<Transacao> transacoes = [
    Transacao(
      titulo: 'Salário',
      data: '05/08/2022',
      valor: 5200.00,
      isReceita: true,
      icone: Icons.account_balance_wallet_rounded,
      corIcone: Color(0xFFE8A03D),
    ),
    Transacao(
      titulo: 'Aluguel',
      data: '05/05/2022',
      valor: 1200.00,
      isReceita: false,
      icone: Icons.house_rounded,
      corIcone: Color(0xFF9B6BF2),
    ),
    Transacao(
      titulo: 'Supermercado',
      data: '07/08/2024',
      valor: 320.50,
      isReceita: false,
      icone: Icons.shopping_cart_rounded,
      corIcone: Color(0xFF4CAF7D),
    ),
    Transacao(
      titulo: 'Internet',
      data: '10/05/2024',
      valor: 99.90,
      isReceita: false,
      icone: Icons.wifi_rounded,
      corIcone: Color(0xFF4FA8E0),
    ),
    Transacao(
      titulo: 'Combustível',
      data: '12/05/2024',
      valor: 200.00,
      isReceita: false,
      icone: Icons.local_gas_station_rounded,
      corIcone: Color(0xFFE0C93F),
    ),
    Transacao(
      titulo: 'Restaurante',
      data: '15/05/2024',
      valor: 150.00,
      isReceita: false,
      icone: Icons.restaurant_rounded,
      corIcone: Color(0xFFE0608F),
    ),
  ];

  double get totalReceitas => transacoes
      .where((t) => t.isReceita)
      .fold(0.0, (soma, t) => soma + t.valor);

  double get totalDespesas => transacoes
      .where((t) => !t.isReceita)
      .fold(0.0, (soma, t) => soma + t.valor);

  double get saldo => totalReceitas - totalDespesas;

  void _abrirFormularioNovaTransacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FormularioTransacao(
          onSalvar: (novaTransacao) {
            setState(() {
              transacoes.insert(0, novaTransacao);
            });
          },
        );
      },
    );
  }

  String formatarMoeda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    String inteiro = partes[0];
    final decimal = partes[1];

    String comSeparador = '';
    int contador = 0;
    for (int i = inteiro.length - 1; i >= 0; i--) {
      comSeparador = inteiro[i] + comSeparador;
      contador++;
      if (contador % 3 == 0 && i != 0) {
        comSeparador = '.$comSeparador';
      }
    }
    return 'R\$ $comSeparador,$decimal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15151F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildResumoCard(),
                    const SizedBox(height: 24),
                    _buildTransacoesHeader(),
                    const SizedBox(height: 12),
                    ...transacoes.map((t) => _buildTransacaoItem(t)),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFE8752D),
          onPressed: _abrirFormularioNovaTransacao,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {},
          ),
          const Text(
            'Finanças',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumo do Mês',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: const [
                  Text(
                    'Maio / 2024',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  titulo: 'Receitas',
                  valor: formatarMoeda(totalReceitas),
                  cor: const Color(0xFF4CD97B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  titulo: 'Despesas',
                  valor: formatarMoeda(totalDespesas),
                  cor: const Color(0xFFE85D5D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF15151F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  formatarMoeda(saldo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15151F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransacoesHeader() {
    return const Text(
      'Transações',
      style: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTransacaoItem(Transacao t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.corIcone.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(t.icone, color: t.corIcone, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  t.data,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatarMoeda(t.valor),
                style: TextStyle(
                  color: t.isReceita
                      ? const Color(0xFF4CD97B)
                      : const Color(0xFFE85D5D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                t.isReceita
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: t.isReceita
                    ? const Color(0xFF4CD97B)
                    : const Color(0xFFE85D5D),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final itens = [
      {'icone': Icons.pie_chart_rounded, 'label': 'Resumo'},
      {'icone': Icons.list_alt_rounded, 'label': 'Transações'},
      {'icone': Icons.category_rounded, 'label': 'Categorias'},
      {'icone': Icons.bar_chart_rounded, 'label': 'Relatórios'},
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(itens.length, (index) {
          final selecionado = _indiceSelecionado == index;
          final cor = selecionado ? const Color(0xFFE8752D) : Colors.white54;
          return GestureDetector(
            onTap: () => setState(() => _indiceSelecionado = index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(itens[index]['icone'] as IconData, color: cor, size: 24),
                const SizedBox(height: 4),
                Text(
                  itens[index]['label'] as String,
                  style: TextStyle(color: cor, fontSize: 11),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// -------------------- FORMULÁRIO DE NOVA TRANSAÇÃO --------------------

class FormularioTransacao extends StatefulWidget {
  final void Function(Transacao) onSalvar;

  const FormularioTransacao({super.key, required this.onSalvar});

  @override
  State<FormularioTransacao> createState() => _FormularioTransacaoState();
}

class _FormularioTransacaoState extends State<FormularioTransacao> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _valorController = TextEditingController();

  bool _isReceita = false; // false = saída (despesa), true = entrada (receita)
  Categoria _categoriaSelecionada = categoriasDisponiveis.first;
  DateTime _dataSelecionada = DateTime.now();

  @override
  void dispose() {
    _tituloController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _selecionarData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE8752D),
              surface: Color(0xFF1E1E2C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (novaData != null) {
      setState(() => _dataSelecionada = novaData);
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final valorTexto = _valorController.text.replaceAll(',', '.');
    final valor = double.tryParse(valorTexto) ?? 0.0;

    final novaTransacao = Transacao(
      titulo: _tituloController.text.trim(),
      data: _formatarData(_dataSelecionada),
      valor: valor,
      isReceita: _isReceita,
      icone: _categoriaSelecionada.icone,
      corIcone: _categoriaSelecionada.cor,
    );

    widget.onSalvar(novaTransacao);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nova Transação',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              // Seletor de tipo: Entrada (receita) ou Saída (despesa)
              Row(
                children: [
                  Expanded(
                    child: _buildBotaoTipo(
                      label: 'Entrada',
                      icone: Icons.arrow_upward_rounded,
                      selecionado: _isReceita,
                      cor: const Color(0xFF4CD97B),
                      onTap: () => setState(() => _isReceita = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBotaoTipo(
                      label: 'Saída',
                      icone: Icons.arrow_downward_rounded,
                      selecionado: !_isReceita,
                      cor: const Color(0xFFE85D5D),
                      onTap: () => setState(() => _isReceita = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildLabel('Título'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _tituloController,
                hint: 'Ex: Mercado, Salário, Uber...',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Valor'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _valorController,
                hint: 'Ex: 150,00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe um valor';
                  }
                  final valor = double.tryParse(v.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Data'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selecionarData,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatarData(_dataSelecionada),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Categoria'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categoriasDisponiveis.map((categoria) {
                  final selecionada =
                      categoria.nome == _categoriaSelecionada.nome;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _categoriaSelecionada = categoria),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? categoria.cor.withOpacity(0.22)
                            : const Color(0xFF15151F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selecionada
                              ? categoria.cor
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoria.icone, color: categoria.cor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            categoria.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8752D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Salvar Transação',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF15151F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8752D), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE85D5D), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildBotaoTipo({
    required String label,
    required IconData icone,
    required bool selecionado,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? cor.withOpacity(0.18) : const Color(0xFF15151F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? cor : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: selecionado ? cor : Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selecionado ? cor : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
