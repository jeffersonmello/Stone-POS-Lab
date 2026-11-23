import 'package:flutter/material.dart';

import 'android_runtime.dart';
import 'lab_data.dart';
import 'lab_widgets.dart';

class EmulatorSetup {
  const EmulatorSetup({
    required this.label,
    required this.image,
    this.width,
    this.height,
    this.dpi,
  });

  final String label;
  final String image;
  final int? width;
  final int? height;
  final int? dpi;
}

class CreateDialog extends StatefulWidget {
  const CreateDialog({super.key, required this.profile, required this.runtime});

  final PosProfile profile;
  final AndroidRuntime runtime;

  @override
  State<CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _dpi;

  int? _api;
  List<String> _images = [];
  String? _image;
  String? _error;
  bool _loading = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: '${profile.brand} ${profile.model}');
    _width = TextEditingController(text: profile.width?.toString());
    _height = TextEditingController(text: profile.height?.toString());
    _dpi = TextEditingController(text: profile.dpi?.toString());
    if (profile.api case final api?) _getImages(api);
  }

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _height.dispose();
    _dpi.dispose();
    super.dispose();
  }

  Future<void> _getImages(int api) async {
    setState(() {
      _api = api;
      _loading = true;
      _images = [];
      _image = null;
      _error = null;
    });
    try {
      final images = await widget.runtime.installedImages(api);
      if (!mounted || _api != api) return;
      final preferred = widget.runtime.preferredImage(api);
      setState(() {
        _images = images;
        _image = images.contains(preferred) ? preferred : images.firstOrNull;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _api != api) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _install() async {
    final api = _api!;
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      await widget.runtime.installImage(widget.runtime.preferredImage(api));
      if (mounted) await _getImages(api);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  void _submit() {
    if (_image == null || !_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      EmulatorSetup(
        label: _name.text.trim(),
        image: _image!,
        width: int.tryParse(_width.text),
        height: int.tryParse(_height.text),
        dpi: int.tryParse(_dpi.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apis = {23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36};
    if (widget.profile.api case final api?) apis.add(api);
    return PopScope(
      canPop: !_installing,
      child: AlertDialog(
        title: const Text('Criar emulador'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.profile.brand} ${widget.profile.model}',
                    style: const TextStyle(color: accent),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nome da instância',
                    ),
                    validator: (name) {
                      final length = name?.trim().length ?? 0;
                      return length == 0 || length > 64
                          ? 'Use de 1 a 64 caracteres.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _api,
                    decoration: const InputDecoration(
                      labelText: 'API da imagem Android',
                    ),
                    items: (apis.toList()..sort())
                        .map(
                          (api) => DropdownMenuItem(
                            value: api,
                            child: Text('API $api'),
                          ),
                        )
                        .toList(),
                    onChanged: _installing
                        ? null
                        : (api) {
                            if (api != null) _getImages(api);
                          },
                  ),
                  const SizedBox(height: 12),
                  if (_api != widget.profile.api)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'A API escolhida será usada como configuração de laboratório.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  if (_loading || _installing) ...[
                    const LinearProgressIndicator(),
                    if (_installing) ...[
                      const SizedBox(height: 8),
                      const Text('Baixando imagem do Android SDK…'),
                    ],
                  ] else if (_images.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey(_api),
                      initialValue: _image,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Imagem instalada',
                      ),
                      items: _images
                          .map(
                            (image) => DropdownMenuItem(
                              value: image,
                              child: Text(image.split(';').skip(2).join(' · ')),
                            ),
                          )
                          .toList(),
                      onChanged: (image) => setState(() => _image = image),
                    )
                  else if (_api != null)
                    OutlinedButton.icon(
                      onPressed: _install,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Baixar imagem AOSP'),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _dimension(
                          _width,
                          'Largura (px)',
                          160,
                          4096,
                          paired: _height,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dimension(
                          _height,
                          'Altura (px)',
                          160,
                          4096,
                          paired: _width,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _dimension(_dpi, 'Densidade', 80, 640)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Campos de tela vazios usam os padrões da imagem.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _installing ? null : () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: _image == null || _loading || _installing
                ? null
                : _submit,
            child: const Text('Criar instância'),
          ),
        ],
      ),
    );
  }

  Widget _dimension(
    TextEditingController controller,
    String label,
    int min,
    int max, {
    TextEditingController? paired,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.number,
    validator: (text) {
      if (text == null || text.isEmpty) {
        return paired != null && paired.text.isNotEmpty
            ? 'Preencha ambos'
            : null;
      }
      final value = int.tryParse(text);
      return value == null || value < min || value > max ? '$min a $max' : null;
    },
  );
}
