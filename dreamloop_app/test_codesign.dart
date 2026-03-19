import 'dart:io';

void main() {
  final path = '/Users/harshaaryan/Desktop/DreamLoop/dreamloop_app/build/ios/Debug-iphonesimulator/Flutter.framework/';
  final codesignIdentity = '-';
  final result = Process.runSync('sh', [
    '-c',
    'sleep 0.2 && xattr -cr "\$1" && /usr/bin/codesign --force --sign "\$2" --timestamp=none "\$1"',
    'codesign_wrapper',
    path,
    codesignIdentity,
  ]);
  print('Exit code: ${result.exitCode}');
  print('Stdout: ${result.stdout}');
  print('Stderr: ${result.stderr}');
}
