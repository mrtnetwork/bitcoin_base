// Library for Bitcoin addresses handling in the bitcoin_base package.
//
// The library includes essential components such as:
// - Core address functionality.
// - encode/decode Legacy address support.
// - Utility functions for address manipulation.
// - encode/decode Segregated Witness (SegWit) address implementation.
// - Enhanced functionality for improved handling of addresses across diverse networks.
library address;

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
part 'core.dart';
part 'legacy_address.dart';
part 'utils/address_utils.dart';
part 'segwit_address.dart';
part 'network_address.dart';
