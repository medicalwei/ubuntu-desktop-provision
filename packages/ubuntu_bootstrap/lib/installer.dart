import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsettings/gsettings.dart';
import 'package:path/path.dart' as p;
import 'package:subiquity_client/subiquity_client.dart';
import 'package:subiquity_client/subiquity_server.dart';
import 'package:timezone_map/timezone_map.dart';
import 'package:ubuntu_bootstrap/installer/installation_step.dart';
import 'package:ubuntu_bootstrap/installer/installer_model.dart';
import 'package:ubuntu_bootstrap/installer/installer_wizard.dart';
import 'package:ubuntu_bootstrap/l10n.dart';
import 'package:ubuntu_bootstrap/pages/loading/loading_page.dart';
import 'package:ubuntu_bootstrap/services.dart';
import 'package:ubuntu_flavor/ubuntu_flavor.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';
import 'package:ubuntu_provision/ubuntu_provision.dart';
import 'package:ubuntu_utils/ubuntu_utils.dart';
import 'package:ubuntu_wizard/ubuntu_wizard.dart';
import 'package:yaru/yaru.dart';

export 'installer/installer_wizard.dart';

Future<void> runInstallerApp(
  List<String> args, {
  ThemeData? theme,
  ThemeData? darkTheme,
}) async {
  final options = parseCommandLine(args, onPopulateOptions: (parser) {
    parser.addFlag(
      'dry-run',
      defaultsTo: Platform.environment['LIVE_RUN'] != '1',
      help: 'Run Subiquity server in dry-run mode',
    );
    parser.addOption(
      'dry-run-config',
      valueHelp: 'path',
      help: 'Path of the dry-run config file',
    );
    parser.addOption(
      'machine-config',
      valueHelp: 'path',
      defaultsTo: 'examples/machines/simple.json',
      help: 'Path of the machine config (dry-run only)',
    );
    parser.addOption(
      'source-catalog',
      valueHelp: 'path',
      defaultsTo: 'examples/sources/desktop.yaml',
      help: 'Path of the source catalog (dry-run only)',
    );
    // This can't be handled by the whitelabel config since if a user clicks
    // try, the next time it opens the installer the page shouldn't show.
    parser.addFlag('try-or-install', aliases: ['welcome']);
  })!;
  final liveRun = options['dry-run'] != true;
  final exe = p.basename(Platform.resolvedExecutable);
  final log =
      Logger.setup(path: liveRun ? '/var/log/installer/$exe.log' : null);

  final serverMode = liveRun ? ServerMode.LIVE : ServerMode.DRY_RUN;
  final endpoint = await defaultEndpoint(serverMode);
  final includeTryOrInstall = options['try-or-install'] as bool? ?? false;
  final process = liveRun
      ? null
      : SubiquityProcess.python(
          'subiquity.cmd.server',
          serverMode: ServerMode.DRY_RUN,
          subiquityPath: await getSubiquityPath()
              .then((dir) => Directory(dir).existsSync() ? dir : null),
        );

  final baseName = p.basename(Platform.resolvedExecutable);

  // conditional registration if not already registered by flavors or tests
  tryRegisterService<AccessibilityService>(GnomeAccessibilityService.new);
  tryRegisterService<ActiveDirectoryService>(
      () => SubiquityActiveDirectoryService(getService<SubiquityClient>()));
  tryRegisterServiceInstance<ArgResults>(options);
  tryRegisterService<ConfigService>(ConfigService.new);
  if (liveRun) tryRegisterService<DesktopService>(GnomeService.new);
  tryRegisterServiceFactory<GSettings, String>(GSettings.new);
  tryRegisterService<IdentityService>(() => SubiquityIdentityService(
      getService<SubiquityClient>(), getService<PostInstallService>()));
  tryRegisterService<InstallerService>(
    () => InstallerService(
      getService<SubiquityClient>(),
      pageConfig: getService<PageConfigService>(),
    ),
  );
  tryRegisterService(JournalService.new);
  tryRegisterService<KeyboardService>(
    () => SubiquityKeyboardService(getService<SubiquityClient>()),
  );
  tryRegisterService<LocaleService>(
    () => SubiquityLocaleService(getService<SubiquityClient>()),
  );
  tryRegisterService<NetworkService>(
    () => SubiquityNetworkService(getService<SubiquityClient>()),
  );
  tryRegisterService(
    () => PageConfigService(
      config: tryGetService<ConfigService>(),
      includeTryOrInstall: includeTryOrInstall,
      allowedToHide: InstallationStep.allowedToHideKeys,
    ),
  );
  tryRegisterService(() => PostInstallService('/tmp/$baseName.conf'));
  tryRegisterService(PowerService.new);
  tryRegisterService(ProductService.new);
  tryRegisterService(() => RefreshService(getService<SubiquityClient>()));
  tryRegisterService<SessionService>(
    () => SubiquitySessionService(getService<SubiquityClient>()),
  );
  if (liveRun) tryRegisterService(SoundService.new);
  tryRegisterService(() => StorageService(getService<SubiquityClient>()));
  tryRegisterService(SubiquityClient.new);
  tryRegisterService(
    () => SubiquityServer(process: process, endpoint: endpoint),
  );
  tryRegisterService<TelemetryService>(() {
    final String path;
    if (kDebugMode) {
      final exe = Platform.resolvedExecutable;
      path = '${p.dirname(exe)}/.${p.basename(exe)}/telemetry';
    } else {
      path = '/var/log/installer/telemetry';
    }
    return TelemetryService(path);
  });
  tryRegisterService<ThemeVariantService>(
    () => ThemeVariantService(config: tryGetService<ConfigService>()),
  );
  tryRegisterService<TimezoneService>(
      () => SubiquityTimezoneService(getService<SubiquityClient>()));
  tryRegisterService(UdevService.new);
  tryRegisterService(UrlLauncher.new);

  final subiquityArgs = [
    if (options['dry-run-config'] != null)
      '--dry-run-config=${options['dry-run-config']}',
    if (options['machine-config'] != null)
      '--machine-config=${options['machine-config']}',
    if (options['source-catalog'] != null)
      '--source-catalog=${options['source-catalog']}',
    '--storage-version=2',
    '--dry-run-config=examples/dry-run-configs/tpm.yaml',
    ...options.rest,
  ];

  await runZonedGuarded(() async {
    FlutterError.onError = (error) {
      log.error('Unhandled exception', error.exception, error.stack);
    };

    final window = await YaruWindow.ensureInitialized();
    await window.onClose(_closeInstallerApp);

    final themeVariantService = getService<ThemeVariantService>();
    await themeVariantService.load();
    final themeVariant = themeVariantService.themeVariant;

    final configService = getService<ConfigService>();
    final windowTitle = await configService.get<String>('app-name');

    // This needs to be done out of order since it depends on the asset bundle
    // to be populated.
    final flavorService = await FlavorService.load();
    tryRegisterService<FlavorService>(() => flavorService);

    runApp(ProviderScope(
      child: _InstallerApp(
        theme: theme,
        darkTheme: darkTheme,
        themeVariant: themeVariant,
        windowTitle: windowTitle,
        flavor: flavorService.flavor,
        init: getService<SubiquityServer>()
            .start(args: subiquityArgs)
            .then(_initInstallerApp),
      ),
    ));
  }, (error, stack) => log.error('Unhandled exception', error, stack));
}

class _InstallerApp extends ConsumerWidget {
  const _InstallerApp({
    required this.theme,
    required this.darkTheme,
    required this.themeVariant,
    required this.windowTitle,
    required this.flavor,
    required this.init,
  });

  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeVariant? themeVariant;
  final String? windowTitle;
  final UbuntuFlavor flavor;
  final Future<void> init;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WizardApp(
      flavor: flavor,
      theme: theme ?? themeVariant?.theme,
      darkTheme: darkTheme ?? themeVariant?.darkTheme,
      onGenerateTitle: (context) {
        if (windowTitle != null) return windowTitle!;
        return UbuntuBootstrapLocalizations.of(context)
            .windowTitle(flavor.displayName);
      },
      locale: ref.watch(localeProvider),
      localizationsDelegates: GlobalUbuntuBootstrapLocalizations.delegates,
      supportedLocales: supportedLocales,
      home: DefaultAssetBundle(
        bundle: ProxyAssetBundle(
          rootBundle,
          package: 'ubuntu_bootstrap',
        ),
        child: FutureBuilder<void>(
            future: init,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingPage();
              } else if (snapshot.hasError) {
                return const ErrorPage(allowRestart: false);
              }
              return InstallerWizard(key: ValueKey(ref.watch(restartProvider)));
            }),
      ),
    );
  }
}

Future<void> _initInstallerApp(Endpoint endpoint) async {
  getService<SubiquityClient>().open(endpoint);

  var geo = tryGetService<GeoService>();
  if (geo == null) {
    final geodata = Geodata.asset();
    final geoname = Geoname.ubuntu(geodata: geodata);
    geo = GeoService(sources: [geodata, geoname]);
    registerServiceInstance(geo);
  }
  final telemetry = getService<TelemetryService>();

  final services = [
    getService<InstallerService>().init(),
    tryGetService<DesktopService>()?.inhibit() ?? Future.value(),
    getService<PageConfigService>().load(),
    geo.init(),
    telemetry.init({
      'Type': 'Flutter',
      'OEM': false,
      'Media': getService<ProductService>().getProductInfo().toString(),
    }),
  ];
  await Future.wait(services);
}

Future<bool> _closeInstallerApp() async {
  await getService<SubiquityClient>().close();
  await getService<SubiquityServer>().stop();
  await tryGetService<DesktopService>()?.close();
  return true;
}
