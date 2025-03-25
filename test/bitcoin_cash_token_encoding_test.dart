import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

final List<Map<String, dynamic>> _validTestVector = [
  {
    'prefix':
        'efaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1001',
    'data': {
      'amount': '1',
      'category':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    }
  },
  {
    'prefix':
        'ef21430000000000000000000000000000000000000000000000000000000034121001',
    'data': {
      'amount': '1',
      'category':
          '1234000000000000000000000000000000000000000000000000000000004321'
    }
  },
  {
    'prefix':
        'ef21436587090000000000000000000000000000000000000000000090785634121001',
    'data': {
      'amount': '1',
      'category':
          '1234567890000000000000000000000000000000000000000000000987654321'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1001',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10fc',
    'data': {
      'amount': '252',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10fdfd00',
    'data': {
      'amount': '253',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10fdffff',
    'data': {
      'amount': '65535',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10fe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10fe01000100',
    'data': {
      'amount': '65537',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10feffffffff',
    'data': {
      'amount': '4294967295',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10ff0000000001000000',
    'data': {
      'amount': '4294967296',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10ff0100000001000000',
    'data': {
      'amount': '4294967297',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb10ffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb20',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3001',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30fc',
    'data': {
      'amount': '252',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30fdfd00',
    'data': {
      'amount': '253',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30fdffff',
    'data': {
      'amount': '65535',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30fe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30feffffffff',
    'data': {
      'amount': '4294967295',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30ff0000000001000000',
    'data': {
      'amount': '4294967296',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30ffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6001cc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb60051234567890',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '1234567890', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001cc01',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccfc',
    'data': {
      'amount': '252',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccfdfd00',
    'data': {
      'amount': '253',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccfdffff',
    'data': {
      'amount': '65535',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccfeffffffff',
    'data': {
      'amount': '4294967295',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccff0000000001000000',
    'data': {
      'amount': '4294967296',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7001ccffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb700accccccccccccccccccccfdffff',
    'data': {
      'amount': '65535',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cccccccccccccccccccc', 'capability': 'none'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7028cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'none'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7029cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'none'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb60fdfd00cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'none'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb70fdfd00cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'none'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb70fde903cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'none'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb21',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb31feffffffff',
    'data': {
      'amount': '4294967295',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6101cc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7101ccff0000000001000000',
    'data': {
      'amount': '4294967296',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7102ccccffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cccc', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb710acccccccccccccccccccc01',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cccccccccccccccccccc', 'capability': 'mutable'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7128cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccfc',
    'data': {
      'amount': '252',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'mutable'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7129cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccccfc',
    'data': {
      'amount': '252',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'mutable'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb71fdfd00cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc01',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'mutable'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb22',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3201',
    'data': {
      'amount': '1',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb32fdfd00',
    'data': {
      'amount': '253',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb32fe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb32ff0000000001000000',
    'data': {
      'amount': '4294967296',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb32ffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': '', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6201cc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6229cccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'minting'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7201ccfdffff',
    'data': {
      'amount': '65535',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cc', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7202ccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cccc', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb720accccccccccccccccccccff01000000'
            '01000000',
    'data': {
      'amount': '4294967297',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {'commitment': 'cccccccccccccccccccc', 'capability': 'minting'}
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7228cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'minting'
      }
    }
  },
  {
    'prefix':
        'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7229cccccccccccccccccccccccccccccc'
            'ccccccccccccccccccccccccccccccccccccccccccccccccccccffffffffffffffff7f',
    'data': {
      'amount': '9223372036854775807',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'minting'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb62fdfd00cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'data': {
      'amount': '0',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'minting'
      }
    }
  },
  {
    'prefix': 'efbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb72fdfd00cccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
        'ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfe00000100',
    'data': {
      'amount': '65536',
      'category':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'nft': {
        'commitment': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'capability': 'minting'
      }
    }
  }
];
void main() {
  test('cash token encoding', () {
    for (var c = 0; c < _validTestVector.length; c++) {
      final i = _validTestVector[c];
      final appendBytes = QuickCrypto.generateRandom(c * 2);
      final tokenBytes = BytesUtils.fromHexString(i['prefix']!);
      final combine = <int>[...tokenBytes, ...appendBytes];
      final decode = CashToken.deserialize(combine);
      final data = Map<String, dynamic>.from(i['data']);
      final amount = BigInt.parse(data['amount']);
      final nft =
          data['nft'] == null ? null : Map<String, dynamic>.from(data['nft']);
      final capability =
          nft == null ? null : CashTokenCapability.fromName(nft['capability']);
      final commitment = BytesUtils.toHexString(decode.item1!.commitment);
      expect(capability, decode.item1!.capability);
      expect(decode.item1?.toHex(), i['prefix']!);
      expect(commitment, (nft?['commitment'] ?? ''));
      expect(amount, decode.item1!.amount);
      expect(combine.sublist(decode.item2), appendBytes);
    }
  });
}
