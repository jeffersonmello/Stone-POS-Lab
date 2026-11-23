import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

class AndroidRuntime {
  AndroidRuntime._(this.root, this._commandTools, this._environment);

  final String root;
  final String _commandTools;
  final Map<String, String> _environment;

  String get _emulator => '$root/emulator/emulator';
  String get _adb => '$root/platform-tools/adb';
  String get _avdManager => '$_commandTools/avdmanager';
  String get _sdkManager => '$_commandTools/sdkmanager';
  String get _avdHome => _environment['ANDROID_AVD_HOME']!;

  static final _namePattern = RegExp(r'^poslab_[a-z0-9_]{1,64}$');
  static final _imagePattern = RegExp(
    r'^system-images;android-([0-9]+);([a-z0-9_]+);(arm64-v8a|x86_64|x86)$',
  );

  static List<String> get _hostAbis => switch (Abi.current()) {
    Abi.macosArm64 || Abi.linuxArm64 => ['arm64-v8a'],
    Abi.macosX64 || Abi.linuxX64 => ['x86_64', 'x86'],
    _ => [],
  };

  static Future<AndroidRuntime?> discover() async {
    final env = Platform.environment;
    final home = env['HOME'];
    if (home == null || _hostAbis.isEmpty) return null;
    const androidStudioJdk =
        '/Applications/Android Studio.app/Contents/jbr/Contents/Home';
    final bundledJava =
        Platform.isMacOS &&
        env['JAVA_HOME'] == null &&
        await File('$androidStudioJdk/bin/java').exists();

    final roots = {
      ?env['ANDROID_HOME'],
      ?env['ANDROID_SDK_ROOT'],
      if (Platform.isMacOS) '$home/Library/Android/sdk',
      if (Platform.isLinux) '$home/Android/Sdk',
    };
    for (final root in roots.where((path) => path.isNotEmpty)) {
      final toolDirectory = Directory('$root/cmdline-tools');
      if (!await toolDirectory.exists() ||
          !await File('$root/emulator/emulator').exists() ||
          !await File('$root/platform-tools/adb').exists()) {
        continue;
      }

      final directories = await toolDirectory
          .list()
          .where((entry) => entry is Directory)
          .map((entry) => entry.path.split('/').last)
          .toList();
      directories.sort(_compareToolReleases);

      for (final release in directories) {
        final bin = '${toolDirectory.path}/$release/bin';
        if (await File('$bin/avdmanager').exists() &&
            await File('$bin/sdkmanager').exists()) {
          final androidHome =
              env['ANDROID_EMULATOR_HOME'] ??
              env['ANDROID_USER_HOME'] ??
              '${env['ANDROID_SDK_HOME'] ?? home}/.android';
          return AndroidRuntime._(root, bin, {
            'ANDROID_HOME': root,
            'ANDROID_SDK_ROOT': root,
            'ANDROID_AVD_HOME': env['ANDROID_AVD_HOME'] ?? '$androidHome/avd',
            if (bundledJava) 'JAVA_HOME': androidStudioJdk,
          });
        }
      }
    }
    return null;
  }

  static int _compareToolReleases(String a, String b) {
    if (a == 'latest') return -1;
    if (b == 'latest') return 1;
    final aMajor = int.tryParse(a.split('.').first) ?? 0;
    final bMajor = int.tryParse(b.split('.').first) ?? 0;
    final majorOrder = bMajor.compareTo(aMajor);
    return majorOrder == 0 ? b.compareTo(a) : majorOrder;
  }

  String preferredImage(int api) =>
      'system-images;android-$api;default;${_hostAbis.first}';

  Future<List<String>> installedImages(int api) async {
    final apiPath = Directory('$root/system-images/android-$api');
    if (!await apiPath.exists()) return [];

    final images = <String>[];
    await for (final tag in apiPath.list()) {
      if (tag is! Directory) continue;
      final tagName = tag.path.split('/').last;
      for (final abi in _hostAbis) {
        final image = 'system-images;android-$api;$tagName;$abi';
        if (_imagePattern.hasMatch(image) &&
            await File('${tag.path}/$abi/system.img').exists() &&
            await File('${tag.path}/$abi/package.xml').exists()) {
          images.add(image);
        }
      }
    }
    images.sort();
    final preferred = preferredImage(api);
    if (images.remove(preferred)) images.insert(0, preferred);
    return images;
  }

  Future<void> installImage(String image) async {
    final api = _imageApi(image);
    if ((await installedImages(api)).contains(image)) return;

    final result = await _run(
      _sdkManager,
      ['--sdk_root=$root', image],
      timeout: const Duration(minutes: 15),
      check: false,
    );
    if (result.exitCode != 0 || !(await installedImages(api)).contains(image)) {
      final output = '${result.stderr}\n${result.stdout}';
      if (output.contains('Accept?') ||
          output.toLowerCase().contains('license not accepted')) {
        throw StateError(
          'Revise os termos da imagem no SDK Manager do Android Studio e '
          'tente novamente após concluir a instalação ou aceitar a licença.',
        );
      }
      throw StateError('Não foi possível instalar $image. ${_summary(output)}');
    }
  }

  Future<Set<String>> availableAvds() async {
    final result = await _run(_emulator, ['-list-avds']);
    return const LineSplitter()
        .convert(result.stdout as String)
        .map((line) => line.trim())
        .where(_namePattern.hasMatch)
        .toSet();
  }

  Future<void> create({
    required String name,
    required String image,
    int? width,
    int? height,
    int? dpi,
  }) async {
    _checkName(name);
    final api = _imageApi(image);
    if (!(await installedImages(api)).contains(image)) {
      throw StateError('Instale a imagem Android antes de criar a instância.');
    }
    final avdPath = '$_avdHome/$name.avd';
    if (await File('$_avdHome/$name.ini').exists() ||
        await FileSystemEntity.type(avdPath, followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw StateError('Já existe uma instância com o nome $name.');
    }

    await Directory(_avdHome).create(recursive: true);
    await _run(_avdManager, [
      'create',
      'avd',
      '-n',
      name,
      '-k',
      image,
      '-p',
      avdPath,
    ], input: 'no\n');

    try {
      final config = File('$avdPath/config.ini');
      final properties = <String, String>{
        'hw.keyboard': 'yes',
        if (width != null) 'hw.lcd.width': '$width',
        if (height != null) 'hw.lcd.height': '$height',
        if (dpi != null) 'hw.lcd.density': '$dpi',
      };
      final lines = const LineSplitter().convert(await config.readAsString());
      lines.removeWhere(
        (line) => properties.containsKey(line.split('=').first),
      );
      lines.addAll(
        properties.entries.map((item) => '${item.key}=${item.value}'),
      );
      await config.writeAsString('${lines.join('\n')}\n', flush: true);
    } on FileSystemException {
      await _run(_avdManager, ['delete', 'avd', '-n', name], check: false);
      rethrow;
    }
  }

  Future<Set<String>> running() async => (await _serialsByAvd()).keys.toSet();

  Future<Map<String, String>> _serialsByAvd() async {
    final result = await _run(_adb, ['devices']);
    final matches = RegExp(
      r'^emulator-[0-9]+(?=\s)',
      multiLine: true,
    ).allMatches(result.stdout as String);
    final pairs = await Future.wait(
      matches.map((match) async {
        final serial = match.group(0)!;
        final nameResult = await _run(_adb, [
          '-s',
          serial,
          'emu',
          'avd',
          'name',
        ], check: false);
        final name = (nameResult.stdout as String).split('\n').first.trim();
        return MapEntry(name, serial);
      }),
    );
    return Map.fromEntries(
      pairs.where((pair) => _namePattern.hasMatch(pair.key)),
    );
  }

  Future<void> start(String name) async {
    _checkName(name);
    if ((await running()).contains(name)) return;
    if (!(await availableAvds()).contains(name)) {
      throw StateError('Instância $name ausente no Android SDK.');
    }

    final process = await Process.start(
      _emulator,
      ['-avd', name],
      environment: _environment,
      mode: ProcessStartMode.detachedWithStdio,
    );

    var logs = '';
    void collect(String message) => logs = _summary('$logs$message');
    const decoder = Utf8Decoder(allowMalformed: true);
    final out = process.stdout.transform(decoder).forEach(collect);
    final err = process.stderr.transform(decoder).forEach(collect);
    var closed = false;
    unawaited(
      Future.wait([out, err]).then<void>(
        (_) => closed = true,
        onError: (Object error) {
          collect('$error');
          closed = true;
        },
      ),
    );
    try {
      final clock = Stopwatch()..start();
      while (clock.elapsed < const Duration(seconds: 30) && !closed) {
        if ((await running()).contains(name)) return;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      throw StateError('O emulador $name não apareceu no ADB. $logs');
    } catch (_) {
      process.kill();
      rethrow;
    }
  }

  Future<void> stop(String name) async {
    _checkName(name);
    final serial = (await _serialsByAvd())[name];
    if (serial == null) return;
    await _run(_adb, ['-s', serial, 'emu', 'kill']);
    final clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(seconds: 10)) {
      if (!(await running()).contains(name)) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    throw StateError('O emulador ainda está em execução.');
  }

  Future<void> delete(String name) async {
    _checkName(name);
    if ((await running()).contains(name)) {
      throw StateError('Pare o emulador antes de remover a instância.');
    }
    if ((await availableAvds()).contains(name)) {
      await _run(_avdManager, ['delete', 'avd', '-n', name]);
      if ((await availableAvds()).contains(name)) {
        throw StateError('A instância ainda está registrada no Android SDK.');
      }
    }
  }

  int _imageApi(String image) {
    final match = _imagePattern.firstMatch(image);
    if (match == null || !_hostAbis.contains(match.group(3))) {
      throw ArgumentError.value(image, 'image', 'Imagem Android incompatível.');
    }
    return int.parse(match.group(1)!);
  }

  void _checkName(String name) {
    if (!_namePattern.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'Instância fora do laboratório.');
    }
  }

  Future<ProcessResult> _run(
    String binary,
    List<String> arguments, {
    String? input,
    bool check = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final process = await Process.start(
      binary,
      arguments,
      environment: _environment,
    );
    final output = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    final errors = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    if (input != null) process.stdin.write(input);
    await process.stdin.close();
    final exit = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill();
        throw StateError('${binary.split('/').last} excedeu o tempo limite.');
      },
    );
    final result = ProcessResult(process.pid, exit, await output, await errors);
    if (check && exit != 0) {
      throw StateError(
        '${binary.split('/').last} retornou $exit. '
        '${_summary('${result.stderr}\n${result.stdout}')}',
      );
    }
    return result;
  }

  String _summary(String text) {
    final normalized = text.trim();
    return normalized.length <= 4000
        ? normalized
        : normalized.substring(normalized.length - 4000);
  }
}
