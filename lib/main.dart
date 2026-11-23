import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'android_runtime.dart';
import 'catalog_page.dart';
import 'create_dialog.dart';
import 'lab_data.dart';
import 'lab_widgets.dart';

void main() {
  runApp(const StonePosLab());
}

class StonePosLab extends StatelessWidget {
  const StonePosLab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ).copyWith(primary: accent, onPrimary: background, surface: surface),
      scaffoldBackgroundColor: background,
      dividerColor: border,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: border),
        ),
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stone POS Lab',
      theme: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          headlineMedium: const TextStyle(
            color: foreground,
            fontSize: 29,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          headlineSmall: const TextStyle(
            color: foreground,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: const TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const _LabHome(),
    );
  }
}

enum _Page {
  catalog('Catálogo de terminais', Icons.grid_view_rounded),
  instances('Minhas instâncias', Icons.developer_board_outlined),
  guides('Documentação', Icons.menu_book_outlined);

  const _Page(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _LabHome extends StatefulWidget {
  const _LabHome();

  @override
  State<_LabHome> createState() => _LabHomeState();
}

class _LabHomeState extends State<_LabHome> {
  final _storage = LabStorage();
  _Page _page = _Page.catalog;
  List<PosProfile> _profiles = [];
  List<LabInstance> _instances = [];
  Set<String> _running = {};
  Set<String> _available = {};
  AndroidRuntime? _runtime;
  Timer? _timer;
  bool _refreshing = false;
  bool _loading = true;
  bool _busy = false;
  bool _syncing = false;
  var _guideVersion = 0;
  String? _loadError;
  String? _runtimeError;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (profiles, instances, runtime) = await (
        PosProfile.load(),
        _storage.loadInstances(),
        AndroidRuntime.discover(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _instances = instances;
        _runtime = runtime;
      });
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    final runtime = _runtime;
    if (runtime == null || _refreshing) return;
    _refreshing = true;
    try {
      final (running, available) = await (
        _instances.isEmpty ? Future.value(<String>{}) : runtime.running(),
        _instances.isEmpty ? Future.value(<String>{}) : runtime.availableAvds(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _running = running;
        _available = available;
        _runtimeError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _runtimeError = '$error');
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _locateSdk() async {
    try {
      final runtime = await AndroidRuntime.discover();
      if (!mounted) return;
      setState(() => _runtime = runtime);
      await _refresh();
      if (runtime == null) {
        await _error(
          'SDK Android',
          'Instale o Android Emulator, Android SDK Platform-Tools e Android SDK '
              'Command-line Tools pelo Android Studio. Depois tente localizar novamente.',
        );
      }
    } catch (error) {
      await _error('SDK Android', error);
    }
  }

  Future<void> _create(PosProfile profile) async {
    final runtime = _runtime;
    if (runtime == null || _busy) return;
    final setup = await showDialog<EmulatorSetup>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateDialog(profile: profile, runtime: runtime),
    );
    if (setup == null || !mounted) return;
    final slug = profile.id.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final name = 'poslab_${slug}_${DateTime.now().microsecondsSinceEpoch}';
    final instance = LabInstance(
      name: name,
      label: setup.label,
      profileId: profile.id,
      image: setup.image,
    );
    await _manage('Criar instância', () async {
      await runtime.create(
        name: name,
        image: setup.image,
        width: setup.width,
        height: setup.height,
        dpi: setup.dpi,
      );
      final updated = [..._instances, instance];
      try {
        await _storage.saveInstances(updated);
      } catch (error) {
        await runtime.delete(name);
        rethrow;
      }
      if (!mounted) return;
      setState(() {
        _instances = updated;
        _available = {..._available, name};
        _page = _Page.instances;
      });
      _message('Instância criada.');
    });
  }

  Future<void> _remove(LabInstance instance) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir instância?'),
        content: Text('Os dados locais de “${instance.label}” serão apagados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _manage('Excluir instância', () async {
      if ((await runtime.availableAvds()).contains(instance.name)) {
        await runtime.delete(instance.name);
      }
      final updated = _instances.where((item) => item != instance).toList();
      await _storage.saveInstances(updated);
      if (!mounted) return;
      setState(() => _instances = updated);
      _message('Instância excluída.');
    });
  }

  Future<void> _manage(String label, Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (error) {
      await _error(label, error);
    } finally {
      await _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final count = await _storage.syncGuides();
      _message(
        count == 0
            ? 'As fontes já estão atualizadas.'
            : '$count página(s) atualizada(s).',
      );
    } catch (error) {
      await _error('Sincronizar fontes', error);
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
          _guideVersion++;
        });
      }
    }
  }

  void _message(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _error(String title, Object error) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText('$error')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('Não foi possível abrir o link.');
      }
    } catch (_) {
      _message('Não foi possível abrir o link.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        _navigation(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 24, 25, 21),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(child: SelectableText(_loadError!))
                : IndexedStack(
                    index: _page.index,
                    children: [
                      CatalogPage(
                        profiles: _profiles,
                        create: _runtime != null && !_busy ? _create : null,
                        openSource: _openSource,
                      ),
                      _instancePage(),
                      _GuidePage(
                        storage: _storage,
                        version: _guideVersion,
                        sync: _syncing ? null : _sync,
                        openSource: _openSource,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _navigation() => Container(
    width: 212,
    decoration: const BoxDecoration(
      color: sidebar,
      border: Border(right: BorderSide(color: border)),
    ),
    padding: const EdgeInsets.fromLTRB(14, 24, 14, 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 0, 30),
          child: Row(
            children: [
              TerminalIcon(size: 37, selected: true),
              SizedBox(width: 9),
              Text(
                'Stone POS Lab',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        for (final page in _Page.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Material(
              color: page == _page ? darkAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _page = page),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        page.icon,
                        color: page == _page ? accent : muted,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        page.label,
                        style: TextStyle(
                          color: page == _page ? accent : muted,
                          fontSize: 13,
                          fontWeight: page == _page
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        LabPanel(
          color: background,
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal, size: 16, color: accent),
                  SizedBox(width: 7),
                  Text(
                    'Android SDK',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _loading
                    ? 'Localizando SDK…'
                    : _runtime == null
                    ? 'SDK não localizado'
                    : _runtimeError == null
                    ? 'Disponível'
                    : 'Falha ao consultar o SDK',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              if (!_loading && _runtime == null)
                TextButton(
                  onPressed: _locateSdk,
                  child: const Text('Localizar SDK'),
                )
              else if (_runtime case final runtime?)
                Tooltip(
                  message: _runtimeError ?? runtime.root,
                  child: const Text(
                    'Ver caminho ao passar o mouse',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _instancePage() => Column(
    children: [
      PageHeading(
        'Minhas instâncias',
        'Abra e gerencie os dispositivos virtuais deste laboratório.',
        action: OutlinedButton.icon(
          onPressed: () => setState(() => _page = _Page.catalog),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Nova instância'),
        ),
      ),
      const SizedBox(height: 24),
      if (_busy) const LinearProgressIndicator(),
      Expanded(
        child: LabPanel(
          child: _instances.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TerminalIcon(size: 55),
                      SizedBox(height: 12),
                      Text(
                        'Nenhuma instância criada',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Escolha um perfil no catálogo para começar.',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _instances.length,
                  separatorBuilder: (_, _) => const Divider(height: 20),
                  itemBuilder: (_, index) => _instanceRow(_instances[index]),
                ),
        ),
      ),
    ],
  );

  Widget _instanceRow(LabInstance instance) {
    final runtime = _runtime;
    final isRunning = _running.contains(instance.name);
    final exists = _available.contains(instance.name) || isRunning;
    final canControl = !_busy && runtime != null && _runtimeError == null;
    final profile = _profiles
        .where((profile) => profile.id == instance.profileId)
        .firstOrNull;
    return Row(
      children: [
        TerminalIcon(selected: isRunning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${profile?.brand ?? ''} ${profile?.model ?? ''} · ${instance.apiLabel}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          !exists
              ? 'Indisponível'
              : isRunning
              ? 'Em execução'
              : 'Parada',
          style: TextStyle(color: isRunning ? accent : muted, fontSize: 12),
        ),
        const SizedBox(width: 14),
        OutlinedButton.icon(
          onPressed: canControl && exists
              ? () => _manage(
                  isRunning ? 'Parar instância' : 'Iniciar instância',
                  () async {
                    if (isRunning) {
                      await runtime.stop(instance.name);
                    } else {
                      await runtime.start(instance.name);
                    }
                  },
                )
              : null,
          icon: Icon(
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(isRunning ? 'Parar' : 'Iniciar'),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Excluir instância',
          onPressed: canControl && !isRunning ? () => _remove(instance) : null,
          icon: const Icon(Icons.delete_outline, size: 19),
        ),
      ],
    );
  }
}

class _GuidePage extends StatefulWidget {
  const _GuidePage({
    required this.storage,
    required this.version,
    required this.sync,
    required this.openSource,
  });

  final LabStorage storage;
  final int version;
  final VoidCallback? sync;
  final ValueChanged<String> openSource;

  @override
  State<_GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<_GuidePage> {
  LabGuide _selected = LabGuide.all.first;
  late Future<String> _text;

  @override
  void initState() {
    super.initState();
    _text = widget.storage.readGuide(_selected);
  }

  @override
  void didUpdateWidget(covariant _GuidePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      _text = widget.storage.readGuide(_selected);
    }
  }

  void _select(LabGuide guide) => setState(() {
    _selected = guide;
    _text = widget.storage.readGuide(guide);
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeading(
        'Documentação',
        'Guias do laboratório e referências técnicas da Stone.',
        action: OutlinedButton.icon(
          onPressed: widget.sync,
          icon: widget.sync == null
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 18),
          label: const Text('Sincronizar fontes'),
        ),
      ),
      const SizedBox(height: 24),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 226,
              child: LabPanel(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final guide in LabGuide.all)
                      ListTile(
                        dense: true,
                        selected: guide == _selected,
                        selectedTileColor: darkAccent,
                        selectedColor: accent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                        ),
                        title: Text(
                          guide.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          guide.description,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        onTap: () => _select(guide),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LabPanel(
                child: FutureBuilder<String>(
                  future: _text,
                  builder: (_, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: SelectableText('${snapshot.error}'));
                    }
                    return Column(
                      children: [
                        if (_selected.source case final source?)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, right: 12),
                              child: TextButton.icon(
                                onPressed: () => widget.openSource(source),
                                icon: const Icon(Icons.open_in_new, size: 13),
                                label: const Text('Abrir original'),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Markdown(
                            key: ValueKey(_selected.id),
                            padding: const EdgeInsets.fromLTRB(25, 19, 25, 24),
                            selectable: true,
                            data: snapshot.data!,
                            imageBuilder: (_, _, _) => const SizedBox.shrink(),
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    height: 1.55,
                                    fontSize: 14,
                                  ),
                                ),
                            onTapLink: (_, href, _) {
                              if (href == null) return;
                              final base = _selected.source;
                              widget.openSource(
                                base == null
                                    ? href
                                    : Uri.parse(base).resolve(href).toString(),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
