import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:subiquity_client/subiquity_client.dart';
import 'package:ubuntu_bootstrap/pages/storage/storage_model.dart';
import 'package:ubuntu_bootstrap/services.dart';

import 'test_storage.mocks.dart';

export '../test_utils.dart';
export 'bitlocker/test_bitlocker.dart';
export 'guided_reformat/test_guided_reformat.dart';
export 'guided_resize/test_guided_resize.dart';
export 'manual/test_manual_storage.dart';
export 'recovery_key/test_recovery_key.dart';
export 'security_key/test_security_key.dart';
export 'test_storage.mocks.dart';

@GenerateMocks([StorageModel])
StorageModel buildStorageModel({
  StorageType? type = StorageType.erase,
  GuidedCapability? guidedCapability,
  ProductInfo? productInfo,
  List<OsProber>? existingOS,
  bool? canInstallAlongside,
  bool? canEraseDisk,
  bool? canManualPartition,
  bool? hasBitLocker,
}) {
  final model = MockStorageModel();
  when(model.type).thenReturn(type);
  when(model.guidedCapability)
      .thenReturn(guidedCapability ?? GuidedCapability.DIRECT);
  when(model.productInfo).thenReturn(productInfo ?? ProductInfo(name: ''));
  when(model.existingOS).thenReturn(existingOS);
  when(model.canInstallAlongside).thenReturn(canInstallAlongside ?? false);
  when(model.canEraseDisk).thenReturn(canEraseDisk ?? true);
  when(model.canManualPartition).thenReturn(canManualPartition ?? true);
  when(model.hasBitLocker).thenReturn(hasBitLocker ?? false);
  return model;
}
