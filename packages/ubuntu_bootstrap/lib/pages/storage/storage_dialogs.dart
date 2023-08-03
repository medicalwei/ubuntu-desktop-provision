import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subiquity_client/subiquity_client.dart';
import 'package:ubuntu_bootstrap/l10n.dart';
import 'package:ubuntu_provision/ubuntu_provision.dart';
import 'package:ubuntu_widgets/ubuntu_widgets.dart';
import 'package:ubuntu_wizard/ubuntu_wizard.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import 'storage_model.dart';

enum AdvancedFeature { none, lvm, zfs }

/// Shows a dialog to select advanced installation features.
Future<void> showAdvancedFeaturesDialog(
    BuildContext context, StorageModel model) async {
  final advancedFeature = ValueNotifier(
      model.guidedCapability?.toAdvancedFeature() ?? AdvancedFeature.none);
  final encryption =
      ValueNotifier(model.guidedCapability == GuidedCapability.LVM_LUKS);

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final lang = UbuntuBootstrapLocalizations.of(context);

      return AlertDialog(
        title: YaruDialogTitleBar(
          title: Text(lang.installationTypeAdvancedTitle),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(kYaruPagePadding),
        actionsPadding: const EdgeInsets.all(kYaruPagePadding),
        buttonPadding: EdgeInsets.zero,
        scrollable: true,
        content: AnimatedBuilder(
          animation: Listenable.merge([advancedFeature, encryption]),
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                YaruRadioButton<AdvancedFeature>(
                  title: Text(lang.installationTypeNone),
                  value: AdvancedFeature.none,
                  groupValue: advancedFeature.value,
                  onChanged: (v) => advancedFeature.value = v!,
                ),
                const SizedBox(height: kWizardSpacing),
                YaruRadioButton<AdvancedFeature>(
                  title: Consumer(builder: (context, ref, child) {
                    final flavor = ref.watch(flavorProvider);
                    return Text(lang.installationTypeLVM(flavor.name));
                  }),
                  value: AdvancedFeature.lvm,
                  groupValue: advancedFeature.value,
                  onChanged: (v) => advancedFeature.value = v!,
                ),
                Padding(
                  padding: kWizardIndentation,
                  child: YaruCheckButton(
                    title: Consumer(builder: (context, ref, child) {
                      final flavor = ref.watch(flavorProvider);
                      return Text(lang.installationTypeEncrypt(flavor.name));
                    }),
                    subtitle: Text(lang.installationTypeEncryptInfo),
                    value: encryption.value,
                    onChanged: advancedFeature.value == AdvancedFeature.lvm
                        ? (v) => encryption.value = v!
                        : null,
                  ),
                ),
                const SizedBox(height: kWizardSpacing),
                // https://github.com/canonical/ubuntu-desktop-installer/issues/373
                // YaruRadioButton<AdvancedFeature>(
                //   title: Text(lang.installationTypeZFS),
                //   value: AdvancedFeature.zfs,
                //   groupValue: advancedFeature.value,
                //   onChanged: (v) => advancedFeature.value = v!,
                // ),
              ],
            );
          },
        ),
        actions: [
          PushButton.outlined(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(UbuntuLocalizations.of(context).cancelLabel),
          ),
          const SizedBox(width: kWizardBarSpacing),
          PushButton.filled(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(UbuntuLocalizations.of(context).okLabel),
          ),
        ],
      );
    },
  );

  if (result == true) {
    model.guidedCapability =
        advancedFeature.value.toGuidedCapability(encryption: encryption.value);
  }
}

extension on GuidedCapability {
  AdvancedFeature? toAdvancedFeature() {
    switch (this) {
      case GuidedCapability.LVM:
      case GuidedCapability.LVM_LUKS:
        return AdvancedFeature.lvm;
      default:
        return AdvancedFeature.none;
    }
  }
}

extension on AdvancedFeature {
  GuidedCapability toGuidedCapability({bool? encryption}) {
    switch (this) {
      case AdvancedFeature.lvm:
        return encryption == true
            ? GuidedCapability.LVM_LUKS
            : GuidedCapability.LVM;
      default:
        return GuidedCapability.DIRECT;
    }
  }
}
