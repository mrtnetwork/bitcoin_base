import 'utils.dart';

void bcsTest() {}

void bcsTest2() {
  BitcoinBaseTestApi.runTest(bcsTest, "Bcs");
}

void main() {
  BitcoinBaseTestApi.runTest(bcsTest2, "Bcs");
}
