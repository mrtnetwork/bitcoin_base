import '../../utils.dart';
import 'psbt_builder_sighash_none.dart';
import 'psbt_builder_sighash_single.dart';
import 'psbt_builder_update_input.dart';
import 'psbt_builder_v0.dart';
import 'psbt_update_output.dart';

void main() {
  List<Function> testCases = [
    psbtTest1,
    psbtTest2,
    psbtTest3,
    psbtTest4,
    psbtTest7,
    psbtTest5,
    psbtTest6,
  ];
  for (final i in testCases.takeShuffle()) {
    i();
  }
}
