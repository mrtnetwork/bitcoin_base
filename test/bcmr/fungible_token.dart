const fungibleToken = {
  r'$schema': 'https://cashtokens.org/bcmr-v2.schema.json',
  'version': {'major': 1, 'minor': 1, 'patch': 0},
  'latestRevision': '2023-04-14T00:00:17.720Z',
  'registryIdentity': {
    'name': 'Example.com Token Registry',
    'description':
        'An example registry demonstrating how the issuer of a single kind of fungible token might publish information about the token.',
    'uris': {
      'icon': 'https://example.com/registry-icon.svg',
      'web': 'https://example.com/',
      'registry':
          'https://example.com/.well-known/bitcoin-cash-metadata-registry.json'
    }
  },
  'identities': {
    '89cad9e3e34280eb1e8bc420542c00a7fcc01002b663dbf7f38bceddf80e680c': {
      '2023-01-03T00:00:00.000Z': {
        'name': 'Example Asset',
        'description':
            "This is a record of an older entry for the token identity. The token was rebranded (from EXAMPLE to XAMPL) and redenominated (from 8 to 6 decimals), but the existing token category was not modified: users were not required to trade their original EXAMPLE tokens for the redenominated XAMPL tokens, their wallets simply updated the way tokens are displayed using the new metadata. Note, this entry has likely been updated by the issuer to provide useful historical information rather than attempting to preserve the precise contents of the old snapshot; the 'web' URI links to a blog post about XAMPL's re-denomination/re-brand, and outdated URI information is excluded. There may have been metadata updates published between this snapshot and the latest snapshot, but they've been excluded because registries should strive to present a useful history of only meaningful changes to identities. This information can be used in user interfaces to improve continuity following metadata updates or to offer historical context.",
        'token': {
          'category':
              '89cad9e3e34280eb1e8bc420542c00a7fcc01002b663dbf7f38bceddf80e680c',
          'decimals': 8,
          'symbol': 'EXAMPLE'
        },
        'uris': {
          'icon': 'https://example.com/old-example-asset-icon.png',
          'web': 'https://blog.example.com/example-asset-is-now-XAMPL'
        }
      }
    }
  },
  'license': 'CC0-1.0'
};
