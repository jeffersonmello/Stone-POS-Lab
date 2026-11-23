import 'package:flutter/material.dart';

import 'lab_data.dart';
import 'lab_widgets.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.profiles,
    required this.create,
    required this.openSource,
  });

  final List<PosProfile> profiles;
  final ValueChanged<PosProfile>? create;
  final ValueChanged<String> openSource;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _query = '';
  String? _brand;
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final brands =
        widget.profiles.map((profile) => profile.brand).toSet().toList()
          ..sort();
    final matches = widget.profiles.where((profile) {
      final name = '${profile.brand} ${profile.model}'.toLowerCase();
      return (_brand == null || _brand == profile.brand) &&
          name.contains(_query.toLowerCase().trim());
    }).toList();
    final selected =
        matches.where((profile) => profile.id == _selected).firstOrNull ??
        (_query.isEmpty && _brand == null
            ? matches.where((profile) => profile.model == 'L400').firstOrNull
            : null) ??
        matches.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Catálogo de terminais',
          'Perfis SmartPOS, fichas técnicas e imagens Android para testes.',
          action: FilledButton.icon(
            onPressed: selected == null || widget.create == null
                ? null
                : () => widget.create!(selected),
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Criar emulador'),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LabPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (query) =>
                                    setState(() => _query = query),
                                decoration: const InputDecoration(
                                  hintText: 'Buscar terminal',
                                  prefixIcon: Icon(Icons.search, size: 19),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                borderRadius: BorderRadius.circular(10),
                                value: _brand ?? '',
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('Fabricantes'),
                                  ),
                                  ...brands.map(
                                    (brand) => DropdownMenuItem(
                                      value: brand,
                                      child: Text(brand),
                                    ),
                                  ),
                                ],
                                onChanged: (brand) => setState(
                                  () => _brand = brand == '' ? null : brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _TableHead(),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum terminal encontrado.',
                                  style: TextStyle(color: muted),
                                ),
                              )
                            : ListView.builder(
                                itemCount: matches.length,
                                itemBuilder: (_, index) => _ProfileRow(
                                  profile: matches[index],
                                  selected: selected == matches[index],
                                  onTap: () => setState(
                                    () => _selected = matches[index].id,
                                  ),
                                ),
                              ),
                      ),
                      ColoredBox(
                        color: sidebar,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                          child: Text(
                            '${matches.length} de ${widget.profiles.length} perfis',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 310,
                child: selected == null
                    ? const LabPanel(
                        child: Center(
                          child: Text(
                            'Selecione um terminal',
                            style: TextStyle(color: muted),
                          ),
                        ),
                      )
                    : _ProfileDetail(
                        key: ValueKey(selected.id),
                        profile: selected,
                        openSource: widget.openSource,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: sidebar,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DefaultTextStyle(
        style: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('Terminal')),
            Expanded(flex: 2, child: Text('Android')),
            Expanded(flex: 2, child: Text('Resolução')),
            SizedBox(width: 14),
          ],
        ),
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final PosProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? darkAccent : surface,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 57,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  TerminalIcon(size: 32, selected: selected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.model,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? accent : foreground,
                          ),
                        ),
                        Text(
                          profile.brand,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(profile.android ?? 'Sob consulta')),
            Expanded(
              flex: 2,
              child: Text(
                profile.resolution,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: selected ? accent : muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    super.key,
    required this.profile,
    required this.openSource,
  });

  final PosProfile profile;
  final ValueChanged<String> openSource;

  @override
  Widget build(BuildContext context) => LabPanel(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff253727), surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const TerminalIcon(size: 52, selected: true),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.brand, style: const TextStyle(color: muted)),
                    Text(
                      profile.model,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 12, 19, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ficha técnica',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 7),
              _Fact('Android', profile.android ?? 'Sob consulta'),
              _Fact('Nível de API', profile.api?.toString() ?? 'Sob consulta'),
              _Fact('Resolução', profile.resolution),
              if (profile.dpi case final dpi?)
                _Fact('Densidade Android', '$dpi dpi'),
              ...profile.specs.entries.map(
                (fact) => _Fact(fact.key, fact.value),
              ),
              if (profile.notes.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  profile.notes,
                  style: const TextStyle(
                    color: muted,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('Fontes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final source in profile.sources)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => openSource(source['url']!),
                  icon: const Icon(Icons.open_in_new, size: 13),
                  label: Text(source['title']!),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: muted)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}
