import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui';
import 'package:toastification/toastification.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:yaml/yaml.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

mixin AppUpdater<T extends StatefulWidget> on State<T> {
  bool _isDownloading = false;
  late String latestVersion;
  String? localVersion;
  String _message = '';
  final dio = Dio();
  Future<void> initVersion() async {
    localVersion = await appVersion();
  }

  Future<bool> checkUpdate({bool notifyLatestVersion = false}) async {
    if (kIsWeb || !await _checkPermission()) {
      return false;
    }

    localVersion ??= await appVersion();
    return dio
        .get(
          'https://raw.githubusercontent.com/Sipoet/music_player_manager/master/pubspec.yaml',
        )
        .then(
          (response) async {
            if ([200, 302].contains(response.statusCode)) {
              var doc = loadYaml(response.data);
              latestVersion = doc['version'];
              if (isOlderVersion()) {
                TargetPlatform platform = defaultTargetPlatform;
                await _showConfirmDialog(platform) ?? false;
              }
              if (notifyLatestVersion) {
                toastification.show(
                  type: ToastificationType.info,
                  title: const Text('Aplikasi sudah versi terbaru'),
                  description: Text('versi saat ini: $localVersion'),
                );
                return true;
              }
            }
            return false;
          },
          onError: (error) {
            _defaultErrorResponse(error: error);
            return false;
          },
        );
  }

  Future<String> appVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  void _defaultErrorResponse({Object? error}) {
    toastification.dismissAll();
    toastification.show(
      type: ToastificationType.error,
      title: const Text('gagal update'),
      description: Text(error?.toString() ?? ''),
    );
  }

  Future<bool> _checkPermission() {
    return Permission.requestInstallPackages.request().isGranted;
  }

  bool isOlderVersion() {
    final localVersions = localVersion!
        .replaceAll('+1', '')
        .split('.')
        .map<int>((e) => int.parse(e))
        .toList();
    final latestVersions = latestVersion
        .replaceAll('+1', '')
        .split('.')
        .map<int>((e) => int.parse(e))
        .toList();
    for (final (int index, int ver) in latestVersions.indexed) {
      if (ver == localVersions[index]) {
        continue;
      }
      return ver > localVersions[index];
    }
    return false;
  }

  Future<bool?> _showConfirmDialog(TargetPlatform platform) {
    // show the dialog
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: const Text("Versi Terbaru"),
              content: Column(
                children: [
                  Text(
                    'Versi terbaru($latestVersion) aplikasi tersedia. apakah mau update ke terbaru?',
                  ),
                  Text('versi saat ini: $localVersion'),
                  const SizedBox(height: 50),
                  Visibility(
                    visible: _isDownloading,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      backgroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_message),
                ],
              ),
              actions: [
                ElevatedButton(
                  child: const Text("Kembali"),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                ElevatedButton(
                  child: const Text("update sekarang"),
                  onPressed: () {
                    setStateDialog(() {
                      _isDownloading = true;
                    });
                    Future.delayed(
                      Duration.zero,
                      () => downloadApp(platform, setStateDialog),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  final Map _downloadPath = {
    TargetPlatform.android:
        "https://raw.githubusercontent.com/Sipoet/music_player_manager/master/src/android/installer_music_player_manager.apk",
    TargetPlatform.windows:
        "https://raw.githubusercontent.com/Sipoet/music_player_manager/master/src/windows/installer_music_player_manager.exe",
  };

  Future<String?> downloadPath(String extFile) {
    return getDownloadsDirectory().then((dir) {
      if (dir == null) {
        return null;
      }
      return p.join(dir.path, 'installer_music_player_manager.$extFile');
    });
  }

  void downloadApp(
    TargetPlatform platform,
    void Function(void Function()) setStateDialog,
  ) {
    final path = _downloadPath[platform];
    final extFile = path.split('.').last;
    DartPluginRegistrant.ensureInitialized();
    final navigator = Navigator.of(context);
    downloadPath(extFile).then(
      (String? filePath) {
        if (filePath != null) {
          setStateDialog(() {
            _message = 'Downloading.';
          });
          dio
              .download(
                path,
                filePath,
                onReceiveProgress: (actualBytes, int totalBytes) {
                  final progress = (actualBytes / totalBytes * 100)
                      .floor()
                      .toString();
                  setStateDialog(() {
                    _message = 'Downloading. $progress%';
                  });
                },
              )
              .then(
                (value) async {
                  setStateDialog(() {
                    _isDownloading = false;
                    _message = 'Download Complete.';
                  });
                  if (platform == TargetPlatform.android ||
                      platform == TargetPlatform.iOS) {
                    final type = platform == TargetPlatform.android
                        ? 'application/vnd.android.package-archive'
                        : null;
                    OpenFile.open(filePath, type: type).then((
                      openFileResponse,
                    ) {
                      if (openFileResponse.type != ResultType.done) {
                        debugPrint(
                          '====error open file ${openFileResponse.message}',
                        );
                        return;
                      } else {
                        debugPrint('====success open file');
                        navigator.pop();
                      }
                    }, onError: (error) => _defaultErrorResponse(error: error));
                  } else if (platform == TargetPlatform.windows) {
                    await installApp(filePath);
                  } else {
                    toastification.show(
                      type: ToastificationType.success,
                      title: const Text('Sukses download APP'),
                      description: Text(
                        'file installer terinstall di $filePath',
                      ),
                    );
                  }
                },
                onError: (error) {
                  setStateDialog(() {
                    _message = 'gagal download installer';
                    _isDownloading = false;
                  });
                  _defaultErrorResponse(error: error);
                },
              );
        }
      },
      onError: (error) {
        _message = 'gagal cari lokasi download';
        debugPrint(error.toString());
        _isDownloading = false;
      },
    );
  }

  Future<int?> installApk(String filePath) async {
    const platformChannel = MethodChannel('android_package_installer');
    final result = await platformChannel.invokeMethod<int>(
      'installApk',
      filePath,
    );
    return result;
  }

  Future installApp(String filePath) {
    final navigator = Navigator.of(context);
    return Process.run(filePath, []).then((ProcessResult results) {
      navigator.pop();
    });
  }

  void showVersion() {
    showAboutDialog(
      context: context,
      applicationName: 'Allegra Music Player Scheduler & Manager',
      applicationVersion: localVersion,
      // applicationIcon: Image.asset('assets/images/logo.png', width: 45),
      applicationLegalese: "© ${DateTime.now().year} Allegra",
    );
  }
}
