import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

main() {
  final Uri path = Platform.script.resolve('..').resolve('.socfony.yml');
  final String yaml = File(path.toFilePath()).readAsStringSync();
  final dynamic data = json.decode(json.encode(loadYaml(yaml)));

  final List<String> classes = [];
  final StringBuffer buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// GENERATED BY ${path.toFilePath()}');
  buffer.writeln();
  buffer.writeln('class Configuration {');
  buffer.writeln('  const Configuration();');
  for (var item in build(data as Map<String, dynamic>, classes)) {
    buffer.writeln(item);
  }
  buffer.writeln('}');
  buffer.writeln();
  for (var value in classes) {
    buffer.writeln(value);
  }

  final String output = buffer.toString();
  final String outputPath = Platform.script
      .resolve('..')
      .resolve('lib/configuration.dart')
      .toFilePath();
  File(outputPath).writeAsStringSync(output);

  // Build database env
  final StringBuffer envBuffer = StringBuffer();
  envBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  envBuffer.writeln('// GENERATED BY ${path.toFilePath()}');
  envBuffer.writeln();
  envBuffer.writeln('DATABASE_URL=${data['database']}');

  final String env = envBuffer.toString();
  final String outEnvPath =
      Platform.script.resolve('..').resolve('.env').toFilePath();
  File(outEnvPath).writeAsStringSync(env);
}

List<String> build(Map<String, dynamic> data, List<String> classes) {
  final List<String> lines = [];

  for (var key in data.keys) {
    final name = toHump(key);
    final value = data[key];
    if (value is Map) {
      final StringBuffer buffer = StringBuffer();
      final className = '_${toHumpCapital(name)}Configuration';
      buffer.writeln('class $className {');
      for (var item in build(value as Map<String, dynamic>, classes)) {
        buffer.writeln(item);
      }
      buffer.writeln('}');

      classes.add(buffer.toString());
      lines.add('  $className get $name => $className();');
    } else if (value is List) {
      lines.add('  final List<dynamic> $name = const ${json.encode(value)};');
    } else {
      final _v = value is String ? 'r"$value"' : value;
      lines.add('  final ${value.runtimeType} $name = $_v;');
    }
  }

  return lines;
}

String toHump(String str) {
  final List<String> words = str.replaceAll('-', '_').split('_');
  final StringBuffer buffer = StringBuffer();
  for (var word in words) {
    buffer.write(word.substring(0, 1).toUpperCase());
    buffer.write(word.substring(1));
  }

  final String hump = buffer.toString();

  return hump.substring(0, 1).toLowerCase() + hump.substring(1);
}

String toHumpCapital(String str) {
  final hump = toHump(str);
  return hump.substring(0, 1).toUpperCase() + hump.substring(1);
}
