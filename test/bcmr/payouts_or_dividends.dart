const payoutsOrDividends = {
  r'$schema': 'https://cashtokens.org/bcmr-v2.schema.json',
  'version': {'major': 1, 'minor': 1, 'patch': 0},
  'latestRevision': '2023-04-14T00:00:17.720Z',
  'registryIdentity': {
    'name': 'Example.com Token Registry',
    'description':
        "An example demonstrating how a registry might publish information about fungible tokens that receive on-chain payouts or dividends, either from off-chain activities (e.g. equity or debt instruments) or as part of an on-chain mechanism (e.g. payouts from a decentralized application or sidechain).\n\nDescriptions below are written from the perspective of a client reading this registry shortly after its 'lastRevision' timestamp on 2023-04-14.",
    'uris': {
      'icon': 'https://example.com/registry-icon.svg',
      'web': 'https://example.com/',
      'registry':
          'https://example.com/.well-known/bitcoin-cash-metadata-registry.json'
    }
  },
  'identities': {
    '978306aa4e02fd06e251b38d2e961f78f4af2ea6524a3e4531126776276a6af1': {
      '2023-06-30T00:00:00.000Z': {
        'name': 'Example Payout Shares',
        'description':
            "This is a description of Example Payout Shares. In most interfaces, it will be hidden beyond 140 characters or the first newline character.\n\nThis sentence should be hidden in user interfaces with limited space.\n\nThis asset entitles holders to on-chain payouts of some kind. For example, they may be shares of a company, interest-paying debt, or utility tokens of a decentralized application where holders have performed some service to the protocol (e.g. sidechain validation, liquidity provision, etc.).\n\nNote that this particular identity snapshot has not yet come into effect (assuming the client is reading the registry shortly after its 'lastRevision' timestamp on 2023-04-14); the next identity snapshot contains the current information for the identity. Instead, this snapshot indicates an update to the identity expected to happen in the future: a payout for 2023Q2, where token holders will trade in fungible tokens of the 2023Q2 category for a quarterly payout and receive an equivalent number of fungible tokens of the new, 2023Q3 category listed in this snapshot.",
        'migrated': '2023-07-01T00:00:00.000Z',
        'token': {
          'category':
              '89cad9e3e34280eb1e8bc420542c00a7fcc01002b663dbf7f38bceddf80e680c',
          'decimals': 6,
          'symbol': 'XAMPL-23Q3'
        },
        'uris': {
          'icon': 'https://example.com/asset-icon.svg',
          'web': 'https://example.com/',
          'migrate': 'https://app.example.com/payouts/2023Q2',
          'blog': 'https://blog.example.com/',
          'chat': 'https://chat.example.com/',
          'forum': 'https://forum.example.com/',
          'registry':
              'https://example.com/.well-known/bitcoin-cash-metadata-registry.json',
          'support': 'https://support.example.com/',
          'custom-uri-identifier':
              'protocol://connection-info-for-some-protocol'
        }
      },
      '2023-03-31T00:00:00.000Z': {
        'name': 'Example Payout Shares',
        'description':
            "The current identity snapshot for this token identity (assuming the client is reading the registry shortly after its 'lastRevision' timestamp on 2023-04-14). Note that as of now, tokens of this category (b1a35ca...) should be listed by the client simply by base symbol: XAMPL. When the next snapshot's initial timestamp is reached (2023-06-30) their full symbol should be displayed, XAMPL-23Q2, as the latest category for this token identity will become XAMPL-23Q3 (89cad9...), and only tokens of that category should be referred to using the base symbol. Holders of XAMPL-23Q2 can refer to the 'migrate' URI in the next snapshot for information about acquiring the new XAMPL tokens (XAMPL-23Q3) and their 2nd quarterly payout by trading in their XAMPL-23Q2 fungible tokens.",
        'migrated': '2023-04-01T00:00:00.000Z',
        'token': {
          'category':
              'b1a35cadd5ddb1bd18787eeb99ee061f34b946f0db375d84caadd8ab621c10f5',
          'decimals': 6,
          'symbol': 'XAMPL-23Q2'
        },
        'uris': {
          'icon': 'https://example.com/asset-icon.svg',
          'web': 'https://example.com/',
          'migrate': 'https://app.example.com/payouts/2023Q1',
          'blog': 'https://blog.example.com/',
          'chat': 'https://chat.example.com/',
          'forum': 'https://forum.example.com/',
          'registry':
              'https://example.com/.well-known/bitcoin-cash-metadata-registry.json',
          'support': 'https://support.example.com/',
          'custom-uri-identifier':
              'protocol://connection-info-for-some-protocol'
        }
      },
      '2022-12-31T00:00:00.000Z': {
        'name': 'Example Payout Shares (2023Q1)',
        'description':
            "Payout shares for Example Protocol for the first quarter of 2023. These shares can be redeemed with the on-chain payout system to receive the payout and the new tokens for 2023Q2. See the linked website for details.\n\nExample note: this asset (XAMPL-23Q1, 978306...) will still be held in wallets that have not yet redeemed the 2023Q1 payout. Because the payout is held by an on-chain covenant, it's safe to delay redemption indefinitely, as funds (and the new, XAMPL-23Q2 tokens) will remain in the covenant until fully claimed by existing XAMPL-23Q1 holders. Some holders may leave XAMPL-23Q1 tokens in long-term vaults for many quarters before withdrawing, redeeming all payouts, and depositing the latest XAMPL tokens back in such vaults.",
        'migrated': '2023-01-01T00:00:00.000Z',
        'token': {
          'category':
              '978306aa4e02fd06e251b38d2e961f78f4af2ea6524a3e4531126776276a6af1',
          'decimals': 6,
          'symbol': 'XAMPL-23Q1'
        },
        'uris': {
          'icon': 'https://example.com/asset-icon-pending-payout.svg',
          'web': 'https://blog.example.com/payout-2023Q1'
        }
      }
    }
  },
  'license': 'CC0-1.0'
};
