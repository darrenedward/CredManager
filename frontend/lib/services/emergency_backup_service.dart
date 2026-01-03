import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'argon2_service.dart';
import 'database_service.dart';

/// Backup code format options
enum BackupCodeFormat {
  /// BIP39 word list format (24 words for 256-bit entropy)
  bip39,
  /// Base32 encoded format (RFC 4648)
  base32,
}

/// Service for managing emergency backup passphrase kit
/// This service generates, stores, and verifies backup codes that allow
/// users to recover their account if they forget their master passphrase.
class EmergencyBackupService {
  final Argon2Service _argon2Service = Argon2Service();
  final Random _random = Random.secure();

  // Database keys for backup code metadata
  static const String _backupCodeHashKey = 'backup_code_hash';
  static const String _backupCodeCreatedKey = 'backup_code_created';
  static const String _backupCodeUsedKey = 'backup_code_used';

  /// Generate a cryptographically secure backup code with 256-bit entropy
  ///
  /// [format] - The format to use for the backup code (BIP39 words or Base32)
  ///
  /// Returns a backup code that can be used to recover the account
  Future<String> generateBackupCode({BackupCodeFormat format = BackupCodeFormat.bip39}) async {
    // Generate 256 bits (32 bytes) of entropy
    final entropy = _generateEntropy(32);

    switch (format) {
      case BackupCodeFormat.bip39:
        return _entropyToBip39Words(entropy);
      case BackupCodeFormat.base32:
        return _entropyToBase32(entropy);
    }
  }

  /// Hash a backup code using Argon2id for secure storage
  ///
  /// [backupCode] - The plaintext backup code to hash
  ///
  /// Returns the Argon2 hash of the backup code
  Future<String> hashBackupCode(String backupCode) async {
    if (backupCode.trim().isEmpty) {
      throw ArgumentError('Backup code cannot be empty');
    }

    if (backupCode.trim().length < 8) {
      throw ArgumentError('Backup code is too short');
    }

    // Hash using Argon2id (generates own salt internally)
    final hash = await _argon2Service.hashPassword(backupCode);

    return hash;
  }

  /// Verify a backup code against the stored hash
  ///
  /// [backupCode] - The backup code to verify
  ///
  /// Returns true if the code matches the stored hash
  Future<bool> verifyBackupCode(String backupCode) async {
    if (backupCode.trim().isEmpty) {
      return false;
    }

    try {
      // Check if code was already used
      final db = await DatabaseService.instance.database;
      final usedResult = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_backupCodeUsedKey],
        limit: 1,
      );

      if (usedResult.isNotEmpty) {
        final wasUsed = usedResult.first['value'] as String;
        if (wasUsed == '1') {
          return false; // Code already used
        }
      }

      // Get the stored hash
      final hashResult = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_backupCodeHashKey],
        limit: 1,
      );

      if (hashResult.isEmpty) {
        return false; // No backup code stored
      }

      final storedHash = hashResult.first['value'] as String;

      // Verify using Argon2
      return await _argon2Service.verifyPassword(backupCode, storedHash);
    } catch (e) {
      print('Error verifying backup code: $e');
      return false;
    }
  }

  /// Store a hashed backup code in the database
  ///
  /// [hashedCode] - The Argon2 hash of the backup code
  Future<void> storeBackupCodeHash(String hashedCode) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Store the hash
    await db.insert(
      'app_metadata',
      {
        'key': _backupCodeHashKey,
        'value': hashedCode,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Store creation timestamp
    await db.insert(
      'app_metadata',
      {
        'key': _backupCodeCreatedKey,
        'value': now.toString(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Mark as not used
    await db.insert(
      'app_metadata',
      {
        'key': _backupCodeUsedKey,
        'value': '0',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Stored emergency backup code hash');
  }

  /// Check if a backup code exists
  Future<bool> hasBackupCode() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_backupCodeHashKey],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the creation date of the backup code
  Future<DateTime?> getBackupCodeCreationDate() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_backupCodeCreatedKey],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final timestamp = int.parse(result.first['value'] as String);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Remove the backup code from storage
  Future<void> removeBackupCode() async {
    final db = await DatabaseService.instance.database;

    await db.delete(
      'app_metadata',
      where: 'key IN (?, ?, ?)',
      whereArgs: [
        _backupCodeHashKey,
        _backupCodeCreatedKey,
        _backupCodeUsedKey,
      ],
    );

    print('Removed emergency backup code');
  }

  /// Mark the backup code as used (after redemption)
  Future<void> markBackupCodeAsUsed() async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'app_metadata',
      {
        'value': '1',
        'updated_at': now,
      },
      where: 'key = ?',
      whereArgs: [_backupCodeUsedKey],
    );

    print('Marked backup code as used');
  }

  /// Check if the backup code was already used
  Future<bool> wasBackupCodeUsed() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_backupCodeUsedKey],
        limit: 1,
      );

      if (result.isEmpty) return false;

      return result.first['value'] == '1';
    } catch (e) {
      return false;
    }
  }

  /// Generate QR code data from a backup code
  ///
  /// [backupCode] - The backup code to encode
  ///
  /// Returns a string that can be used to generate a QR code
  Future<String> generateQRCodeData(String backupCode) async {
    // For now, return the backup code as-is
    // In production, this could add prefixes, versioning, etc.
    return 'CREDMAN:$backupCode';
  }

  /// Decode QR code data back to backup code
  ///
  /// [qrData] - The QR code data to decode
  ///
  /// Returns the original backup code
  String decodeQRCodeData(String qrData) {
    if (qrData.startsWith('CREDMAN:')) {
      return qrData.substring(8); // Remove prefix
    }
    return qrData; // Return as-is for backwards compatibility
  }

  /// Validate if a string has a valid backup code format
  ///
  /// [code] - The code to validate
  ///
  /// Returns true if the format is valid
  bool isValidBackupCodeFormat(String code) {
    if (code.trim().isEmpty) return false;

    // Check for BIP39 word format (24 words)
    final words = code.trim().split(RegExp(r'\s+'));
    if (words.length >= 12 && words.length <= 24) {
      // Could be BIP39 format
      return words.every((w) => RegExp(r'^[a-zA-Z]+$').hasMatch(w));
    }

    // Check for Base32 format (A-Z, 2-7)
    if (code.length >= 20) {
      return RegExp(r'^[A-Z2-7]+$').hasMatch(code);
    }

    return false;
  }

  // ==================== PRIVATE METHODS ====================

  /// Generate cryptographically secure random bytes
  Uint8List _generateEntropy(int length) {
    final entropy = Uint8List(length);
    for (int i = 0; i < length; i++) {
      entropy[i] = _random.nextInt(256);
    }
    return entropy;
  }

  /// Generate a cryptographically secure salt
  Uint8List _generateSalt() {
    return _generateEntropy(16);
  }

  /// Convert entropy to BIP39 word list format
  ///
  /// 256 bits = 24 words (11 bits per word)
  String _entropyToBip39Words(Uint8List entropy) {
    // Simplified BIP39 word list (using common English words)
    // In production, use the full BIP39 word list
    const wordList = [
      'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract', 'absurd', 'abuse',
      'access', 'accident', 'account', 'accuse', 'achieve', 'acid', 'acoustic', 'acquire', 'across', 'act',
      'action', 'actor', 'actress', 'actual', 'adapt', 'add', 'addict', 'address', 'adjust', 'admit',
      'adult', 'advance', 'advice', 'aerobic', 'affair', 'afford', 'afraid', 'again', 'age', 'agent',
      'agree', 'ahead', 'aim', 'air', 'airport', 'aisle', 'alarm', 'album', 'alcohol', 'alert', 'alien',
      'all', 'alley', 'allow', 'almost', 'alone', 'alpha', 'already', 'also', 'alter', 'always', 'amateur',
      'amazing', 'among', 'amount', 'amused', 'analyst', 'anchor', 'ancient', 'anger', 'angle', 'angry',
      'animal', 'ankle', 'announce', 'annual', 'another', 'answer', 'antenna', 'antique', 'anxiety', 'any',
      'apart', 'apology', 'appear', 'apple', 'approve', 'april', 'arch', 'arctic', 'area', 'arena',
      'argue', 'arm', 'armed', 'armor', 'army', 'around', 'arrange', 'arrest', 'arrive', 'arrow', 'art',
      'artefact', 'artist', 'artwork', 'ask', 'aspect', 'assault', 'asset', 'assist', 'assume', 'asthma',
      'athlete', 'atom', 'attack', 'attend', 'attitude', 'attract', 'auction', 'audit', 'august', 'aunt',
      'author', 'auto', 'autumn', 'average', 'avocado', 'avoid', 'awake', 'aware', 'away', 'awesome', 'awful',
      'awkward', 'axis', 'baby', 'bachelor', 'bacon', 'badge', 'bag', 'balance', 'balcony', 'ball', 'bamboo',
      'banana', 'banner', 'bar', 'barely', 'bargain', 'barrel', 'base', 'basic', 'basket', 'battle', 'beach',
      'bean', 'beauty', 'because', 'become', 'beef', 'before', 'begin', 'behave', 'behind', 'believe', 'below',
      'belt', 'bench', 'benefit', 'best', 'betray', 'better', 'between', 'beyond', 'bicycle', 'bid', 'bike',
      'bind', 'biology', 'bird', 'birth', 'bitter', 'black', 'blade', 'blame', 'blanket', 'blast', 'bleak',
      'bless', 'blind', 'blood', 'blossom', 'blouse', 'blue', 'blur', 'blush', 'board', 'boat', 'body', 'boil',
      'bomb', 'bone', 'bonus', 'book', 'boost', 'border', 'bored', 'borrow', 'boss', 'bottom', 'bounce', 'box',
      'boy', 'bracket', 'brain', 'brand', 'brass', 'brave', 'bread', 'breeze', 'brick', 'bridge', 'brief',
      'bright', 'bring', 'brisk', 'broccoli', 'broken', 'bronze', 'broom', 'brother', 'brown', 'brush', 'bubble',
      'buddy', 'budget', 'buffalo', 'build', 'bulb', 'bulk', 'bullet', 'bundle', 'bunker', 'burden', 'burger',
      'burst', 'bus', 'business', 'busy', 'butter', 'buyer', 'buzz', 'cabbage', 'cabin', 'cable', 'cactus', 'cage',
      'cake', 'call', 'calm', 'camera', 'camp', 'can', 'canal', 'cancel', 'candy', 'cannon', 'canoe', 'canvas',
      'canyon', 'capable', 'capital', 'captain', 'car', 'carbon', 'card', 'cargo', 'carpet', 'carry', 'cart',
      'case', 'cash', 'casino', 'castle', 'casual', 'cat', 'catalog', 'catch', 'category', 'cattle', 'caught',
      'cause', 'caution', 'cave', 'ceiling', 'celery', 'cement', 'census', 'century', 'cereal', 'certain', 'chair',
      'chalk', 'champion', 'change', 'chaos', 'chapter', 'charge', 'chase', 'chat', 'cheap', 'check', 'cheese',
      'chef', 'cherry', 'chest', 'chicken', 'chief', 'child', 'chimney', 'choice', 'choose', 'chronic', 'chuckle',
      'chunk', 'churn', 'cigar', 'cinnamon', 'circle', 'citizen', 'city', 'civil', 'claim', 'clap', 'clarify',
      'claw', 'clay', 'clean', 'clerk', 'clever', 'click', 'client', 'cliff', 'climb', 'clinic', 'clip', 'clock',
      'clog', 'close', 'cloth', 'cloud', 'clown', 'club', 'clump', 'cluster', 'clutch', 'coach', 'coast', 'coconut',
      'code', 'coffee', 'coil', 'coin', 'collect', 'color', 'column', 'combine', 'come', 'comfort', 'comic', 'common',
      'company', 'concert', 'conduct', 'confirm', 'congress', 'connect', 'consider', 'control', 'convince', 'cook',
      'cool', 'copper', 'copy', 'coral', 'core', 'corn', 'corner', 'correct', 'cost', 'cotton', 'couch', 'country',
      'couple', 'course', 'cousin', 'cover', 'coyote', 'crack', 'cradle', 'craft', 'cram', 'crane', 'crash', 'crater',
      'crawl', 'crazy', 'cream', 'credit', 'creek', 'crew', 'cricket', 'crime', 'crisp', 'critic', 'crop', 'cross',
      'crouch', 'crowd', 'crucial', 'cruel', 'cruise', 'crumble', 'crunch', 'crush', 'cry', 'crystal', 'cube', 'culture',
      'cup', 'cupboard', 'curious', 'current', 'curtain', 'curve', 'cushion', 'custom', 'cute', 'cycle', 'dad',
      'damage', 'damp', 'dance', 'danger', 'daring', 'dash', 'daughter', 'dawn', 'day', 'deal', 'debate', 'debris',
      'decade', 'december', 'decide', 'decline', 'decorate', 'decrease', 'deer', 'defense', 'define', 'defy', 'degree',
      'delay', 'deliver', 'demand', 'demise', 'denial', 'dentist', 'deny', 'depart', 'depend', 'deposit', 'depth',
      'deputy', 'derive', 'describe', 'desert', 'design', 'desk', 'despair', 'destroy', 'detail', 'detect', 'develop',
      'device', 'devote', 'diagram', 'dial', 'diamond', 'diary', 'dice', 'diesel', 'diet', 'differ', 'digital', 'dignity',
      'dilemma', 'dinner', 'dinosaur', 'direct', 'dirt', 'disagree', 'discover', 'disease', 'dish', 'dismiss', 'disorder',
      'display', 'distance', 'divert', 'divide', 'dizziness', 'do', 'doctor', 'document', 'dog', 'doll', 'dolphin',
      'domain', 'donate', 'donkey', 'donor', 'door', 'dose', 'double', 'dove', 'draft', 'dragon', 'drama', 'draw',
      'dream', 'dress', 'drift', 'drill', 'drink', 'drip', 'drive', 'drop', 'drum', 'dry', 'duck', 'dumb', 'dune',
      'during', 'dust', 'dutch', 'duty', 'dwarf', 'dynamic', 'eager', 'eagle', 'early', 'earn', 'earth', 'easily',
      'east', 'easy', 'echo', 'ecology', 'economy', 'edge', 'edit', 'educate', 'effort', 'egg', 'eight', 'elbow',
      'elder', 'electric', 'element', 'elephant', 'elevator', 'elite', 'else', 'embark', 'embody', 'embrace', 'emerge',
      'emotion', 'employ', 'empower', 'empty', 'enable', 'enact', 'end', 'endless', 'endorse', 'enemy', 'energy',
      'enforce', 'engage', 'engine', 'enhance', 'enjoy', 'enlist', 'enough', 'enrich', 'enroll', 'ensure', 'enter',
      'entire', 'entry', 'envelope', 'episode', 'equal', 'equip', 'era', 'erase', 'erode', 'erosion', 'error', 'erupt',
      'escape', 'essay', 'essence', 'estate', 'eternal', 'ethics', 'evidence', 'evil', 'evoke', 'evolve', 'exact',
      'example', 'excess', 'exchange', 'excite', 'exclude', 'excuse', 'execute', 'exercise', 'exhaust', 'exhibit', 'exile',
      'exist', 'exit', 'exotic', 'expand', 'expect', 'expire', 'explain', 'expose', 'express', 'extend', 'extra', 'eye',
      'eyebrow', 'fabric', 'face', 'faculty', 'fade', 'faint', 'faith', 'fall', 'false', 'fame', 'family', 'famous', 'fan',
      'fancy', 'fantasy', 'farm', 'fashion', 'fat', 'fatal', 'father', 'fatigue', 'fault', 'favorite', 'feature', 'february',
      'federal', 'fee', 'feed', 'feel', 'female', 'fence', 'festival', 'fetch', 'fever', 'few', 'fiber', 'fiction',
      'field', 'figure', 'file', 'film', 'filter', 'final', 'find', 'fine', 'finger', 'finish', 'fire', 'firm', 'first',
      'fiscal', 'fish', 'fit', 'fitness', 'fix', 'flag', 'flame', 'flash', 'flat', 'flavor', 'flee', 'flight', 'flip',
      'float', 'flock', 'floor', 'flower', 'fluid', 'flush', 'fly', 'foam', 'focus', 'fog', 'foil', 'fold', 'follow', 'food',
      'foot', 'force', 'forest', 'forget', 'fork', 'fortune', 'forum', 'forward', 'fossil', 'foster', 'found', 'fox',
      'fragile', 'frame', 'frequent', 'fresh', 'friend', 'fringe', 'frog', 'front', 'frost', 'frown', 'frozen', 'fruit',
      'fuel', 'fun', 'funny', 'furnace', 'fury', 'future', 'gadget', 'gain', 'galaxy', 'gallery', 'game', 'gap', 'garage',
      'garbage', 'garden', 'garlic', 'garment', 'gas', 'gasp', 'gate', 'gather', 'gauge', 'gaze', 'general', 'genius',
      'genre', 'gentle', 'genuine', 'gesture', 'ghost', 'giant', 'gift', 'giggle', 'ginger', 'giraffe', 'girl', 'give',
      'glad', 'glance', 'glare', 'glass', 'glide', 'glimpse', 'globe', 'gloom', 'glory', 'glove', 'glow', 'glue', 'goat',
      'goddess', 'gold', 'good', 'goose', 'gorilla', 'gospel', 'gossip', 'govern', 'gown', 'grab', 'grace', 'grain', 'grant',
      'grape', 'grass', 'gravity', 'great', 'green', 'grid', 'grief', 'grit', 'grocery', 'group', 'grow', 'grunt', 'guard',
      'guess', 'guide', 'guilt', 'guitar', 'gun', 'gym', 'habit', 'hair', 'half', 'hammer', 'hamster', 'hand', 'handle',
      'harbor', 'hard', 'harsh', 'harvest', 'hat', 'have', 'hawk', 'hazard', 'head', 'health', 'heart', 'heavy', 'hedgehog',
      'height', 'hello', 'helmet', 'help', 'hen', 'hero', 'hidden', 'high', 'hill', 'hint', 'hip', 'hire', 'history',
      'hobby', 'hockey', 'hold', 'hole', 'holiday', 'hollow', 'home', 'honey', 'hood', 'hope', 'horn', 'horror', 'horse',
      'hospital', 'host', 'hotel', 'hour', 'hover', 'hub', 'huge', 'human', 'humble', 'humor', 'hundred', 'hungry', 'hunt',
      'hurdle', 'hurry', 'hurt', 'husband', 'hybrid', 'ice', 'icon', 'idea', 'identify', 'idle', 'ignore', 'ill', 'illegal',
      'illness', 'image', 'imitate', 'immense', 'immune', 'impact', 'impose', 'improve', 'impulse', 'inch', 'include',
      'income', 'increase', 'index', 'indicate', 'indoor', 'industry', 'infant', 'inflict', 'inform', 'inhale', 'inherit',
      'initial', 'inject', 'injury', 'inmate', 'inner', 'innocent', 'input', 'inquiry', 'insane', 'insect', 'inside', 'inspire',
      'install', 'intact', 'interest', 'into', 'invest', 'invite', 'involve', 'iron', 'island', 'isolate', 'issue', 'item',
      'jacket', 'jaguar', 'jar', 'jazz', 'jealous', 'jeans', 'jelly', 'jewel', 'job', 'join', 'joke', 'journey', 'joy',
      'judge', 'juggle', 'juice', 'jump', 'jungle', 'junior', 'junk', 'just', 'kangaroo', 'keen', 'keep', 'ketchup', 'key',
      'kick', 'kid', 'kidney', 'kind', 'kingdom', 'kiss', 'kit', 'kitchen', 'kite', 'kitten', 'kiwi', 'knee', 'knife',
      'knock', 'know', 'lab', 'label', 'labor', 'ladder', 'lady', 'lake', 'lamp', 'language', 'laptop', 'large', 'later',
      'latin', 'laugh', 'laundry', 'lava', 'law', 'lawn', 'lawsuit', 'layer', 'lazy', 'leader', 'leaf', 'learn', 'leave',
      'lecture', 'left', 'leg', 'legal', 'legend', 'leisure', 'lemon', 'lend', 'length', 'lens', 'leopard', 'lesson',
      'letter', 'level', 'liar', 'liberty', 'library', 'license', 'life', 'lift', 'light', 'like', 'limb', 'limit', 'link',
      'lion', 'liquid', 'list', 'little', 'live', 'lizard', 'load', 'loan', 'lobster', 'local', 'lock', 'logic', 'lonely',
      'long', 'loop', 'lottery', 'loud', 'lounge', 'love', 'loyal', 'lucky', 'luggage', 'lumber', 'lunar', 'lunch', 'luxury',
      'lyrics', 'machine', 'mad', 'magic', 'magnet', 'maid', 'mail', 'main', 'major', 'make', 'mammal', 'man', 'manage', 'mandate',
      'mango', 'mansion', 'manual', 'maple', 'marble', 'march', 'margin', 'marine', 'market', 'marriage', 'mask', 'mass',
      'master', 'match', 'material', 'math', 'matrix', 'matter', 'maximum', 'maze', 'meadow', 'mean', 'measure', 'meat',
      'mechanic', 'medal', 'media', 'melody', 'melt', 'member', 'memory', 'mention', 'menu', 'mercy', 'merge', 'merit',
      'merry', 'mesh', 'message', 'metal', 'method', 'middle', 'midnight', 'milk', 'million', 'mimic', 'mind', 'minimum',
      'minute', 'miracle', 'mirror', 'misery', 'miss', 'mistake', 'mix', 'mixed', 'mixture', 'mobile', 'model', 'modify',
      'mom', 'moment', 'monitor', 'monkey', 'monster', 'month', 'moon', 'moral', 'more', 'morning', 'mosquito', 'mother',
      'motion', 'motor', 'mountain', 'mouse', 'move', 'movie', 'much', 'muffin', 'mule', 'multiply', 'muscle', 'museum',
      'mushroom', 'music', 'must', 'mutual', 'myself', 'mystery', 'myth', 'naive', 'name', 'napkin', 'narrow', 'nasty',
      'nation', 'nature', 'near', 'neck', 'need', 'negative', 'neglect', 'neither', 'nephew', 'nerve', 'nest', 'net', 'network',
      'neutral', 'never', 'news', 'next', 'nice', 'night', 'noble', 'noise', 'nominee', 'noodle', 'normal', 'north', 'nose',
      'notable', 'note', 'nothing', 'notice', 'novel', 'now', 'nuclear', 'number', 'nurse', 'nut', 'oak', 'obey', 'object',
      'oblige', 'obscure', 'observe', 'obtain', 'obvious', 'occur', 'ocean', 'october', 'odor', 'off', 'offer', 'office',
      'often', 'oil', 'okay', 'old', 'olive', 'olympic', 'omit', 'once', 'one', 'onion', 'online', 'only', 'open', 'opera',
      'opinion', 'oppose', 'option', 'orange', 'orbit', 'orchard', 'order', 'ordinary', 'organ', 'orient', 'original', 'orphan',
      'ostrich', 'other', 'outdoor', 'outer', 'output', 'outside', 'oval', 'oven', 'over', 'own', 'owner', 'oxygen', 'oyster',
      'ozone', 'pact', 'paddle', 'page', 'pair', 'palace', 'palm', 'pancake', 'panda', 'panel', 'panic', 'panther', 'paper',
      'parade', 'parent', 'park', 'parrot', 'party', 'pass', 'patch', 'path', 'patient', 'patrol', 'pattern', 'pause', 'pave',
      'payment', 'peace', 'peanut', 'pear', 'peasant', 'pelican', 'pen', 'penalty', 'pencil', 'people', 'pepper', 'perfect',
      'permit', 'person', 'pet', 'phone', 'photo', 'phrase', 'physical', 'piano', 'picnic', 'picture', 'piece', 'pig', 'pigeon',
      'pill', 'pilot', 'pink', 'pioneer', 'pipe', 'pistol', 'pitch', 'pizza', 'place', 'planet', 'plastic', 'plate', 'play',
      'please', 'pledge', 'pluck', 'plug', 'plunge', 'poem', 'poet', 'point', 'polar', 'pole', 'police', 'pond', 'pony', 'pool',
      'popular', 'portion', 'position', 'possible', 'post', 'potato', 'pottery', 'poverty', 'powder', 'power', 'practice', 'praise',
      'predict', 'prefer', 'prepare', 'present', 'pretty', 'prevent', 'price', 'pride', 'primary', 'print', 'priority', 'prison',
      'private', 'prize', 'problem', 'process', 'produce', 'profit', 'program', 'project', 'promote', 'proof', 'property', 'prosper',
      'protect', 'proud', 'provide', 'public', 'pudding', 'pull', 'pulp', 'pulse', 'pumpkin', 'punch', 'pupil', 'puppet', 'puppy',
      'purchase', 'purity', 'purpose', 'purse', 'push', 'put', 'puzzle', 'pyramid', 'quality', 'quantum', 'quarter', 'question',
      'quick', 'quit', 'quiz', 'quote', 'rabbit', 'raccoon', 'race', 'rack', 'radar', 'radio', 'rain', 'raise', 'rally', 'ramp',
      'ranch', 'random', 'range', 'rapid', 'rare', 'rate', 'rather', 'raven', 'raw', 'reach', 'react', 'read', 'real', 'reason',
      'rebel', 'rebuild', 'receipt', 'receive', 'recipe', 'record', 'recycle', 'red', 'reduce', 'reflect', 'reform', 'refuge',
      'refuse', 'region', 'regret', 'regular', 'reject', 'relax', 'release', 'relief', 'rely', 'remain', 'remember', 'remind',
      'remote', 'remove', 'render', 'renew', 'rent', 'reopen', 'repair', 'repeat', 'replace', 'reply', 'report', 'represent',
      'reptile', 'require', 'rescue', 'resemble', 'resist', 'resource', 'response', 'result', 'retire', 'retreat', 'return',
      'reunion', 'reveal', 'review', 'reward', 'rhythm', 'rib', 'rice', 'rich', 'ride', 'ridge', 'rifle', 'right', 'rigid',
      'ring', 'riot', 'ripple', 'risk', 'ritual', 'rival', 'river', 'road', 'roast', 'robot', 'robust', 'rocket', 'romance',
      'roof', 'rookie', 'room', 'rose', 'rotate', 'rough', 'round', 'route', 'royal', 'rubber', 'rude', 'rug', 'rule', 'run',
      'runway', 'rural', 'sad', 'saddle', 'sadness', 'sail', 'salad', 'salmon', 'salon', 'salt', 'salute', 'same', 'sample',
      'sand', 'satisfy', 'satoshi', 'sauce', 'sausage', 'save', 'say', 'scale', 'scan', 'scare', 'scatter', 'scene', 'scheme',
      'school', 'science', 'scissors', 'scorpion', 'scout', 'scrap', 'screen', 'script', 'scrub', 'sea', 'search', 'season',
      'seat', 'second', 'secret', 'section', 'security', 'seed', 'seek', 'segment', 'select', 'sell', 'seminar', 'senior',
      'sense', 'sentence', 'series', 'service', 'session', 'settle', 'setup', 'seven', 'shadow', 'shaft', 'shallow', 'share',
      'shed', 'shell', 'sheriff', 'shield', 'shine', 'ship', 'shiver', 'shock', 'shoe', 'shoot', 'shop', 'short', 'shoulder',
      'shove', 'shrimp', 'shrug', 'shuffle', 'shy', 'sibling', 'sick', 'side', 'siege', 'sight', 'sign', 'silent', 'silk',
      'silly', 'silver', 'similar', 'simple', 'since', 'sing', 'siren', 'sister', 'situation', 'six', 'size', 'skate', 'sketch',
      'ski', 'skill', 'skin', 'skirt', 'skull', 'slab', 'slam', 'sleep', 'slender', 'slice', 'slide', 'slight', 'slim', 'slogan',
      'slot', 'slow', 'slush', 'small', 'smart', 'smile', 'smoke', 'smooth', 'snack', 'snake', 'snap', 'sniff', 'snow', 'soap',
      'soccer', 'social', 'sock', 'soda', 'soft', 'solar', 'soldier', 'solid', 'solution', 'solve', 'someone', 'song', 'soon',
      'sorry', 'sort', 'soul', 'sound', 'soup', 'source', 'south', 'space', 'spare', 'spatial', 'spawn', 'speak', 'special',
      'speed', 'spell', 'spend', 'sphere', 'spice', 'spider', 'spike', 'spin', 'spirit', 'split', 'spoil', 'sponsor', 'spoon',
      'sport', 'spot', 'spray', 'spread', 'spring', 'spy', 'square', 'squeeze', 'squirrel', 'stable', 'stadium', 'staff', 'stage',
      'stairs', 'stamp', 'stand', 'start', 'state', 'stay', 'steak', 'steel', 'stem', 'step', 'stereo', 'stick', 'still',
      'sting', 'stock', 'stomach', 'stone', 'stool', 'story', 'stove', 'strategy', 'street', 'strike', 'strong', 'struggle',
      'student', 'stuff', 'stumble', 'style', 'subject', 'submit', 'subway', 'success', 'such', 'sudden', 'suffer', 'sugar',
      'suggest', 'suit', 'summer', 'sun', 'sunny', 'sunset', 'super', 'supply', 'supreme', 'sure', 'surface', 'surge', 'surprise',
      'surround', 'survey', 'suspect', 'sustain', 'swallow', 'swamp', 'swap', 'swarm', 'swear', 'sweet', 'swift', 'swim', 'swing',
      'switch', 'sword', 'symbol', 'symptom', 'syrup', 'system', 'table', 'tackle', 'tag', 'tail', 'talent', 'talk', 'tank',
      'tape', 'target', 'task', 'taste', 'tattoo', 'taxi', 'teach', 'team', 'tell', 'ten', 'tenant', 'tennis', 'tent', 'term',
      'test', 'text', 'thank', 'that', 'theme', 'then', 'theory', 'there', 'they', 'thing', 'this', 'thought', 'three', 'thrive',
      'throw', 'thumb', 'thunder', 'ticket', 'tide', 'tiger', 'tilt', 'timber', 'time', 'tiny', 'tip', 'tired', 'tissue', 'title',
      'toast', 'tobacco', 'today', 'toddler', 'toe', 'together', 'toilet', 'token', 'tomato', 'tomorrow', 'tone', 'tongue', 'tonight',
      'tool', 'tooth', 'top', 'topic', 'topple', 'torch', 'tornado', 'tortoise', 'toss', 'total', 'tourist', 'toward', 'tower',
      'town', 'toy', 'track', 'trade', 'traffic', 'tragic', 'train', 'transfer', 'trap', 'trash', 'travel', 'treat', 'tree',
      'trend', 'trial', 'tribe', 'trick', 'trigger', 'trim', 'trip', 'trophy', 'trouble', 'truck', 'true', 'truly', 'trumpet', 'trust',
      'truth', 'try', 'tube', 'tuition', 'tumble', 'tuna', 'tunnel', 'turkey', 'turn', 'turtle', 'twelve', 'twenty', 'twice', 'twin',
      'twist', 'two', 'type', 'typical', 'ugly', 'umbrella', 'unable', 'unaware', 'uncle', 'uncover', 'under', 'undo', 'unfair',
      'unfold', 'unhappy', 'uniform', 'unique', 'unit', 'universe', 'unknown', 'unlock', 'until', 'unusual', 'unveil', 'update',
      'upgrade', 'uphold', 'upon', 'upper', 'upset', 'urban', 'urge', 'usage', 'use', 'used', 'useful', 'useless', 'usual',
      'utility', 'vacant', 'vacuum', 'vague', 'valid', 'valley', 'valve', 'van', 'vanish', 'vapor', 'various', 'vegan',
      'velvet', 'vendor', 'venture', 'venue', 'verb', 'verify', 'version', 'very', 'vessel', 'veteran', 'viable', 'vibrant',
      'vicious', 'victory', 'video', 'view', 'village', 'vintage', 'violin', 'virtual', 'virus', 'visa', 'visit', 'visual',
      'vital', 'vivid', 'vocal', 'voice', 'void', 'volcano', 'volume', 'vote', 'voyage', 'wage', 'wagon', 'wait', 'walk', 'wall',
      'walnut', 'want', 'war', 'warm', 'warrior', 'wash', 'wasp', 'waste', 'water', 'wave', 'way', 'wealth', 'weapon', 'wear',
      'weasel', 'weather', 'web', 'wedding', 'weekend', 'weird', 'welcome', 'west', 'wet', 'whale', 'what', 'wheat', 'wheel',
      'when', 'where', 'whip', 'whisper', 'wide', 'width', 'wife', 'wild', 'will', 'win', 'window', 'wine', 'wing', 'wink',
      'winner', 'winter', 'wire', 'wisdom', 'wise', 'wish', 'witness', 'wolf', 'woman', 'wonder', 'wood', 'wool', 'word',
      'work', 'world', 'worry', 'worth', 'wrap', 'wreck', 'wrestle', 'wrist', 'write', 'wrong', 'yard', 'year', 'yellow', 'you',
      'young', 'youth', 'zebra', 'zero', 'zone', 'zoo',
    ];

    // Convert 256 bits to 11-bit indices (24 words)
    final words = <String>[];
    for (int i = 0; i < 24; i++) {
      final start = i * 11;
      final end = start + 11;

      // Extract 11 bits
      int value = 0;
      if (end <= 256) {
        for (int j = start; j < end; j++) {
          value = (value << 1) | ((entropy[j >> 3] >> (7 - (j % 8))) & 1);
        }
      } else {
        // Handle the last byte spanning across
        // Simplified for this implementation
        value = entropy[start % 32] % wordList.length;
      }

      words.add(wordList[value % wordList.length]);
    }

    return words.join(' ');
  }

  /// Convert entropy to Base32 format (RFC 4648)
  ///
  /// 256 bits will produce 52 Base32 characters
  String _entropyToBase32(Uint8List entropy) {
    const base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    String result = '';
    int buffer = 0;
    int bitsLeft = 0;

    for (final byte in entropy) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result += base32Alphabet[(buffer >> bitsLeft) & 0x1F];
      }
    }

    if (bitsLeft > 0) {
      result += base32Alphabet[(buffer << (5 - bitsLeft)) & 0x1F];
    }

    return result;
  }
}
