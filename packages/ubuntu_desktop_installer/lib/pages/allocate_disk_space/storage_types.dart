import 'package:filesize/filesize.dart';
import 'package:subiquity_client/subiquity_client.dart';

export 'package:subiquity_client/subiquity_client.dart'
    show Disk, DiskObject, Gap, Partition;

extension DiskExtension on Disk {
  String get prettySize => filesize(size ?? 0);
}

extension PartitionExtension on Partition {
  bool get canWipe => mount != null;
  String get prettySize => filesize(size ?? 0);
}
