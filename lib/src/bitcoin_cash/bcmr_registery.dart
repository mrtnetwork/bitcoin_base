/// A mapping of identifiers to URIs associated with an entity. URI identifiers
/// may be widely-standardized or registry-specific. Values must be valid URIs,
/// including a protocol prefix – e.g. `https://` or `ipfs://`., Clients are only
/// required to support `https` and `ipfs` URIs, but any scheme may be specified.
class URIs {
  const URIs(this.identifier);
  final Map<String, String> identifier;

  Map<String, dynamic> toJson() => Map<String, String>.from(identifier);
  factory URIs.fromJson(Map<String, dynamic> json) {
    return URIs(Map<String, String>.from(json));
  }
}

/// A mapping of extension identifiers to extension definitions. Extensions may
/// be widely standardized or application-specific, and extension definitions
/// must be either:
///
/// - `string`s,
/// - key-value mappings of `string`s, or
/// - two-dimensional, key-value mappings of `string`s.
///
/// This limitation encourages safety and wider compatibility across
/// implementations.
///
/// To encode an array, it is recommended that each value be assigned to a
/// numeric key indicating the item's index (beginning at `0`).
/// Numerically-indexed objects are often a more useful and resilient
/// data-transfer format than simple arrays because they simplify difference-only
/// transmission: only modified indexes need to be transferred, and shifts in
/// item order must be explicit, simplifying merges of conflicting updates.
///
/// For encoding of more complex data, consider using base64 and/or
/// string-encoded JSON.
class Extensions {
  const Extensions(this.identifier);
  final Map<String, dynamic> identifier;

  Map<String, dynamic> toJson() => Map<String, String>.from(identifier);
  factory Extensions.fromJson(Map<String, dynamic> json) {
    return Extensions(Map<String, dynamic>.from(json));
  }
}

/// Tags allow registries to classify and group identities by a variety of
/// characteristics. Tags are standardized within a registry and may represent
/// either labels applied by that registry or designations by external
/// authorities (certification, membership, ownership, etc.) that are tracked by
/// that registry.
///
/// Examples of possible tags include: `individual`, `organization`, `token`,
/// `wallet`, `exchange`, `staking`, `utility-token`, `security-token`,
/// `stablecoin`, `wrapped`, `collectable`, `deflationary`, `governance`,
/// `decentralized-exchange`, `liquidity-provider`, `sidechain`,
/// `sidechain-bridge`, `acme-audited`, `acme-endorsed`, etc.
///
/// Tags may be used by clients in search, discovery, and filtering of
/// identities, and they can also convey information like accreditation from
/// investor protection organizations, public certifications by security or
/// financial auditors, and other designations that signal integrity and value
/// to users.
class Tag {
  /// The name of this tag for use in interfaces.
  ///
  /// In user interfaces with limited space, names should be hidden beyond
  /// the first newline character or `20` characters until revealed by the user.
  ///
  /// E.g.:
  /// - `Individual`
  /// - `Token`
  /// - `Audited by ACME, Inc.`
  final String name;

  /// A string describing this tag for use in user interfaces.
  ///
  /// In user interfaces with limited space, descriptions should be hidden beyond
  /// the first newline character or `140` characters until revealed by the user.
  ///
  /// E.g.:
  /// - `An identity maintained by a single individual.`
  /// - `An identity representing a type of token.`
  /// - `An on-chain application that has passed security audits by ACME, Inc.`
  final String? description;

  /// A mapping of identifiers to URIs associated with this tag. URI identifiers
  /// may be widely-standardized or registry-specific. Values must be valid URIs,
  /// including a protocol prefix (e.g. `https://` or `ipfs://`). Clients are
  /// only required to support `https` and `ipfs` URIs, but any scheme may
  /// be specified.
  ///
  /// The following identifiers are recommended for all tags:
  /// - `icon`
  /// - `web`
  ///
  /// The following optional identifiers are standardized:
  /// - `blog`
  /// - `chat`
  /// - `forum`
  /// - `icon-intro`
  /// - `registry`
  /// - `support`
  ///
  /// For details on these standard identifiers, see:
  /// https://github.com/bitjson/chip-bcmr#uri-identifiers
  ///
  /// Custom URI identifiers allow for sharing social networking profiles, p2p
  /// connection information, and other application-specific URIs. Identifiers
  /// must be lowercase, alphanumeric strings, with no whitespace or special
  /// characters other than dashes (as a regular expression: `/^[-a-z0-9]+$/`).
  ///
  /// For example, some common identifiers include: `discord`, `docker`,
  /// `facebook`, `git`, `github`, `gitter`, `instagram`, `linkedin`, `matrix`,
  /// `npm`, `reddit`, `slack`, `substack`, `telegram`, `twitter`, `wechat`,
  /// `youtube`.
  final URIs? uris;

  /// A mapping of `Tag` extension identifiers to extension definitions.
  /// Extensions may be widely standardized or application-specific.
  final Extensions? extensions;

  const Tag({required this.name, this.description, this.uris, this.extensions});
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'],
      description: json['description'],
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'uris': uris?.toJson(),
        'extensions': extensions?.toJson(),
      }..removeWhere((key, value) => value == null);
}

/// A definition for one type of NFT within a token category.
class NftType {
  /// The name of this NFT type for use in interfaces. Names longer than `20`
  /// characters may be elided in some interfaces.
  ///
  /// E.g. `Market Order Buys`, `Limit Order Sales`, `Pledge Receipts`,
  /// `ACME Stadium Tickets`, `Sealed Votes`, etc.
  final String name;

  /// A string describing this NFT type for use in user interfaces.
  ///
  /// In user interfaces with limited space, names should be hidden beyond the
  /// first newline character or `140` characters until revealed by the user.
  ///
  /// E.g.:
  /// - "Receipts issued by the exchange to record details about purchases. After
  /// settlement, these receipts are redeemed for the purchased tokens.";
  /// - "Receipts issued by the crowdfunding campaign to document the value of
  /// funds pledged. If the user decides to cancel their pledge before the
  /// campaign completes, these receipts can be redeemed for a full refund.";
  /// - "Tickets issued for events at ACME Stadium.";
  /// - Sealed ballots certified by ACME decentralized organization during the
  /// voting period. After the voting period ends, these ballots must be revealed
  /// to reclaim the tokens used for voting."
  final String? description;

  /// A list of identifiers for fields contained in NFTs of this type. On
  /// successful parsing evaluations, the bottom item on the altstack indicates
  /// the matched NFT type, and the remaining altstack items represent NFT field
  /// contents in the order listed (where `fields[0]` is the second-to-bottom
  /// item, and the final item in `fields` is the top of the altstack).
  ///
  /// Fields should be ordered by recommended importance from most important to
  /// least important; in user interfaces, clients should display fields at lower
  /// indexes more prominently than those at higher indexes, e.g. if some fields
  /// cannot be displayed in minimized interfaces, higher-importance fields can
  /// still be represented. (Note, this ordering is controlled by the bytecode
  /// specified in `token.nft.parse.bytecode`.)
  ///
  /// If this is a sequential NFT, (the category's `parse.bytecode` is
  /// undefined), `fields` should be omitted or set to `undefined`.
  final List<String>? fields;

  /// A mapping of identifiers to URIs associated with this NFT type. URI
  /// identifiers may be widely-standardized or registry-specific. Values must be
  /// valid URIs, including a protocol prefix (e.g. `https://` or `ipfs://`).
  /// Clients are only required to support `https` and `ipfs` URIs, but any
  /// scheme may be specified.
  final URIs? uris;

  /// A mapping of NFT type extension identifiers to extension definitions.
  /// [Extensions] may be widely standardized or application-specific.
  final Extensions? extensions;
  factory NftType.fromJson(Map<String, dynamic> json) {
    return NftType(
      name: json['name'],
      description: json['description'],
      fields: json['fields'] == null ? null : List<String>.from(json['fields']),
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }
  const NftType(
      {required this.name,
      this.description,
      this.fields,
      this.uris,
      this.extensions});

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'fields': fields,
        'uris': uris?.toJson(),
        'extensions': extensions?.toJson(),
      }..removeWhere((key, value) => value == null);
}

class NftCategoryFieldType {
  /// The name of this field for use in interfaces. Names longer than `20`
  /// characters may be elided in some interfaces.
  ///
  /// E.g.:
  /// - `BCH Pledged`
  /// - `Tokens Sold`
  /// - `Settlement Locktime`
  /// - `Seat Number`,
  /// - `IPFS Content Identifier`
  /// - `HTTPS URL`
  final String? name;

  /// A string describing how this identity uses NFTs (for use in user
  /// interfaces). Descriptions longer than `160` characters may be elided in
  /// some interfaces.
  ///
  /// E.g.:
  /// - `The BCH value pledged at the time this receipt was issued.`
  /// - `The number of tokens sold in this order.`
  /// - `The seat number associated with this ticket.`
  final String? description;

  /// The expected encoding of this field when read from the parsing altstack
  /// (see [ParsableNftCollection]). All encoding definitions must have a
  /// `type`, and some encoding definitions allow for additional hinting about
  /// display strategies in clients.
  ///
  /// Encoding types may be set to `binary`, `boolean`, `hex`, `number`,
  /// or `utf8`:
  ///
  /// - `binary` types should be displayed as binary literals (e.g. `0b0101`)
  /// - `boolean` types should be displayed as `true` if exactly `0x01` or
  /// `false` if exactly `0x00`. If a boolean value does not match one of these
  /// values, clients should represent the NFT as unable to be parsed
  /// (e.g. simply display the full `commitment`).
  /// - `hex` types should be displayed as hex literals (e.g.`0xabcd`).
  /// - `https-url` types are percent encoded with the `https://` prefix
  /// omitted; they may be displayed as URIs or as activatable links.
  /// - `ipfs-cid` types are binary-encoded IPFS Content Identifiers; they may
  /// be displayed as URIs or as activatable links.
  /// - `locktime` types are `OP_TXLOCKTIME` results: integers from `0` to
  /// `4294967295` (inclusive) where values less than `500000000` are
  /// understood to be a block height (the current block number in the chain,
  /// beginning from block `0`), and values greater than or equal to
  /// `500000000` are understood to be a Median Time Past (BIP113) UNIX
  /// timestamp. (Note, sequence age is not currently supported.)
  /// - `number` types should be displayed according the their configured
  /// `decimals` and `unit` values.
  /// - `utf8` types should be displayed as utf8 strings.
  final dynamic encoding;

  /// A mapping of identifiers to URIs associated with this NFT field. URI
  /// identifiers may be widely-standardized or registry-specific. Values must
  /// be valid URIs, including a protocol prefix (e.g. `https://` or
  /// `ipfs://`). Clients are only required to support `https` and `ipfs` URIs,
  /// but any scheme may be specified.
  final URIs? uris;

  /// A mapping of NFT field extension identifiers to extension definitions.
  /// [Extensions] may be widely standardized or application-specific.
  final Extensions? extensions;

  factory NftCategoryFieldType.fromJson(Map<String, dynamic> json) {
    return NftCategoryFieldType(
      name: json['name'],
      description: json['description'],
      encoding: json['encoding'],
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }
  const NftCategoryFieldType({
    this.name,
    this.description,
    required this.encoding,
    this.uris,
    this.extensions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'encoding': encoding,
        'uris': uris?.toJson(),
        'extensions': extensions?.toJson(),
      }..removeWhere((key, value) => value == null);
}

/// A definition specifying a field that can be encoded in non-fungible tokens of
/// a token category.
class NftCategoryField {
  const NftCategoryField({required this.identifier});
  final Map<String, NftCategoryFieldType> identifier;
  factory NftCategoryField.fromJson(Map<String, dynamic> json) {
    final Map<String, NftCategoryFieldType> parsedIdentifier = {};
    json.forEach((key, value) {
      parsedIdentifier[key] = NftCategoryFieldType.fromJson(value);
    });

    return NftCategoryField(identifier: parsedIdentifier);
  }
  Map<String, dynamic> toJson() {
    return {for (final i in identifier.entries) i.key: i.value.toJson()};
  }
}

abstract class Parse {
  Map<String, dynamic> toJson();
  factory Parse.fromJson(Map<String, dynamic> json) {
    if (json['bytecode'] != null) {
      return ParsableNftCollection.fromJson(json);
    }
    return SequentialNftCollection.fromJson(json);
  }
}

/// Interpretation information for a collection of sequential NFTs, a collection
/// in which each NFT includes only a sequential identifier within its on-chain
/// commitment. Note that [SequentialNftCollection]s differ from
/// [ParsableNftCollection]s in that sequential collections lack a
/// parsing `bytecode` with which to inspect each NFT commitment: the type of
/// each NFT is indexed by the full contents its commitment (interpreted as a
/// positive VM integer in user interfaces).
class SequentialNftCollection implements Parse {
  const SequentialNftCollection({required this.types});

  /// A mapping of each NFT commitment (typically, a positive integer encoded as
  /// a VM number) to metadata for that NFT type in this category.
  final Map<String, NftType> types;
  factory SequentialNftCollection.fromJson(Map<String, dynamic> json) {
    return SequentialNftCollection(
      types: Map<String, dynamic>.from(json['types'])
          .map((key, value) => MapEntry(key, NftType.fromJson(value))),
    );
  }
  @override
  Map<String, dynamic> toJson() => {
        'types': {for (final i in types.entries) i.key: i.value.toJson()}
      };
}

/// Interpretation information for a collection of parsable NFTs, a collection
/// in which each NFT may include additional metadata fields beyond a sequential
/// identifier within its on-chain commitment. Note that
/// [ParsableNftCollection]s differ from [SequentialNftCollection]s
/// in that parsable collections require a parsing `bytecode` with which to
/// inspect each NFT commitment: the type of each NFT is indexed by the
/// hex-encoded contents the bottom item on the altstack following the evaluation
/// of the parsing bytecode.
class ParsableNftCollection implements Parse {
  /// A segment of hex-encoded Bitcoin Cash VM bytecode that parses UTXOs
  /// holding NFTs of this category, identifies the NFT's type within the
  /// category, and returns a list of the NFT's field values via the
  /// altstack. If undefined, this NFT Category includes only sequential NFTs,
  /// with only an identifier and no NFT fields encoded in each NFT's
  /// on-chain commitment.
  ///
  /// The parse `bytecode` is evaluated by instantiating and partially
  /// verifying a standardized NFT parsing transaction:
  /// - version: `2`
  /// - inputs:
  ///   - 0: Spends the UTXO containing the NFT with an empty
  ///   unlocking bytecode and sequence number of `0`.
  ///   - 1: Spends index `0` of the empty hash outpoint, with locking
  ///   bytecode set to `parse.bytecode`, unlocking bytecode `OP_1`
  ///   (`0x51`) and sequence number `0`.
  /// - outputs:
  ///   - 0: A locking bytecode of OP_RETURN (`0x6a`) and value of `0`.
  /// - locktime: `0`
  ///
  /// After input 1 of this NFT parsing transaction is evaluated, if the
  /// resulting stack is not valid (a single "truthy" element remaining on
  /// the stack) – or if the altstack is empty – parsing has failed and
  /// clients should represent the NFT as unable to be parsed (e.g. simply
  /// display the full `commitment` as a hex-encoded value in the user
  /// interface).
  ///
  /// On successful parsing evaluations, the bottom item on the altstack
  /// indicates the type of the NFT according to the matching definition in
  /// `types`. If no match is found, clients should represent the NFT as
  /// unable to be parsed.
  ///
  /// For example: `00d2517f7c6b` (OP_0 OP_UTXOTOKENCOMMITMENT OP_1 OP_SPLIT
  /// OP_SWAP OP_TOALTSTACK OP_TOALTSTACK) splits the commitment after 1 byte,
  /// pushing the first byte to the altstack as an NFT type identifier and the
  /// remaining segment of the commitment as the first NFT field value.
  ///
  /// If undefined (in a [SequentialNftCollection]), this field could be
  /// considered to have a default value of `00d26b` (OP_0 OP_UTXOTOKENCOMMITMENT
  /// OP_TOALTSTACK), which takes the full contents of the commitment as a fixed
  /// type index. As such, each index of the NFT category's `types` maps a
  /// precise commitment value to the metadata for NFTs with that particular
  /// commitment. E.g. an NFT with an empty commitment (VM number 0) maps to
  /// `types['']`, a commitment of `01` (hex) maps to `types['01']`, etc. This
  /// pattern is used for collections of sequential NFTs.
  final String bytecode;

  /// A mapping of hex-encoded values to definitions of possible NFT types
  /// in this category.
  final Map<String, NftType> types;
  factory ParsableNftCollection.fromJson(Map<String, dynamic> json) {
    return ParsableNftCollection(
      bytecode: json['bytecode'],
      types: Map<String, dynamic>.from(json['types'])
          .map((key, value) => MapEntry(key, NftType.fromJson(value))),
    );
  }
  const ParsableNftCollection({required this.bytecode, required this.types});

  @override
  Map<String, dynamic> toJson() => {
        'bytecode': bytecode,
        'types': {for (final i in types.entries) i.key: i.value.toJson()}
      };
}

/// A definition specifying the non-fungible token information for a
/// token category.
class NftCategory {
  const NftCategory({this.description, this.fields, this.parse});

  /// A string describing how this identity uses NFTs (for use in user
  /// interfaces). Descriptions longer than `160` characters may be elided in
  /// some interfaces.
  ///
  /// E.g.:
  /// - "ACME DEX NFT order receipts are issued when you place orders on the
  /// decentralized exchange. After orders are processed, order receipts can
  /// be redeemed for purchased tokens or sales proceeds.";
  /// - "ACME Game collectable NFTs unlock unique playable content, user
  /// avatars, and item skins in ACME Game Online."; etc.
  final String? description;

  /// A mapping of field identifier to field definitions for the data fields
  /// that can appear in NFT commitments of this category.
  ///
  /// Categories including only sequential NFTs (where `parse.bytecode` is
  /// undefined) should omit `fields` (or set to `undefined`).
  final NftCategoryField? fields;

  /// Parsing and interpretation information for all NFTs of this category;
  /// this enables generalized wallets to parse and display detailed
  /// information about all NFTs held by the wallet, e.g. `BCH Pledged`,
  /// `Order Price`, `Seat Number`, `Asset Number`,
  /// `IPFS Content Identifier`, `HTTPS URL`, etc.
  ///
  /// Parsing instructions are provided in the `bytecode` property, and the
  /// results are interpreted using the `types` property.
  final Parse? parse;
  factory NftCategory.fromJson(Map<String, dynamic> json) {
    return NftCategory(
      description: json['description'],
      fields: json['fields'] != null
          ? NftCategoryField.fromJson(json['fields'])
          : null,
      parse: json['parse'] != null ? Parse.fromJson(json['parse']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'fields': fields?.toJson(),
        'parse': parse?.toJson(),
      }..removeWhere((key, value) => value == null);
}

/// A definition specifying information about an identity's token category.
class TokenCategory {
  /// The current token category used by this identity. Often, this will be
  /// equal to the identity's authbase, but some token identities must migrate
  /// to new categories for technical reasons.
  final String category;

  /// An abbreviation used to uniquely identity this token category.
  ///
  /// Symbols must be comprised only of capital letters, numbers, and dashes
  /// (`-`). This can be validated with the regular expression:
  /// `/^[-A-Z0-9]+$/`.
  final String symbol;

  /// An integer between `0` and `18` (inclusive) indicating the divisibility
  /// of the primary unit of this token category.
  ///
  /// This is the number of digits that can appear after the decimal separator
  /// in fungible token amounts. For a token category with a `symbol` of
  /// `SYMBOL` and a `decimals` of `2`, a fungible token amount of `12345`
  /// should be displayed as `123.45 SYMBOL`.
  ///
  /// If omitted, defaults to `0`.
  final int? decimals;

  /// Display information for non-fungible tokens (NFTs) of this identity.
  /// Omitted for token categories without NFTs.
  final NftCategory? nfts;
  factory TokenCategory.fromJson(Map<String, dynamic> json) {
    return TokenCategory(
      category: json['category'],
      symbol: json['symbol'],
      decimals: json['decimals'],
      nfts: json['nfts'] != null ? NftCategory.fromJson(json['nfts']) : null,
    );
  }

  const TokenCategory(
      {required this.category, required this.symbol, this.decimals, this.nfts});

  Map<String, dynamic> toJson() => {
        'category': category,
        'decimals': decimals,
        'symbol': symbol,
        'nfts': nfts?.toJson(),
      }..removeWhere((key, value) => value == null);
}

/// A snapshot of the metadata for a particular identity at a specific time.
class IdentitySnapshot {
  /// The name of this identity for use in interfaces.
  ///
  /// In user interfaces with limited space, names should be hidden beyond
  /// the first newline character or `20` characters until revealed by the user.
  ///
  /// E.g. `ACME Class A Shares`, `ACME Registry`, `Satoshi Nakamoto`, etc.
  final String name;

  /// A string describing this identity for use in user interfaces.
  ///
  /// In user interfaces with limited space, descriptions should be hidden beyond
  /// the first newline character or `140` characters until revealed by the user.
  ///
  /// E.g.:
  /// - `The common stock issued by ACME, Inc.`
  /// - `A metadata registry maintained by Company Name, the embedded registry for Wallet Name.`
  /// - `Software developer and lead maintainer of Wallet Name.`
  final String? description;

  /// An array of `Tag` identifiers marking the `Tag`s associated with this
  /// identity. All specified tag identifiers must be defined in the registry's
  /// `tags` mapping.
  final List<String>? tags;

  /// The timestamp at which this identity snapshot is fully in effect. This
  /// value should only be provided if the snapshot takes effect over a period
  /// of time (e.g. an in-circulation token identity is gradually migrating to
  /// a new category). In these cases, clients should gradually migrate to
  /// using the new information beginning after the identity snapshot's timestamp
  /// and the `migrated` time.
  ///
  /// This timestamp must be provided in simplified extended ISO 8601 format, a
  /// 24-character string of format `YYYY-MM-DDTHH:mm:ss.sssZ` where timezone is
  /// zero UTC (denoted by `Z`). Note, this is the format returned by ECMAScript
  /// `Date.toISOString()`.
  final String? migrated;

  /// If this identity is a type of token, a data structure indicating how tokens
  /// should be understood and displayed in user interfaces. Omitted for
  /// non-token identities.
  final TokenCategory? token;

  /// The status of this identity, must be `active`, `inactive`, or `burned`. If
  /// omitted, defaults to `active`.
  /// - Identities with an `active` status should be actively tracked by clients.
  /// - Identities with an `inactive` status may be considered for archival by
  /// clients and may be removed in future registry versions.
  /// - Identities with a `burned` status have been destroyed by setting the
  /// latest identity output to a data-carrier output (`OP_RETURN`), permanently
  /// terminating the authchain. Clients should archive burned identities and –
  /// if the burned identity represented a token type – consider burning any
  /// remaining tokens of that category to reclaim funds from those outputs.
  final String? status;

  /// The split ID of this identity's chain of record.
  ///
  /// If undefined, defaults to [Registry.defaultChain].
  final String? splitId;

  /// A mapping of identifiers to URIs associated with this identity. URI
  /// identifiers may be widely-standardized or registry-specific. Values must be
  /// valid URIs, including a protocol prefix (e.g. `https://` or `ipfs://`).
  /// Clients are only required to support `https` and `ipfs` URIs, but any
  /// scheme may be specified.
  ///
  /// The following identifiers are recommended for all identities:
  /// - `icon`
  /// - `web`
  ///
  /// The following optional identifiers are standardized:
  /// - `blog`
  /// - `chat`
  /// - `forum`
  /// - `icon-intro`
  /// - `image`
  /// - `migrate`
  /// - `registry`
  /// - `support`
  ///
  /// For details on these standard identifiers, see:
  /// https://github.com/bitjson/chip-bcmr#uri-identifiers
  ///
  /// Custom URI identifiers allow for sharing social networking profiles, p2p
  /// connection information, and other application-specific URIs. Identifiers
  /// must be lowercase, alphanumeric strings, with no whitespace or special
  /// characters other than dashes (as a regular expression: `/^[-a-z0-9]+$/`).
  ///
  /// For example, some common identifiers include: `discord`, `docker`,
  /// `facebook`, `git`, `github`, `gitter`, `instagram`, `linkedin`, `matrix`,
  /// `npm`, `reddit`, `slack`, `substack`, `telegram`, `twitter`, `wechat`,
  /// `youtube`.
  final URIs? uris;

  /// A mapping of `IdentitySnapshot` extension identifiers to extension
  /// definitions. [Extensions] may be widely standardized or
  /// application-specific.
  ///
  /// Standardized extensions for `IdentitySnapshot`s include the `authchain`
  /// extension. See
  /// https://github.com/bitjson/chip-bcmr#authchain-extension for details.
  final Extensions? extensions;
  factory IdentitySnapshot.fromJson(Map<String, dynamic> json) {
    return IdentitySnapshot(
      name: json['name'],
      description: json['description'],
      tags: json['tags'] == null ? null : List<String>.from(json['tags']),
      migrated: json['migrated'],
      token:
          json['token'] != null ? TokenCategory.fromJson(json['token']) : null,
      status: json['status'],
      splitId: json['splitId'],
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }

  const IdentitySnapshot({
    required this.name,
    this.description,
    this.tags,
    this.migrated,
    this.token,
    this.status,
    this.splitId,
    this.uris,
    this.extensions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'tags': tags,
        'migrated': migrated,
        'token': token?.toJson(),
        'status': status,
        'splitId': splitId,
        'uris': uris?.toJson(),
        'extensions': extensions?.toJson(),
      }..removeWhere((key, value) => value == null);
}

/// A snapshot of the metadata for a particular chain/network at a specific
/// time. This allows for registries to provide similar metadata for each chain's
/// native currency unit (name, description, symbol, icon, etc.) as can be
/// provided for other registered tokens.
class ChainSnapshot extends IdentitySnapshot {
  factory ChainSnapshot.fromJson(Map<String, dynamic> json) {
    return ChainSnapshot(
      name: json['name'],
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      migrated: json['migrated'],
      token: TokenCategory.fromJson(json['token']),
      status: json['status'],
      splitId: json['splitId'],
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }
  const ChainSnapshot({
    required String name,
    required TokenCategory token,
    String? description,
    List<String>? tags,
    String? migrated,
    String? status,
    String? splitId,
    URIs? uris,
    Extensions? extensions,
  }) : super(
          name: name,
          description: description,
          tags: tags,
          migrated: migrated,
          token: token,
          status: status,
          splitId: splitId,
          uris: uris,
          extensions: extensions,
        );
}

class RegistryTimestampKeyedValues<T extends IdentitySnapshot> {
  const RegistryTimestampKeyedValues({required this.timestampMap});

  final Map<String, T> timestampMap;

  Map<String, dynamic> toJson() =>
      {for (final i in timestampMap.entries) i.key: i.value.toJson()};
}

class ChainHistory extends RegistryTimestampKeyedValues<ChainSnapshot> {
  const ChainHistory({required Map<String, ChainSnapshot> timestampMap})
      : super(timestampMap: timestampMap);

  factory ChainHistory.fromJson(Map<String, dynamic> json) {
    return ChainHistory(
      timestampMap: json.map(
        (key, value) => MapEntry(key, ChainSnapshot.fromJson(value)),
      ),
    );
  }
}

class IdentityHistory extends RegistryTimestampKeyedValues<IdentitySnapshot> {
  const IdentityHistory({required Map<String, IdentitySnapshot> timestampMap})
      : super(timestampMap: timestampMap);

  factory IdentityHistory.fromJson(Map<String, dynamic> json) {
    return IdentityHistory(
      timestampMap: json.map(
        (key, value) => MapEntry(key, IdentitySnapshot.fromJson(value)),
      ),
    );
  }
}

class OffChainRegistryIdentity {
  final String name;
  final String? description;
  final URIs? uris;
  final List<String>? tags;
  final Extensions? extensions;

  const OffChainRegistryIdentity({
    required this.name,
    this.description,
    this.uris,
    this.tags,
    this.extensions,
  });

  factory OffChainRegistryIdentity.fromJson(Map<String, dynamic> json) {
    return OffChainRegistryIdentity(
      name: json['name'],
      description: json['description'],
      uris: json['uris'] != null ? URIs.fromJson(json['uris']) : null,
      tags: json['tags'] == null ? null : List<String>.from(json['tags']),
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'uris': uris?.toJson(),
        'tags': tags,
        'extensions': extensions?.toJson(),
      }..removeWhere((key, value) => value == null);
}

class Version {
  const Version(
      {required this.major, required this.minor, required this.patch});

  final int major;
  final int minor;
  final int patch;

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      major: json['major'],
      minor: json['minor'],
      patch: json['patch'],
    );
  }

  Map<String, int> toJson() {
    return {'major': major, 'minor': minor, 'patch': patch};
  }
}

class Registry {
  /// The schema used by this registry. Many JSON editors can automatically
  /// provide inline documentation and autocomplete support using the `$schema`
  /// property, so it is recommended that registries include it. E.g.:
  /// `https://cashtokens.org/bcmr-v2.schema.json`
  final String? schema;

  /// The version of this registry. Versioning adheres to Semantic Versioning
  /// (https://semver.org/).
  final Version version;

  /// The timestamp of the latest revision made to this registry version. The
  /// timestamp must be provided in simplified extended ISO 8601 format, a
  /// 24-character string of format `YYYY-MM-DDTHH:mm:ss.sssZ` where timezone is
  /// zero UTC (denoted by `Z`). Note, this is the format returned by ECMAScript
  /// `Date.toISOString()`.
  final String latestRevision;

  /// The identity information of this particular registry, provided as either an
  /// authbase (recommended) or an `IdentitySnapshot`.
  ///
  /// An authbase is a 32-byte, hex-encoded transaction hash (A.K.A. TXID) for
  /// which the zeroth-descendant transaction chain (ZDTC) authenticates and
  /// publishes all registry updates. If an authbase is provided, the registry's
  /// identity information can be found in `identities[authbase]`, and clients
  /// should immediately attempt to verify the registry's identity on-chain.
  /// (See https://github.com/bitjson/chip-bcmr#chain-resolved-registries)
  ///
  /// If an `IdentitySnapshot` is provided directly, this registry does not
  /// support on-chain resolution/authentication, and the contained
  /// `IdentitySnapshot` can only be authenticated via DNS/HTTPS.
  final dynamic registryIdentity;

  /// A mapping of authbases to the `IdentityHistory` for that identity.
  ///
  /// An authbase is a 32-byte, hex-encoded transaction hash (A.K.A. TXID) for
  /// which the zeroth-descendant transaction chain (ZDTC) authenticates and
  /// publishes an identity's claimed metadata.
  ///
  /// Identities may represent metadata registries, specific types of tokens,
  /// companies, organizations, individuals, or other on-chain entities.
  final Map<String, IdentityHistory>? identities;

  /// A map of registry-specific `Tag`s used by this registry to convey
  /// information about identities it tracks.
  ///
  /// Tags allow registries to group identities into collections of related
  /// identities, marking characteristics or those identities. Tags are
  /// standardized within a registry and may represent either labels applied by
  /// that registry (e.g. `individual`, `organization`, `token`, `wallet`,
  /// `exchange`, `staking`, `utility-token`, `security-token`, `stablecoin`,
  /// `wrapped`, `collectable`, `deflationary`, `governance`,
  /// `decentralized-exchange`, `liquidity-provider`, `sidechain`,
  /// `sidechain-bridge`, etc.) or designations by external authorities
  /// (certification, membership, ownership, etc.) that are tracked by
  /// that registry.
  ///
  /// Tags may be used by clients in search, discover, and filtering of
  /// identities, and they can also convey information like accreditation from
  /// investor protection organizations, public certifications by security or
  /// financial auditors, and other designations that signal legitimacy and value
  /// to users.
  final Map<String, Tag>? tags;

  /// The split ID of the chain/network considered the "default" chain for this
  /// registry. Identities that do not specify a [IdentitySnapshot.splitId]
  /// are assumed to be set to this split ID. For a description of split IDs,
  /// see [Registry.chains].
  ///
  /// If not provided, the `defaultChain` is
  /// `0000000000000000029e471c41818d24b8b74c911071c4ef0b4a0509f9b5a8ce`, the BCH
  /// side of the BCH/XEC split (mainnet). Common values include:
  /// - `00000000ae25e85d9e22cd6c8d72c2f5d4b0222289d801b7f633aeae3f8c6367`
  /// (testnet4)
  /// - `00000000040ba9641ba98a37b2e5ceead38e4e2930ac8f145c8094f94c708727`
  /// (chipnet)
  final String? defaultChain;

  /// A map of split IDs tracked by this registry to the [ChainHistory] for
  /// that chain/network.
  ///
  /// The split ID of a chain is the block header hash (A.K.A. block ID) of the
  /// first unique block after the most recent tracked split – a split after
  /// which both resulting chains are considered notable or tracked by the
  /// registry. (For chains with no such splits, this is the ID of the
  /// genesis block.)
  ///
  /// Note, split ID is inherently a "relative" identifier. After a tracked
  /// split, both resulting chains will have a new split ID. However, if a wallet
  /// has not yet heard about a particular split, that wallet will continue to
  /// reference one of the resulting chains by its previous split ID, and the
  /// split-unaware wallet may create transactions that are valid on both chains
  /// (losing claimable value if the receivers of their transactions don't
  /// acknowledge transfers on both chains). When a registry trusted by the
  /// wallet notes the split in it's `chains` map, the wallet can represent the
  /// split in the user interface using the the latest [ChainSnapshot] for
  /// each chain and splitting coins prior to spending (by introducing post-split
  /// coins in each transaction).
  ///
  /// This map may exclude the following well-known split IDs (all clients
  /// supporting any of these chains should build-in [ChainHistory] for
  /// those chains):
  ///
  /// - `0000000000000000029e471c41818d24b8b74c911071c4ef0b4a0509f9b5a8ce`:
  ///   A.K.A. mainnet – the BCH side of the BCH/XEC split.
  /// - `00000000ae25e85d9e22cd6c8d72c2f5d4b0222289d801b7f633aeae3f8c6367`:
  ///   A.K.A testnet4 – the test network on which CHIPs are activated
  ///   simultaneously with mainnet (May 15 at 12 UTC).
  /// - `00000000040ba9641ba98a37b2e5ceead38e4e2930ac8f145c8094f94c708727`:
  ///   A.K.A. chipnet – the test network on which CHIPs are activated 6 months
  ///   before mainnet (November 15 at 12 UTC).
  ///
  /// All other split IDs referenced by this registry should be included in this
  /// map.
  final Map<String, ChainHistory>? chains;

  /// The license under which this registry is published. This may be specified
  /// as either a SPDX short identifier (https://spdx.org/licenses/) or by
  /// including the full text of the license.
  ///
  /// Common values include:
  ///  - `CC0-1.0`: https://creativecommons.org/publicdomain/zero/1.0/
  ///  - `MIT`: https://opensource.org/licenses/MIT
  final String? license;

  /// A mapping of `Registry` extension identifiers to extension definitions.
  /// [Extensions] may be widely standardized or application-specific.
  ///
  /// Standardized extensions for `Registry`s include the `locale` extension. See
  /// https://github.com/bitjson/chip-bcmr#locales-extension for details.
  final Extensions? extensions;
  factory Registry.fromJson(Map<String, dynamic> json) {
    return Registry(
      schema: json[r'$schema'],
      version: Version.fromJson(json['version']),
      latestRevision: json['latestRevision'],
      registryIdentity: json['registryIdentity'] != null
          ? OffChainRegistryIdentity.fromJson(json['registryIdentity'])
          : json['registryIdentity'],
      defaultChain: json['defaultChain'],
      license: json['license'],
      extensions: json['extensions'] != null
          ? Extensions.fromJson(json['extensions'])
          : null,
      identities: json['identities'] != null
          ? (json['identities'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, IdentityHistory.fromJson(value)),
            )
          : null,
      chains: json['chains'] != null
          ? (json['chains'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, ChainHistory.fromJson(value)),
            )
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, Tag.fromJson(value)),
            )
          : null,
    );
  }
  const Registry({
    this.schema,
    required this.version,
    required this.latestRevision,
    required this.registryIdentity,
    this.identities,
    this.tags,
    this.defaultChain,
    this.chains,
    this.license,
    this.extensions,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> js = {
      r'$schema': schema,
      'version': version.toJson(),
      'latestRevision': latestRevision,
      'registryIdentity': registryIdentity is OffChainRegistryIdentity
          ? (registryIdentity as OffChainRegistryIdentity).toJson()
          : registryIdentity,
      'identities': null,
      'defaultChain': defaultChain,
      'license': license,
      'extensions': extensions?.toJson(),
    };
    if (identities != null) {
      final jsIdentities = {};
      for (final i in identities!.entries) {
        jsIdentities[i.key] = i.value.toJson();
      }
      js["identities"] = jsIdentities;
    }
    if (chains != null) {
      final jsChains = {};
      for (final i in chains!.entries) {
        jsChains[i.key] = i.value.toJson();
      }
      js["chains"] = jsChains;
    }
    if (tags != null) {
      final jsTags = {};
      for (final i in tags!.entries) {
        jsTags[i.key] = i.value.toJson();
      }
      js["tags"] = jsTags;
    }
    return js..removeWhere((key, value) => value == null);
  }
}
