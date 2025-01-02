import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

/// copied from https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash/tests/test_token.py
// # Copyright (c) 2023 Calin Culianu <calin.culianu@gmail.com>
// #
// # Permission is hereby granted, free of charge, to any person obtaining a copy
// # of this software and associated documentation files (the "Software"), to deal
// # in the Software without restriction, including without limitation the rights
// # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// # copies of the Software, and to permit persons to whom the Software is
// # furnished to do so, subject to the following conditions:
// #
// # The above copyright notice and this permission notice shall be included in
// # all copies or substantial portions of the Software.
// #
// # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// # THE SOFTWARE.

final Map<String, Map<String, dynamic>> bitcoinCashAddresses = {
  'bitcoincash:qr7fzmep8g7h7ymfxy74lgc0v950j3r2959lhtxxsl': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bitcoincash:zr7fzmep8g7h7ymfxy74lgc0v950j3r295z4y4gq0v': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bchtest:qr7fzmep8g7h7ymfxy74lgc0v950j3r295pdnvy3hr': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bchtest:zr7fzmep8g7h7ymfxy74lgc0v950j3r295x8qj2hgs': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bchreg:qr7fzmep8g7h7ymfxy74lgc0v950j3r295m39d8z59': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bchreg:zr7fzmep8g7h7ymfxy74lgc0v950j3r295umknfytk': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'prefix:qr7fzmep8g7h7ymfxy74lgc0v950j3r295fu6e430r': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'prefix:zr7fzmep8g7h7ymfxy74lgc0v950j3r295wkf8mhss': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'fc916f213a3d7f1369313d5fa30f6168f9446a2d',
  },
  'bitcoincash:qpagr634w55t4wp56ftxx53xukhqgl24yse53qxdge': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': '7a81ea357528bab834d256635226e5ae047d5524',
  },
  'bitcoincash:zpagr634w55t4wp56ftxx53xukhqgl24ys77z7gth2': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': '7a81ea357528bab834d256635226e5ae047d5524',
  },
  'bitcoincash:qq9l9e2dgkx0hp43qm3c3h252e9euugrfc6vlt3r9e': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': '0bf2e54d458cfb86b106e388dd54564b9e71034e',
  },
  'bitcoincash:zq9l9e2dgkx0hp43qm3c3h252e9euugrfcaxv4l962': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': '0bf2e54d458cfb86b106e388dd54564b9e71034e',
  },
  'bitcoincash:qre24q38ghy6k3pegpyvtxahu8q8hqmxmqqn28z85p': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'f2aa822745c9ab44394048c59bb7e1c07b8366d8',
  },
  'bitcoincash:zre24q38ghy6k3pegpyvtxahu8q8hqmxmq8eeevptj': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'f2aa822745c9ab44394048c59bb7e1c07b8366d8',
  },
  'bitcoincash:qz7xc0vl85nck65ffrsx5wvewjznp9lflgktxc5878': {
    'type': 0,
    'addressType': 'P2PKH',
    'programLength': 20,
    'programBytes': 'bc6c3d9f3d278b6a8948e06a399974853097e9fa',
  },
  'bitcoincash:zz7xc0vl85nck65ffrsx5wvewjznp9lflg3p4x6pp5': {
    'type': 2,
    'addressType': 'Token-Aware P2PKH',
    'programLength': 20,
    'programBytes': 'bc6c3d9f3d278b6a8948e06a399974853097e9fa',
  },
  'bitcoincash:ppawqn2h74a4t50phuza84kdp3794pq3ccvm92p8sh': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 20,
    'programBytes': '7ae04d57f57b55d1e1bf05d3d6cd0c7c5a8411c6',
  },
  'bitcoincash:rpawqn2h74a4t50phuza84kdp3794pq3cct3k50p0y': {
    'type': 3,
    'addressType': 'Token-Aware P2SH',
    'programLength': 20,
    'programBytes': '7ae04d57f57b55d1e1bf05d3d6cd0c7c5a8411c6',
  },
  'bitcoincash:pqv53dwyatxse2xh7nnlqhyr6ryjgfdtagkd4vc388': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 20,
    'programBytes': '1948b5c4eacd0ca8d7f4e7f05c83d0c92425abea',
  },
  'bitcoincash:rqv53dwyatxse2xh7nnlqhyr6ryjgfdtag38xjkhc5': {
    'type': 3,
    'addressType': 'Token-Aware P2SH',
    'programLength': 20,
    'programBytes': '1948b5c4eacd0ca8d7f4e7f05c83d0c92425abea',
  },
  'bitcoincash:prseh0a4aejjcewhc665wjqhppgwrz2lw5txgn666a': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 20,
    'programBytes': 'e19bbfb5ee652c65d7c6b54748170850e1895f75',
  },
  'bitcoincash:rrseh0a4aejjcewhc665wjqhppgwrz2lw5vvmd5u9w': {
    'type': 3,
    'addressType': 'Token-Aware P2SH',
    'programLength': 20,
    'programBytes': 'e19bbfb5ee652c65d7c6b54748170850e1895f75',
  },
  'bitcoincash:pzltaslh7xnrsxeqm7qtvh0v53n3gfk0v5wwf6d7j4': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 20,
    'programBytes': 'bebec3f7f1a6381b20df80b65deca4671426cf65',
  },
  'bitcoincash:rzltaslh7xnrsxeqm7qtvh0v53n3gfk0v5fy6yrcdx': {
    'type': 3,
    'addressType': 'Token-Aware P2SH',
    'programLength': 20,
    'programBytes': 'bebec3f7f1a6381b20df80b65deca4671426cf65',
  },
  'bitcoincash:pvqqqqqqqqqqqqqqqqqqqqqqzg69v7ysqqqqqqqqqqqqqqqqqqqqqpkp7fqn0': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 32,
    'programBytes':
        '0000000000000000000000000000123456789000000000000000000000000000',
  },
  'bitcoincash:rvqqqqqqqqqqqqqqqqqqqqqqzg69v7ysqqqqqqqqqqqqqqqqqqqqqn9alsp2y': {
    'type': 3,
    'addressType': 'Token-Aware P2SH',
    'programLength': 32,
    'programBytes':
        '0000000000000000000000000000123456789000000000000000000000000000',
  },
  'bitcoincash:pdzyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3jh2p5nn': {
    'type': 1,
    'addressType': 'P2SH',
    'programLength': 32,
    'programBytes':
        '4444444444444444444444444444444444444444444444444444444444444444',
  },
};

void main() {
  test('decode encode address', () {
    for (final i in bitcoinCashAddresses.keys.toList()) {
      final info = Map.from(bitcoinCashAddresses[i]!);
      const network = BitcoinCashNetwork.mainnet;
      final address =
          BitcoinCashAddress(i, network: network, validateNetworkPrefix: false);
      expect(address.baseAddress.addressProgram, info['programBytes']);
      final hrp = i.substring(0, i.indexOf(':'));
      expect(i, address.toAddress(network, hrp));
    }
  });
}
