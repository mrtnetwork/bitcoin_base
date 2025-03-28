import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:test/test.dart';

void main() {
  _decodeTx();
}

void _decodeTx() {
  test('decode transaction', () {
    const data =
        '020000000186389e3142effb82e00d38abc93ef856e543221ca6dd7d916760e0cda49f059300000000fd57030047304402204335c0185a9277c531315d0cd6c83bbe8d60d39f1b93864d9a4e67c8cccb400802207813732324a0cccf3989b4c56554bf06eaeea9175557525532926de939cfac3c414730440220515367fed3284a5469489c27fc7ea1915e7a07a939fb56d2188e5a27813b87690220578a491532d4bc84756fb489c2a5093b9f6884cfe852f2b469a89c7e35482ac0414730440220594f4cf6da2c88e430d1cc00d3b9b47b2936a9c4121be1c0e2e3b634e060c58202202c340707cc66aa27bd8fe40d9993751a0efa805b021f861fad460343b2826d4841473044022001c8e211117d20ecd3b3d7359e96485015303b4f55ba3039e40f1e035d867c2f02203c43c3e3f48a8215cb99a22b95d4d99defed9e385dbbacc4501c9c6fbc7db50141473044022000e95343e11b6765aa823c58c4fd1b78495b0a29f3fb428886ce858850827e6d02206bb967529a3289397e7c0482c063d872bc839306940b9e36e35457d840f2bfef4147304402200475c3a062644cf26269c91524cece25ff95cde8cbf52c7f180c1f7e45092fcf02207c4f4449aa69de7e8ae5825375825f5175462766e17bd1d7f96b5096f2d6ae004147304402201339113915d56209270d3be2c91ca0c04392db726a4909026924cce6236444310220476c5c6a8cdb6f973b62dad12b95a651269ad74cf767d5100d88ea98309ff9c4414730440220628dcdc3b1ed6e85d6df25c976fa09488b73e1d81f4ef80d02fcbfd852fd88a00220264ba1fc4fc6d92246f3a3511f76871954aee360c7e2e407dc317736fe910df6414d1301582102b509e03e5773ad6864d037eb1c8f9e9c39698bc5b59272d7f2156da2070d810f210369cc1b70ded5caf25b42b59ae13bdbee386e5dcaa0612a2a258dec02364040682103d850292f0e06a8e64c569a23cb310d192d4ad1b145c7050c6cb23bd9e8a4310421024fa5bd6af09db2740c39ec3e795eab200f091029b65d9013f7d3b52eb1cbc6e0210205a9f0be6d7f598c9a3b06cca6223705b49a43f5de5401eef93ee8c48ddf34b42103aaf256cb145aef9bea0bad969ca498108da7a3ad6da7cdeadcbcade2aa64fcea2103cb2ce8e4c87f7a6184abb30bf21cfb987634959f67bf20336d4208f4d7d62ac52103515a9b03688488850dd184e9229cb43634c1a39e2ccc5b8f2cf2c0a8cebb92e858aeffffffff0284030000000000001976a914e54b088d7f501604b1d85ed9d30f46b5db721ac288acc71c00000000000017a91492b98234f58410b0cea227d6e7e60ec08aa8547e8700000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
  test('decode transaction 2', () {
    const data =
        '0200000000010b78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d356470000000000ffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d356470100000000ffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d3564702000000484730440220759a2beb31cbc0bfb30ad3cff3f3c84869b6549984ac8f5413bae19b0fed3aed022036718ddc6bbd7c7921d922fe90e7786ef67818208e268507dea99c782a578e1301ffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d356470300000000ffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d35647040000008a47304402202846a5ca5766a4ef0246e59cf11bfd0a182b5ce4fe366e43480df48efe92465f022005a47fdbefa0aa971d8804606362866bcf6d0c2bf8e4ecd0c31d04e7e28d4b7e0141042f1b310f4c065331bc0d79ba4661bb9822d67d7c4a1b0a1892e1fd0cd23aa68d2518d05511d46fc76b5bd2f94625b811df220f825786208cc5b5cca23de230ccffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d3564705000000a447304402203cdbff5392666f0d5bd364c9b83053e3b7508727102cba2f2110136359fd717402205069298f860fbd84f9b60466535c9ca226d92eaf9bf298c97df7f20b758248590141041a7a569e91dbf60581509c7fc946d1003b60c7dee85299538db6353538d59574b4e89d60c7d584d084632d296f125f165b4df8e061a49daeba51d36133d03e1a1976a914c880e94561d70cb61f2108deff2f1a6c10fff6a488acffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d3564706000000a447304402202e5f50e724c564dd1dde5cbad5ed87a803beb1b3f0a1401f3d5ee4a7e1ec9ed2022005efbc073f4862625923c68ac15a830b00f01a7e40fdebe7979528782a8c64180141041a7a569e91dbf60581509c7fc946d1003b60c7dee85299538db6353538d59574b4e89d60c7d584d084632d296f125f165b4df8e061a49daeba51d36133d03e1a1976a914c880e94561d70cb61f2108deff2f1a6c10fff6a488acffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d3564707000000232200209e7470b3013d2e9585f2009241f223beaefc8067f82a2a6f2dd87d74cb5969dbffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d35647080000008c473044022013608955698454f9eff9708cb98f2ff97d3a4d4ab9f8a80996d57a861ae712970220347ad5bca2e6773fb1fc817cd12bac451cfedae8f024e67e8fac905eaa2601370143410499c2aa85d2b21a62f396907a802a58e521dafd5bddaccbd72786eea189bc4dc9c40c3728b587c47395ce41a2afe84ee70016fafa39d3b54e66fc1f11aefda704acffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d3564709000000fd410400473044022062c412f612e08ed3cf5ce5aba3c8e556849a2ffdded9814525393bd4b61c76890220638557c4426a83012b0cf31fccd395c9a063f01942dcdadf5c86b174fceaffbe0147304402206bec40f5bb548e6f0e2c8b6ffe24d1173f60b1ebb0a870cef941e8499d34c9ae02204206d61ecdfd2aa0a300f91dafd9e7399f22bee9298d56d972e0d58e366977fe01473044022050f449a88e32850924a1d19ab9b82f676d2859ec38765d13b0a08902eb8bb95b02203c1bbc81ad3af940470cd100e4bf59bd92570d0dc8b76bf6196a90c8a528520a0147304402205e8e6937d25e139762ca57d4e4777e28bbd730cde2cd72d16b7f73eca04df84d022011141ef7b64b3b10ae9fc1c78c73453c1855ff997c05b2aed56ee24ee53a789f01473044022046c8000f5c97f5e8b388e6294db4ebd8cb45f4c58f844003ed571ee8b5965a6e02202f2880e91746bcf240a6cf1945de81016f6c46cb95265e67289611e1eaaffbd00147304402204610acecbda4763c3d7bcf3e656a1cdb1f0e6286dff755b36640c52d5153011b0220785bb66ff9e36d9de663379d520858d340c66845c3f9c7b4bfd4843bf6c2fc0f01473044022007c91bb30021f4b2d84ca5cc18458aeb6ee96d9d5881d09a37af845524d3ff10022068ffdca9828bc4648cdb954bd76436b373a3da07c376452325e52a01075e7b2201473044022007c91bb30021f4b2d84ca5cc18458aeb6ee96d9d5881d09a37af845524d3ff10022068ffdca9828bc4648cdb954bd76436b373a3da07c376452325e52a01075e7b2201473044022007c91bb30021f4b2d84ca5cc18458aeb6ee96d9d5881d09a37af845524d3ff10022068ffdca9828bc4648cdb954bd76436b373a3da07c376452325e52a01075e7b22014db5015941040f0fb9a244ad31a369ee02b7abfbbb0bfa3812b9a39ed93346d03d67d412d1777965c382f55222a9aed59cb8affc64bb5381f065eab9ef3baa57f2f0ac6bfae921022f1b310f4c065331bc0d79ba4661bb9822d67d7c4a1b0a1892e1fd0cd23aa68d210299c2aa85d2b21a62f396907a802a58e521dafd5bddaccbd72786eea189bc4dc921021a7a569e91dbf60581509c7fc946d1003b60c7dee85299538db6353538d595742103a92c9b7cac68758de5783ed8e5123598e4ad137091e42987d3bad8a08e35bf3d21034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa41046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7eb1c2784a65901538479361e94c0a2597973adef0836a6a7eddf50b7997c88a341046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7eb1c2784a65901538479361e94c0a2597973adef0836a6a7eddf50b7997c88a341046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f7eb1c2784a65901538479361e94c0a2597973adef0836a6a7eddf50b7997c88a359aeffffffff78c2ebf52b849090b70ba2bb3ec4a4447037ab41e56781f44f7cae3d82d356470a000000484730440220028b766844f8d4e5c28b2464605dfa79435c9203481976db468517ca96674b320220761f5687ce7d6067ba3cbe652e11b8495ac274b5ce0e7f1b8f59b2c34f007bf701ffffffff0be803000000000000160014b4bd9b543a615fe9b73ced34a9a38572ae18a395e8030000000000002200209e7470b3013d2e9585f2009241f223beaefc8067f82a2a6f2dd87d74cb5969dbe8030000000000004341040f0fb9a244ad31a369ee02b7abfbbb0bfa3812b9a39ed93346d03d67d412d1777965c382f55222a9aed59cb8affc64bb5381f065eab9ef3baa57f2f0ac6bfae9ace80300000000000022512039d1075e641ac7deda75bfbfa28aa5c65d7f39b1315e024f62e1064b1ec71d3ee8030000000000001976a914f9c4fccde68b163563e0d60842d1accd19c1207b88ace80300000000000017a91454db4f9a5c6f2de3110925e1f8cf42aeab807e6687e80300000000000017a91454db4f9a5c6f2de3110925e1f8cf42aeab807e6687e80300000000000017a914baf6af81b991265c3e3223f4649cf1b21afa73b987e80300000000000017a914c95d7440311017931c7adb20ab103e116e17ccbb87e80300000000000017a914d6215d5c57d6d65ae73eb0d8fe2ad7cfa07d441f879ba80000000000004341040f0fb9a244ad31a369ee02b7abfbbb0bfa3812b9a39ed93346d03d67d412d1777965c382f55222a9aed59cb8affc64bb5381f065eab9ef3baa57f2f0ac6bfae9ac02473044022044cd5a0eca8585d1dfb183dc12b37bfb41308244540d6a6ba449b6663f85f5e402206221b9980ecc54538e249a1c01972c6198c150945d12b6d124ebe523bd7bd2c30121021a7a569e91dbf60581509c7fc946d1003b60c7dee85299538db6353538d595740300473044022010b9f2310bc25214db7508df0107c8683c7c2f3eabb60aad2c35bed84d516159022059a643ad81a966716db06a2d707fefb234bffcac975ece1bc4b900239b50b7e501255121031d16453b3ab3132acb0a5bc16cc49690d819a585267a15cd5a064e2a0ad4059951ae000140daf8270bffc7a39c45114f5b180f5f82bc920803f3a612a4b517ce609e7e4ef30d8939102af08c9407f0cc4f9c63ffdda9914634dc59b1786d6d6b9d1b8a31960000000300473044022058f436dd9dc7d2966cd44a52989c972fb67e017d02e08723293fcfc4a3da3bff02200f8ff1bb6a95709ed5cfc47e9f567cba1fca8c9c10cd2db4f348152b3420361001255121031d16453b3ab3132acb0a5bc16cc49690d819a585267a15cd5a064e2a0ad4059951ae00000000000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('decode transaction v1', () {
    const data =
        '01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0104ffffffff0100f2052a0100000043410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('decode transaction v1', () {
    const data =
        '010000000001011f871dacf49f08de0b72b063cc404c75cbeefdcf7de2a5bafcbe9dcbb58eb87c0100000000ffffffff12178f0a000000000016001469f3d3f8d127c1e3c1db10d4faa3263a2e5303cb7ad23d0000000000160014dc6bf86354105de2fcd9868a2b0376d6731cb92fd8fe6c0400000000225120ad6714c44b802a2ccd6bbe667a5faade86c48201063672d32d9c5bb550c187caa3a00000000000001976a914fed6f9b52e720e3466f9467fe3e741d897ed3f6388ac012e0400000000001976a914cd2c4da5e41ca985b7b70f9640892d8ffd70220a88ace7980800000000001600141bf3e943e6b34ce90afd7ea4825340267857b2e98c4c05000000000017a914f783dd0ef788b9b9da08458e4196642fd51f03cf877873930300000000160014d05f26ec09388c9bc431140b3a011d5890a1ca0795351100000000001976a914c4e0a6b92a3586a091999b0065d7ce1cf72dd3d588ac93c20000000000001600141d4ca73811013b9800e1560f99a5e63787f445c2b15203000000000017a9143d5d7193067175f60c8c03f1624ba0c1a531722987cd64260c0000000016001437ddfc9925a2440c0248c5ce267ebd7c8eba7e9fa0fc7a0000000000160014b07d04c81ce60900a46281c11f43fa54318df7fd10920300000000001976a914352bdc1728d2e0ec44b287d983d4f45fa42b039e88ac6cfa0e000000000017a914011f646bec73c2ff7a3c6ea73b3e0212de81942e87c16803000000000017a9149d585b5e3a5c641f508af275a3f34a143636f23387e79d0900000000001600146878a6bbd9aa096da23d03bcd44ed39de954ca91c209b90000000000160014fac7320a37312597573662bc3ba5fb377ca1c8cf02483045022100d03519ced503a026dff6681429aba44551bdd1c489b79b6e247175d7b3d182ff0220642184bbc977504c394820f36cb2b18a8a7d8170f6c3f31f2003d2afcc3b8c67012102174ee672429ff94304321cdae1fc1e487edf658b34bd1d36da03761658a2bb0900000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
  test('decode transaction v1', () {
    const data =
        '010000000001011f871dacf49f08de0b72b063cc404c75cbeefdcf7de2a5bafcbe9dcbb58eb87c0100000000ffffffff12178f0a000000000016001469f3d3f8d127c1e3c1db10d4faa3263a2e5303cb7ad23d0000000000160014dc6bf86354105de2fcd9868a2b0376d6731cb92fd8fe6c0400000000225120ad6714c44b802a2ccd6bbe667a5faade86c48201063672d32d9c5bb550c187caa3a00000000000001976a914fed6f9b52e720e3466f9467fe3e741d897ed3f6388ac012e0400000000001976a914cd2c4da5e41ca985b7b70f9640892d8ffd70220a88ace7980800000000001600141bf3e943e6b34ce90afd7ea4825340267857b2e98c4c05000000000017a914f783dd0ef788b9b9da08458e4196642fd51f03cf877873930300000000160014d05f26ec09388c9bc431140b3a011d5890a1ca0795351100000000001976a914c4e0a6b92a3586a091999b0065d7ce1cf72dd3d588ac93c20000000000001600141d4ca73811013b9800e1560f99a5e63787f445c2b15203000000000017a9143d5d7193067175f60c8c03f1624ba0c1a531722987cd64260c0000000016001437ddfc9925a2440c0248c5ce267ebd7c8eba7e9fa0fc7a0000000000160014b07d04c81ce60900a46281c11f43fa54318df7fd10920300000000001976a914352bdc1728d2e0ec44b287d983d4f45fa42b039e88ac6cfa0e000000000017a914011f646bec73c2ff7a3c6ea73b3e0212de81942e87c16803000000000017a9149d585b5e3a5c641f508af275a3f34a143636f23387e79d0900000000001600146878a6bbd9aa096da23d03bcd44ed39de954ca91c209b90000000000160014fac7320a37312597573662bc3ba5fb377ca1c8cf02483045022100d03519ced503a026dff6681429aba44551bdd1c489b79b6e247175d7b3d182ff0220642184bbc977504c394820f36cb2b18a8a7d8170f6c3f31f2003d2afcc3b8c67012102174ee672429ff94304321cdae1fc1e487edf658b34bd1d36da03761658a2bb0900000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
  test('decode transaction v2', () {
    const data =
        '020000000001014d5d7cd2376971d2b70dc19f8007c2a92bc92d434aad78dccda6973156bc3bdd1100000000ffffffff020000000000000000286a262020202020202c7a7a7a7a71202020202020202c717a7a7a7a7a7a7a7a7a7a2c202020202020780e0100000000001600141cfed0b7e02b609216badd580ed363ce0e0bb4660247304402205a2cbd8815c94379cc5dd5fb5eae445d422e97fbf605291c1f8e40867c28efc5022078f1e9f5a6378d4f1bbd09c200eebac472dd582167d938872aa2f89ad54f6f9701210398cf668fe678cc6d8e2b20b5f574c9f398c7f031a1e91e9b85029e4cde597ad700000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('dogecoin tx', () {
    const data =
        '010000000d138cfa4dd9b6c016a26e80c0ee25c16bb39b69b30079007416e13f8b5c1d66f0000000006a47304402204bd620edf5b28eaf60f68d9218dee0693f1fb0ae9ed894df21874823981a014802203dc50222242ac5329a4dc808226b061fa73fc1cac8ed65ab1625809700a27cef0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff92ae2afb74d4ea6c3e3df0ddfe3a836fdd214f14a1fe61b7eba3b300208cdf37000000006b4830450221009f6864cff99c72deaa9100e616f022b9496c6a27f5ca0930ba0b94c85001311402202163081c5ebccdc1a310b22a33568b651785701d2c49f7f175cc6cda47eadc380121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff8dbe84774e929adb73461262afba3fe03941827422d724455d9a6d26fff3d3d2010000006b483045022100c23945fca081e707590fc57596a0abdad1b6a47e96b77189fa2ee64b356c2656022058a30c92d76940aaba36a43e1e3629540c2b338dc9a26b0a372bdbd22e3ca48e0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff2ae485816b06a5145f382b23f9d8e133ac4c79b515b790fad96b1dd33d155eb9000000006b483045022100db7d4b2a174c1e1da1eaeb7f1d99a2b1a7eba7407b65506dd387b64d442a654e02201f0c0d8e4967a7364e60d52e834a95e49766b9ea2fded7cd4346e09b22c871210121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff59a776796da2d053cab55dc390925ddd27734f047036b2423c2bc0406eebfe5a000000006a47304402203ecf46375800011835121ab06ce40b5073a7ae7307d45d4a47b1d1a0a1fe5628022026f2472bf2d32ff5e6ab161d151ce8a26ec98b16981b8f0ad74c6a690b5921ad0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffffbabbe45c8b93d962156f605ced7e91cc850851aa767dcf73706038311032240a000000006b483045022100ef5af19455a68557c7381abcb4c240b9ec74bcba9ab68e58865464d582959c7702201030d5c7dd06b256bab762f8d71674aef00ea9bc224a1bd6c6ec681a399459c10121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff655eb0881cfb97c4c2585c5efc1ca9c5fa8716da9f9d2a6ecdb14a8717481bd3000000006a473044022032354a6fe57420f1fee4d7fdb49e2e740347830dc148e7b9eb761d16886f161e022060b7b3e651aab836f0559d635993f3380e2d406a0a0eb1958f68003dc34509ae0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffffda7ec3634031ab1115fe4659fe731d3d290f9806a4037ed210fb2d0831eebb82000000006b483045022100afc795b53b647650e3358ce1a1d39b3f509cfe48a9cfa4a67984cf860a1e449a02206f139fd581ea16d3480956f258567529c2f81ee78f28a8ff987f45a6f2eb32850121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff953e0037d1d1017ea531f8bf9bfdcd5c466a89559a4e185d88736ced5d68ca80000000006a47304402207ca040f17c366fa9208ff6637af737b767e7b14fb3031c2b4e7368a1f494dfb40220562999aa9dc4db2c8512a088566240b8a8567ea9e5fdcf99474a790ea3bd15830121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff7db0de12d3af887ae7c6190cf4eee02a94c5e1782fe424ce92d414b64114f579010000006b48304502210099dd1fda0def15d93566d23dc46602a67b1cee1d62f44a10956520abdb7cbdff022063f1b41f5d2d053b0b9640a3578c083ec51ceeb9b18f144d094c4a678ff329f40121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff8dd8c4b8938aa615c09ef58bb6fd84a661296e47ebeb90c489bfdbcb3b37d496000000006b483045022100cfd319c796c7d730502467666a66c462d588584fee5ee84b43cb35a73787f2280220478e0634b1d0b996bac8974cbf3299778f0bf08adc0af5b53affe6a59bfbabdc0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff88fec19183b2d1ec7f308c8c5f24343b2073c32f069250a2634b7e67ea25c41d000000006b483045022100be7e59aa44977cdd6ff9caf895b6c70678d792f1c69a371ab3430ae359048880022014130c6e42d782221294b38fff886c8207fc3bc84cd8d20e904e7db5649999df0121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffffd49d5f3d30321b59a0fe4e61051a9426ab6740842bace935425b5bd4a511fc9e000000006a473044022020abfcb9805240471c7c2af6f9a4351f83946834082f65ae03ca909cfb32a31302203c9d646ae3f8f6261f0e20027111adf43382a957d294577e4cad2829d00000640121034534c45b6d6b18fdeb0af72f321ee59b3ad673e72b492d2f074bc7fc802ad57bffffffff026c0d1c144a0100001976a914012e159fa95dc1ef8ec568ee1ed1ff42cf63804888acf05e58e3bc1700001976a9140e3b95db0be4f3be8cf9805eec7640f51708596b88ac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('dogecoin tx', () {
    const data =
        '0100000003c60ef036fdabacbc899e4c6b25cfd895776119f18dddfdf2de351e4bcb78d87e000000006a47304402205c21b1bab103a0ceb245db53fd142853ea8d58a014c4761ce44c6c011158b3b102200c147f51019c0a3e3f0a1c9108dd424eee0bb47747e6df2a4f978ce01084d1a20121034583bd544ca6475ffa08337b61006dc58baa191dd34171a663d59840ca921520feffffff88151a9df595f2269e392cf554d453f4f9d1242aadaf64fc530cae25d52a6b39010000006b483045022100b3ac50ee9c5a950b4d75d6ea8f25966b46e1bcd66d7a11c5f7bf644ec55de18f0220234a8acd85d79ac3da2ecb2a30733ccf5cb92adb6cadb399b6158c16f436527e012103d5b3ad30e3c1fa8510911c350070cfb4ddce8b97874e8b318321224d8de21651fefffffffcd3fae65d095a1f1b2ff19270a310b62b7999a42c2731cb2a7b86a898b44d58030000006b483045022100ec3981eb8b6b8a04dce9f10eaa758323c33a601eeaf04f03d527449e3c9eb62c02201fc9fc3b3c4cfd9f0b864cc40b9bd28d0f623d3a6244bd022907251d6e74859801210300489fec872cf080ed88a4d4f461ca2751f90013a012770ea52c9a47a5e3f5c7feffffff02c708fc85030000001976a914a34d74643215879b6b6864e5c05160cbda197f4088ac1465e206000000001976a914a450c3040e7e253fb9443d2b9578de59d475a46288ac061b5600';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
  test('litecoin tx', () {
    const data =
        '010000000150a425002379dfd83718474ca3d46efad63dc8bcbed20aca484e381230e1f896010000006b483045022100bdfc1647ba51b1ccb9d6945df4603b605c1a159bc518020bdd7297511b56a090022022835148bb399d087481d61ee236584c50a7da07077c561f5f193cf69fee27fa012102862ac97f69ddc423ed7261d2f6fe91384d365ed8e1405a98893db3cc86a253ebffffffff02fa7372000000000017a9148ca092e2ba513ec4bfb9a22f1d4c37c515e186e68739d09e01000000001976a914058cd1272c5cef87c1aa2d1a5ac8864cdcd8c56f88ac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('litecoin tx 2', () {
    const data =
        '02000000000101b6bbd3447513cab8062cd93cb4d6a74a87b38813a1f11da664788646687e4c880100000000fdffffff021a4c2e36000000001600149095aed28074d0861e807ea27bf79fa4076d8f57d076140400000000160014d6c63917e45c0ef4dfeab29ea581b7c6eb288bc3024730440220570199800473ca545c7eb19cbb3f0f26e9ac58971b3f495f03eeb25e27455cc302202c30ec2c953b4996d1ee2af87b7f24dd7a8f6a8ac0388b610a817c402599b7550121026d9e26471899e2f2d9acd6fc76c82329b58573687d6fbcd0677840c3ff4f67279fc72b00';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('dash tx', () {
    const data =
        '02000000067ec6789ca1437bfd229cd5e338a365bbb83c438cb25d3e1e56eb49c8a3469203050000006a47304402205771740351025d4465ac31e996dab359b818e146bd593186ef0bcc18a477f640022043d4f8a9648890a2d394a652d9372d8b109b75ea6f1b2a2285c3aba190d35ed9812102d52c46b94eeead777d624e97203110e5b9dd3b0c52032509228805dd527a1ccaffffffff02794de87868e74bb5dbcc6c0e1268efa054e257f5d3becb1691b87accc0814b2d0000006a473044022038f2ffd79668721983d6364a1ecf307393b224f17c9c7f32a181baa779902b830220481b6279fa713d633696eef57531c248a588168d272afe4cda746ba8cbf04ca5812103321be6dda0ec05b04e805fb444d08f79d4f9f4bb2dd424cd831cb5412b22b7d6ffffffff36568984b7948c483c82c77f36a486ad30f9f14b28e8b6b85ba9d29179003f68110000006b483045022100c09b8fa76375d4959ae54b087964a915e4b455906882cafc2ad0421409beb077022022b809ce0276964c463958298b42ef9d0bef6da37cd2b3be436fcca10ccbae13812103bb0972ca8d668467137af4f755a02c5092c02cd842a0d0210288042e91971c89ffffffffbb0e6a6f3cdc34e1505e4c859a338256cf56b92031b647a142c9ab7ba56d136b070000006a473044022038632f60d4456de01bcf16181c349db1e8e029e09f6382755a1cd154e3f4849d022066098478d641e8fc0b5f55a7603a175b90fc7a6c807e47ab5d80390227c2527a812103059f8e54c70ba3ed62dc7f990855073ab4e351a5c77030c229ec179e78d4e4d5ffffffff47a3bba1d13a32d00c6e8aa605be2ec650ededbeba0c59593d709323c670ef82030000006a47304402205d4c722eb5615fc7964e8342eb149a3bf91df65f710a4d6ba4c692263e1ee8700220730f5e081283c92e8ea9a741818e24602451d08743a3d9234fd5e867d7dcd504812103f214e07727f4960f0fcd00607d09740b90fdc3c321325590cd02e6325129a5aaffffffff139f25d2de7e5d70f6210c63d5aafa2e252d2ba7cc4edb8a793dc9b00bcad7c8030000006a473044022072abc5ba89862cd55abec975c4e59c04d59eda5a4f6b2fbf42ced7c554be98bf02206ad19698e81fea5b0de12b8b1f8195b2562d8988c2bf4ae33143a770bfc5ac2c812103aeb97d6a600daaa42c618da9bf81ec57f02f44b6c3189c699a63b4bfeae95a71ffffffff06e4969800000000001976a9142149692d05b5e3f41f848acda5f2b37c2aaac47888ace4969800000000001976a9145f36f030a224b07faf33f39200f4436d28d964a688ace4969800000000001976a91469edca14c80aee4cc2201a3bbc7f0b5ef4636e3d88ace4969800000000001976a9147cbe0e9eb6fad144961614848b628e6bb9549b3788ace4969800000000001976a914b3221850107422cbe5c8a9719f7cf6852116778b88ace4969800000000001976a914f35755bc08cd70b736d263cc64dd178dc8062e4e88ac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('dash tx 2', () {
    const data =
        '0200000008e6bb96ca66f9113d1e912ae8428c643775e80bbf2c42a66e3d0d7b0a0745e110000000006a4730440220627a2a95b41239ce18ed210e284d4b2f340bd04cbe4aefb46ac17d81fe633e8c022009d51a430462e1acd136f166e12023e6fe128da5d58c2a22747999b4930f3b9b8121030066e007a0c062395f2465fc7530464033d6bf06da4d31b7cab4528c78fb7e92ffffffff655ffbce984d7cdd5755956cf81c6cba943cd3f73096cdfccfb2c773a55f8a17050000006a47304402201dcb97a5e6bcd2b84c6b516f4ce822f0dbc56e7a7861c58c45e38911016296bb0220100792d21a272cc8f82cc5731c7b6d5d01ead82a7e86e7b8e56c3993d2ddca55812103bf143b5da4c72c710ab4faa03699ffcde664f702dcb9a233e7c4b2f2bc34df28ffffffff9e7313069e2354fa5ea83c9cadad39a3af6bb1fcce20288014045ced582ca32f050000006a47304402202f9bf53ba54b0c9a6fc51413f7fae2f807c77862fb732cefdf8126da75ea3cd90220469bd0613f1c608bb86d038fef5488b58c13d5bf315a7ea9f1013af55ac5aacf812102056bb71313ac1312ac06c37d9e122ac474d362f612f24efc2a2fcb5a2e7b14c9ffffffff02794de87868e74bb5dbcc6c0e1268efa054e257f5d3becb1691b87accc0814b040000006a47304402206613a22198b8d2da88d2130b4a9eda7b1d215c2d911d9e93fe7d09e287591b33022026db2b3e5fa08517b9e1298c55de6f82232515961206b834377158b5ed7582e2812102645d5fd97132ffc062fda0f2a5690dae75063e7822fcd8eecae4804beabc0311ffffffff3050c730cf10d18748a9814886e707b1c57a01e76447463ac0f36a5887bd6c850a0000006a47304402201337bbc74c8590db7dac559ce3ed35d9a1ff2c38ac9a02afe03d6805d8d2a5c8022016ae120c2549ec8f9ae17e70a7eab1acfb17964cdce9385de3952f22a95527e9812102c986ba3071adb0c4d25e217ee94c87cc1a5815e1d3a1066f751ab912695210bcffffffff3050c730cf10d18748a9814886e707b1c57a01e76447463ac0f36a5887bd6c850b0000006a47304402204595b722080bc7f25eeee7d51854daaf609813db0b87f80dfc581833a709509f02202b0f00d0423f016b5736f6a661c4cffb40d7afc17cf996722ca9a2b9205c167b812103df03592adc913ed3ce4fb0e141f75b038f57a83aef4a06c2c905bd14b271ad9affffffff5a856c1742a1405ddd0743b270b406d977d28632356ae66f71a51d8591ffa58f050000006a4730440220064b645f8412311faffcd35441b94c344be199385d0b47824708ed375f3dbf690220449ba172b0afdf57617ef2b4772cd31257d8f7b3e72477340016a0e391ce49088121025c40a587b2a7d11b0eb5cd5ad3fa5ddf5cf65315c92a492f193f5f08305793a5ffffffff8dca5a8ea7c2ec793023ad96f06ee9f138cd634ce50d352e3c2608f162c91ba9020000006a4730440220691e3c4f0225ef7bd7350ad21d4714754f7d6b1ddaac8dbad2b6860e9bf8c49b02200c4a31b450da238fb858188e3f123f0ad6ae81598dc731ec04750923cd081ab681210331778c0c3100b2496af4dc66672b0725c0a761d2cb78c0d020d70c9926be7bd6ffffffff08a1860100000000001976a9140c0fd22a69781721011509241fca1fad9cd4bea388aca1860100000000001976a914695e68c012a8761975575fce48830a908420e40a88aca1860100000000001976a9146ceaa83bdb3e97ad30838de6bfca5cafac4d3ff988aca1860100000000001976a91473eee8557895c3b7bd46aae904fc42a235fe9ce788aca1860100000000001976a914bc43911184a259081097ad6b5654b21379f9e0c388aca1860100000000001976a914cad640fd47e5ac874f6b04f8ca0b6eb32881be8c88aca1860100000000001976a914cb18799503fbe4d6e1048848f3b949416e1a78b688aca1860100000000001976a914f932d6a4cc4c9299e4bca2f758b3d9de97a9157788ac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('bitcoincash tx', () {
    const data =
        '01000000041904b4c85904f67047abc6e85704f6d01e9713cd06321533d77e5bda317c957201000000fdfe0000483045022100a12184aa60e74461cbbe7cf45fabae2be6ceae62ba2b0c5f9db20869442aa8e802205b988b94c77e35ce6a2f3cd7bfaf103e71835be380e538719b54a13567904ead41483045022100eae8ae369e43af4861dac31c776ac29146558be5aa4ad3f79066b9175429dfa202203515f0e5b87ceb4299a238c528a79d02e5afc364ab9869c34e0a501736da0544414c695221030f936f5aa4cc703cb6e58f74fa9822f4c02a3711d486f6659c898fced90d94802103704d85f33c05ab154ca17af039c4a0ec86c4ebbbceb6059cb213967af9a88284210332a19546459dbc0c0e0fdd666ac4660773dff7a87259b6f710397f645af1d63653aefffffffff94c6b88cc195d32612a3cfcd988e975a9d85e684a4994a4c146a302a91261d808000000fdfd0000483045022100e65d01c256046c0a3157c29d633a3f274cb8870c197ed83a57bb144035ba26ce02205b93697bea63856e042b13538a50a210193c24e564b3c5f0f0c499daeb1eac1841473044022001c5f43071070a2cf2df838816c2a03033e3f8f7ef7676739ca331c1b52dcb3102204b71b3eaaf419bf0394d6e7af2d69e0d453260ee2c42dfa883bf84eeceeb1a83414c695221036387540a911a4a9b5301747f95ac464569e433f89b543656249a91d6ba2331f52102770461d186bae94795a1a03e768e48c631bf330b33ff877e6301c304053238bd21022faf46f5453ddcb477b585008e740c663ed747a76d1b66d39a91f5aaa2d4bca253aeffffffff8d747a002b24313ec23a2e30ef9c242d7984735d082df95f55240deb265d110d01000000fdfd0000483045022100b80e84b5f2f4d23933a9a2cd86e3cd144c4acdc5b4672b220922d30d6509525702200eed3b90c90fe1fcf8218b0178e6e7a7e4822e95fe5ff6e50f3a42d808fd5abd41473044022048b69d1e9ab25811353575ce29007a3106afce53a53909f6d68c58f46935036302206abd28e1d489fae8d1b740d9aa6793197268bb60c6a5dd9f95930988ff388d87414c695221030f936f5aa4cc703cb6e58f74fa9822f4c02a3711d486f6659c898fced90d94802103704d85f33c05ab154ca17af039c4a0ec86c4ebbbceb6059cb213967af9a88284210332a19546459dbc0c0e0fdd666ac4660773dff7a87259b6f710397f645af1d63653aeffffffffc6f51b454354ef651defdb1b11423cef138af021936053861b6378e8e0ea4e5d00000000fdfd000047304402205d10dc9a1c2597da9ec3f09ae94a0f40155ffba761405d0736bb3d57857b0007022072096747ae9681537ab3435f4cf36323cb303444522b9ff76692e782ddc1ec7f41483045022100be6425b03866bd4f89c8ff3753646e438b8bf3c0c8c9c48e5bb6529208b3949302205ab25792a8bfede2ef696c12d23bfe435f19aaee60e12e8c04824d955be61058414c69522103178e8f0f888f72f46c2866c9f70c5c43d01d1e224d7f6606d4b6464d8980dd6021036a86f8ef4b99902bcabbed85009774632e59a2669642fef23f0db58ee58e267f210202e0615394ed2be02c2bc06237b82a4055414b3fca939e125230fbe8f42ba6a953aeffffffff02306e2e01000000001976a914bbffc1dd8a5ca4123107a53445eb27dab94ba99188ac2dd5c4040000000017a9145cb22d4e81d3ed41993d117c17308a69586951998700000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('bitcoincash tx 2', () {
    const data =
        '01000000018b2fc92143114a0637b66e315a7eb5c3cee66fc4b5dcdd46c17aea061317cb95000000006b483045022100c85588fd44178becaa66caa53b916f9c5e7e05a8c8b06e1277b59113af43995102204ec5a673403cf56878256d7d57d149fb5d4030d15c9f39f3efb4bbacd9a8750341210208c6b6d97ca3d625fba56b6460bdcceb3e06f5555c1184590b3339c0f5879be1ffffffff05e0609cba000000001976a91490f228539519931540f0e1de25dbc0093498c7a588acb3ebc100000000001976a914d50187c085db7ee76fdcf374773be65d91dfa5b788ac238f6400000000001976a914f7b20108496c168d589274b10c7c461db4008ad888ac16255200000000001976a914fdc30e2b3281bfe05ff7e2935a18a3cffb054a4188acbb652b00000000001976a9143f33cc9456e79bd74ab175b807c7a830f768d2df88ac00000000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });

  test('bitcoincash tx 3 NFT', () {
    const data =
        '02000000027c4e8ce3897e23afd8fa5ba394efb2a5ba810da6cfe2351fb34798e31bd6dc9e0000000064413ee47f3531cbcae584e71992060c29b611062667834a242a5c9b508e76b2ecc1f8c03d87b8c6af1c97a9d3038eba3c440fdb9e2b4d42851cd997f0835318fc47612102bb2f64940415b2c6511d6290d2a8da06db708c2c1a8c19df0b3cecc338050b0700000000db43539e4474909c80ea4e0a7eb8bfff7be752f3a3da527428af3470d025011701000000fd6f0110414de5676a471000524710008280000040c63937fb49a950b2ddfddfd314772c883b90244d035340340fc35eb63a92eb60e6a50f3c744c4cdb40fd0e13caa88b2651c706830349f20cfd886d724b9f3c8c2102d09db08af1ff4e8453919cc866a4be427d7bfe18f2c05e5444c196fcf6fd2818004cf82103341a6fb68e883fb2c5ce0d0d186e9e09792839479bfb14adda2f498fc2dfaacf78009c635279827701219d54798277609dc0cf827701249dc0cf01147f785579a988557a5679567abb5479587f77547f75817c587f77547f7581a069c0ccc0c6a269c0cdc0c788c0d1c0ce88537a7ec0d28777776778519c6302e803c0ccc0c67b93a269c0cdc0c788c0d1c0ce88c0d2c0cf8777776778529c637b7cadc0cc022003a269c0cdc0c788c0d1c0ce88c0d2c0cf8777677c539dadc0cc022003a269c0cdc0c788c0d1c0ce88c0d2827701249dc0cf01147f75c0d201147f7b7b879169100000000000000000000000000000000087686868ffffffff02a0e99b00000000001976a9149ad0f528e1c26501c49f1186bb2f208038971ac488ac50711600000000006aef5059621a87a140da4d8f83e456630be833cc7d7664e43fbbf481da5c3dfcb6b06124763d932c30ca45715f9861dc205243f1520bfafa414de5676a4710005247100082800000aa2076fbc08f5ba4bd098f0c0da12a13d5b229b68c6d7e3cbd197c90ec01ae116ab98729230000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
  test('bitcoincash tx 4 NFT', () {
    const data =
        '0200000003bd9b073409d877028322f7286a4f4f0f6fd9213ae87f5dcb64fb575edf87f76400000000fd6c01004d680123aa20b758a71d99ea449f56cbdfb68516be858480fc320e8365b86917e8a7871b0f4387215059621a87a140da4d8f83e456630be833cc7d7664e43fbbf481da5c3dfcb6b0015279009c63c076009d51ce7b8851cf011c7f77547f758100cf816ea269785379cd5479c7885379d15479ce885379d2885279d35379d0a2695279cc02e8039da078d35279d0016493a29b69c452a06352d1008868c453a06376ce01207f7553d1008753d15279879b6953d200887568c454a1777777677b519dc076009d51ce7b88768bcf76011c7f77547f75815279cf8178a1697c01207f77817600a06952cc529553967c950400e1f5059652795393d3767ba169760164a2697603a08601a1695279cd5379c7885279d15379ce885279d27b8878d35279d05279949d78cc02e8039d7cce01207f7552d178885379827701149d52d2547a537a7e8852d3009d52cd7b8853cc02e8039d53d18853d2008854d10088c455a06355d1008868c456a168000000007c4e8ce3897e23afd8fa5ba394efb2a5ba810da6cfe2351fb34798e31bd6dc9e01000000fb514cf82103341a6fb68e883fb2c5ce0d0d186e9e09792839479bfb14adda2f498fc2dfaacf78009c635279827701219d54798277609dc0cf827701249dc0cf01147f785579a988557a5679567abb5479587f77547f75817c587f77547f7581a069c0ccc0c6a269c0cdc0c788c0d1c0ce88537a7ec0d28777776778519c6302e803c0ccc0c67b93a269c0cdc0c788c0d1c0ce88c0d2c0cf8777776778529c637b7cadc0cc022003a269c0cdc0c788c0d1c0ce88c0d2c0cf8777677c539dadc0cc022003a269c0cdc0c788c0d1c0ce88c0d2827701249dc0cf01147f75c0d201147f7b7b87916910000000000000000000000000000000008768686800000000bd9b073409d877028322f7286a4f4f0f6fd9213ae87f5dcb64fb575edf87f764020000006441fee8035fa13b02783daf398197af10ebb890820119fdddf0e6519039fb8b92e5e718c63da97a06fd4a0bebb3f6f5939d977b1a52d9185caa14512c2077a5bd4161210245496ebbf3d90fa94a395a3b6cc6852fbc621ee4147bbac0580a59d803cae8f80000000003e8030000000000004eef67bf363c2417af7fed5514fa1f489f845222f93d8a044a21b2706bba3c9146407203484710fe3ca1ae05aa20539be6c586e4f426a100e0bd56b3c0f765bea9d796e504f68f02ef992f26ac1487c0821700000000006aef5059621a87a140da4d8f83e456630be833cc7d7664e43fbbf481da5c3dfcb6b06124763d932c30ca45715f9861dc205243f1520bfafae94ae56760471000484710003f800000aa2076fbc08f5ba4bd098f0c0da12a13d5b229b68c6d7e3cbd197c90ec01ae116ab98758353900000000001976a914925e9bcecea0e9a129ede392a075da2ef03a22c188ac29230000';
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(data));
    expect(tx.serialize(), data);
  });
}
