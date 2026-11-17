import 'utils.dart';

void bip68Test() {}

void bip68Test2() {
  BitcoinBaseTestApi.runTest(bip68Test, "Bip68");
}

void main() {
  BitcoinBaseTestApi.runTest(bip68Test2, "Bip68");
}

