import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class PosProfile {
  PosProfile.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      brand = json['brand'] as String,
      model = json['model'] as String,
      android = json['android'] as String?,
      api = json['api'] as int?,
      width = json['width'] as int?,
      height = json['height'] as int?,
      dpi = json['dpi'] as int?,
      specs = Map<String, String>.from(json['specs'] as Map),
      sources = (json['sources'] as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      notes = json['notes'] as String;

  final String id;
  final String brand;
  final String model;
  final String? android;
  final int? api;
  final int? width;
  final int? height;
  final int? dpi;
  final Map<String, String> specs;
  final List<Map<String, String>> sources;
  final String notes;

  String get resolution =>
      width == null || height == null ? 'Sob consulta' : '$width × $height';

  static Future<List<PosProfile>> load() async {
    final data = await rootBundle.loadString('data/catalog.json');
    return (jsonDecode(data) as List)
        .map((entry) => PosProfile.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}

class LabInstance {
  const LabInstance({
    required this.name,
    required this.label,
    required this.profileId,
    required this.image,
  });

  LabInstance.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      label = json['label'] as String,
      profileId = json['profileId'] as String,
      image = json['image'] as String;

  final String name;
  final String label;
  final String profileId;
  final String image;

  String get apiLabel => image.split(';')[1].replaceFirst('android-', 'API ');

  Map<String, String> toJson() => {
    'name': name,
    'label': label,
    'profileId': profileId,
    'image': image,
  };
}

class LabGuide {
  const LabGuide(this.id, this.title, this.description, {this.source});

  final String id;
  final String title;
  final String description;
  final String? source;

  static const all = [
    LabGuide(
      'overview',
      'Primeiros passos',
      'SDK Android, imagens e instâncias',
    ),
    LabGuide(
      'stone',
      'Integração Stone',
      'Ativação, assinatura, SDK e deeplink',
    ),
    LabGuide(
      'cenarios',
      'Cenários de compatibilidade',
      'Instalação, inicialização e regressões por modelo',
    ),
    LabGuide('market', 'Pesquisa de mercado', 'Emuladores e alternativas'),
    LabGuide(
      'devices',
      'Modelos suportados',
      'Referência oficial Stone',
      source:
          'https://sdkandroid.stone.com.br/reference/dispositivos-suportados',
    ),
    LabGuide(
      'sandbox',
      'Sandbox e ambientes',
      'Referência oficial Stone',
      source:
          'https://sdkandroid.stone.com.br/reference/configurando-ambientes',
    ),
    LabGuide(
      'initialization',
      'Inicialização do SDK',
      'Referência oficial Stone',
      source: 'https://sdkandroid.stone.com.br/reference/inicializando-o-sdk',
    ),
    LabGuide(
      'deeplink',
      'Configuração do deeplink',
      'Referência oficial Stone',
      source: 'https://sdkandroid.stone.com.br/reference/configuracao-deeplink',
    ),
  ];
}

class LabStorage {
  LabStorage()
    : folder = Directory(
        '${Platform.environment['HOME'] ?? Directory.systemTemp.path}'
        '/Library/Application Support/Stone POS Lab',
      );

  final Directory folder;

  File get _instances => File('${folder.path}/instances.json');
  File _guide(LabGuide guide) => File('${folder.path}/${guide.id}.md');

  Future<List<LabInstance>> loadInstances() async {
    if (!await _instances.exists()) return [];
    final data = jsonDecode(await _instances.readAsString()) as List;
    return data
        .map((entry) => LabInstance.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveInstances(List<LabInstance> instances) =>
      _replace(_instances, jsonEncode(instances));

  Future<String> readGuide(LabGuide guide) async {
    if (guide.source == null) {
      return rootBundle.loadString('data/guides/${guide.id}.md');
    }
    final local = _guide(guide);
    if (!await local.exists()) {
      return '# ${guide.title}\n\nUse **Sincronizar fontes** para baixar esta página. '
          'A cópia ficará disponível neste programa para leitura offline.';
    }
    return (await local.readAsString()).replaceFirst(
      RegExp(r'^---\r?\n[\s\S]*?\r?\n---\s*'),
      '',
    );
  }

  Future<int> syncGuides() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    var changed = 0;
    final failures = <String>[];
    try {
      for (final guide in LabGuide.all.where((guide) => guide.source != null)) {
        try {
          final uri = Uri.parse('${guide.source}.md');
          final request = await client.getUrl(uri);
          request.followRedirects = false;
          final response = await request.close().timeout(
            const Duration(seconds: 20),
          );
          final type = response.headers.contentType?.mimeType;
          if (response.statusCode != 200 ||
              (type != 'text/markdown' && type != 'text/plain')) {
            await response.drain<void>().timeout(const Duration(seconds: 5));
            throw const FormatException('Resposta inválida');
          }
          final body = await utf8.decoder
              .bind(response)
              .join()
              .timeout(const Duration(seconds: 20));
          if (body.trim().isEmpty) throw const FormatException('Página vazia');
          final copy = _guide(guide);
          if (await copy.exists() && await copy.readAsString() == body) {
            continue;
          }
          await _replace(copy, body);
          changed++;
        } catch (_) {
          failures.add(guide.title);
        }
      }
    } finally {
      client.close(force: true);
    }
    if (failures.isNotEmpty) {
      throw StateError(
        '$changed página(s) atualizada(s). Falha ao baixar ${failures.join(', ')}.',
      );
    }
    return changed;
  }

  Future<void> _replace(File destination, String content) async {
    await folder.create(recursive: true);
    final temporary = await folder.createTemp('write-');
    try {
      final file = File('${temporary.path}/content');
      await file.writeAsString(content, flush: true);
      await file.rename(destination.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
