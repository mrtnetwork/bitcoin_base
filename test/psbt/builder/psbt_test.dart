import '../../utils.dart';
import 'psbt_builder_sighash_none_test.dart';
import 'psbt_builder_sighash_single.dart';
import 'psbt_builder_update_input.dart';
import 'psbt_builder_v0.dart';
import 'psbt_update_output.dart';

void psbtTest() {
  psbtTest1();
  psbtTest2();
  psbtTest3();
  psbtTest4();
  psbtTest7();
  psbtTest5();
  psbtTest6();
}

void builderPsbtTest() {
  BitcoinBaseTestApi.runTest(psbtTest, "Psbt");
}

void main() {
  BitcoinBaseTestApi.runTest(builderPsbtTest, "Psbt");
}
