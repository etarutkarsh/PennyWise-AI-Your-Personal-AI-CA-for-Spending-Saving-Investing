import '../../domain/engines/merchant_resolver.dart';
import '../../domain/ingestion/merchant_profile.dart';

/// Indian merchant identity resolution — the Financial Identity Resolution Engine.
/// Resolves alias strings to canonical MerchantProfiles.
///
/// All comparisons are case-insensitive and strip punctuation.
/// Order: exact alias match → prefix match → substring match → UnknownMerchantProfile.
class HardcodedMerchantResolver implements MerchantResolver {
  const HardcodedMerchantResolver();

  static const _kVersion = 'merchant-resolver-hardcoded-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  MerchantProfile resolve(String rawMerchant) {
    final normalized = _normalize(rawMerchant);
    if (normalized.isEmpty) return UnknownMerchantProfile(rawMerchant);

    // 1. Exact alias match
    for (final profile in allProfiles) {
      for (final alias in profile.aliases) {
        if (_normalize(alias) == normalized) return profile;
      }
    }

    // 2. Prefix match (alias starts with normalized or normalized starts with alias)
    for (final profile in allProfiles) {
      for (final alias in profile.aliases) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.isNotEmpty &&
            (normalized.startsWith(normalizedAlias) ||
             normalizedAlias.startsWith(normalized))) {
          return profile;
        }
      }
    }

    // 3. Substring match (alias appears in normalized string)
    for (final profile in allProfiles) {
      for (final alias in profile.aliases) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.length >= 4 && normalized.contains(normalizedAlias)) {
          return profile;
        }
      }
    }

    return UnknownMerchantProfile(rawMerchant);
  }

  static String _normalize(String s) =>
      s.toLowerCase()
       .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
       .replaceAll(RegExp(r'\s+'), ' ')
       .trim();

  @override
  List<MerchantProfile> get allProfiles => _profiles;

  static final List<MerchantProfile> _profiles = [
    // ── Streaming ─────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'netflix',
      canonicalName: 'Netflix',
      category: MerchantCategory.streaming,
      aliases: ['NETFLIX', 'Netflix', 'NETFLIX INDIA', 'NETFLIX-MUM', 'NETFLIX.COM',
                 'Netflix India', 'netflixindia', 'netflix.com'],
      isSubscription: true,
      website: 'netflix.com',
      typicalMonthlyAmount: 499.0,
      upiHandles: {'netflix@icici', 'netflix@hdfcbank'},
    ),
    const MerchantProfile(
      id: 'amazon_prime',
      canonicalName: 'Amazon Prime',
      category: MerchantCategory.streaming,
      aliases: ['AMAZON PRIME', 'Amazon Prime', 'PRIME VIDEO', 'Prime Video',
                 'AMAZON PRIME VIDEO', 'PRIMEVIDEO', 'primevideo.com', 'amazon prime'],
      isSubscription: true,
      website: 'primevideo.com',
      typicalMonthlyAmount: 179.0,
    ),
    const MerchantProfile(
      id: 'disney_hotstar',
      canonicalName: 'Disney+ Hotstar',
      category: MerchantCategory.streaming,
      aliases: ['HOTSTAR', 'Hotstar', 'DISNEY HOTSTAR', 'Disney+ Hotstar',
                 'DISNEYPLUS', 'hotstar.com', 'DISNEY+HOTSTAR', 'JIO HOTSTAR'],
      isSubscription: true,
      typicalMonthlyAmount: 299.0,
    ),
    const MerchantProfile(
      id: 'zee5',
      canonicalName: 'ZEE5',
      category: MerchantCategory.streaming,
      aliases: ['ZEE5', 'Zee5', 'ZEE5 INDIA', 'zee5.com'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'sonyliv',
      canonicalName: 'SonyLIV',
      category: MerchantCategory.streaming,
      aliases: ['SONYLIV', 'SonyLIV', 'Sony LIV', 'SONY LIV', 'sonyliv.com'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'youtube_premium',
      canonicalName: 'YouTube Premium',
      category: MerchantCategory.streaming,
      aliases: ['YOUTUBE PREMIUM', 'Youtube Premium', 'YOUTUBE', 'youtube.com',
                 'GOOGLE YOUTUBE'],
      isSubscription: true,
      typicalMonthlyAmount: 139.0,
    ),

    // ── Music ─────────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'spotify',
      canonicalName: 'Spotify',
      category: MerchantCategory.musicStreaming,
      aliases: ['SPOTIFY', 'Spotify', 'SPOTIFY INDIA', 'spotify.com'],
      isSubscription: true,
      website: 'spotify.com',
      typicalMonthlyAmount: 119.0,
    ),

    // ── AI Services ───────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'openai_chatgpt',
      canonicalName: 'ChatGPT (OpenAI)',
      category: MerchantCategory.aiServices,
      aliases: ['OPENAI', 'OpenAI', 'CHATGPT', 'ChatGPT', 'openai.com',
                 'OPENAI CHATGPT', 'chat.openai.com'],
      isSubscription: true,
      website: 'openai.com',
      typicalMonthlyAmount: 1660.0,
      upiHandles: {'openai@stripe'},
    ),
    const MerchantProfile(
      id: 'anthropic_claude',
      canonicalName: 'Claude (Anthropic)',
      category: MerchantCategory.aiServices,
      aliases: ['ANTHROPIC', 'Anthropic', 'CLAUDE', 'claude.ai', 'anthropic.com'],
      isSubscription: true,
      website: 'anthropic.com',
      typicalMonthlyAmount: 1660.0,
    ),

    // ── Cloud Storage / Software ───────────────────────────────────────────────
    const MerchantProfile(
      id: 'google_one',
      canonicalName: 'Google One',
      category: MerchantCategory.cloudStorage,
      aliases: ['GOOGLE ONE', 'Google One', 'GOOGLE*ONE', 'one.google.com',
                 'GOOGLE STORAGE', 'Google Storage'],
      isSubscription: true,
      typicalMonthlyAmount: 130.0,
    ),
    const MerchantProfile(
      id: 'icloud',
      canonicalName: 'iCloud',
      category: MerchantCategory.cloudStorage,
      aliases: ['ICLOUD', 'iCloud', 'APPLE ICLOUD', 'icloud.com',
                 'APPLE.COM/IN/ICLOUD', 'APPLE STORAGE'],
      isSubscription: true,
      typicalMonthlyAmount: 75.0,
    ),
    const MerchantProfile(
      id: 'microsoft365',
      canonicalName: 'Microsoft 365',
      category: MerchantCategory.softwareSubscription,
      aliases: ['MICROSOFT 365', 'Microsoft 365', 'MICROSOFT OFFICE', 'OFFICE 365',
                 'microsoft.com', 'MSFT', 'MS365'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'adobe',
      canonicalName: 'Adobe',
      category: MerchantCategory.softwareSubscription,
      aliases: ['ADOBE', 'Adobe', 'ADOBE INC', 'adobe.com', 'ADOBE SYSTEMS',
                 'ADOBE CREATIVE', 'ADOBE CC'],
      isSubscription: true,
      website: 'adobe.com',
    ),
    const MerchantProfile(
      id: 'canva',
      canonicalName: 'Canva',
      category: MerchantCategory.softwareSubscription,
      aliases: ['CANVA', 'Canva', 'canva.com', 'CANVA PRO'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'github',
      canonicalName: 'GitHub',
      category: MerchantCategory.softwareSubscription,
      aliases: ['GITHUB', 'GitHub', 'github.com', 'GITHUB INC', 'GITHUB PRO',
                 'GITHUB COPILOT'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'notion',
      canonicalName: 'Notion',
      category: MerchantCategory.softwareSubscription,
      aliases: ['NOTION', 'Notion', 'notion.so', 'NOTION LABS'],
      isSubscription: true,
    ),

    // ── Food / Delivery ───────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'swiggy',
      canonicalName: 'Swiggy',
      category: MerchantCategory.food,
      aliases: ['SWIGGY', 'Swiggy', 'SWIGGY INSTAMART', 'swiggy.com',
                 'SWIGGY ONE', 'BUNDL TECHNOLOGIES'],
      website: 'swiggy.com',
    ),
    const MerchantProfile(
      id: 'zomato',
      canonicalName: 'Zomato',
      category: MerchantCategory.food,
      aliases: ['ZOMATO', 'Zomato', 'zomato.com', 'ZOMATO GOLD',
                 'ZOMATO LIMITED'],
      website: 'zomato.com',
    ),
    const MerchantProfile(
      id: 'blinkit',
      canonicalName: 'Blinkit',
      category: MerchantCategory.groceries,
      aliases: ['BLINKIT', 'Blinkit', 'GROFERS', 'blinkit.com',
                 'BLINKIT INDIA'],
    ),
    const MerchantProfile(
      id: 'zepto',
      canonicalName: 'Zepto',
      category: MerchantCategory.groceries,
      aliases: ['ZEPTO', 'Zepto', 'zepto.com', 'KIRANA KING'],
    ),

    // ── Transport ─────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'uber',
      canonicalName: 'Uber',
      category: MerchantCategory.transport,
      aliases: ['UBER', 'Uber', 'UBER INDIA', 'uber.com', 'UBER*TRIP'],
    ),
    const MerchantProfile(
      id: 'ola',
      canonicalName: 'Ola',
      category: MerchantCategory.transport,
      aliases: ['OLA', 'Ola', 'OLA CABS', 'olacabs.com', 'ANI TECHNOLOGIES',
                 'OLA ELECTRIC'],
    ),
    const MerchantProfile(
      id: 'rapido',
      canonicalName: 'Rapido',
      category: MerchantCategory.transport,
      aliases: ['RAPIDO', 'Rapido', 'rapido.bike'],
    ),

    // ── Banks (for transfers, not EMIs) ───────────────────────────────────────
    const MerchantProfile(
      id: 'hdfc_bank',
      canonicalName: 'HDFC Bank',
      category: MerchantCategory.bank,
      aliases: ['HDFC BANK', 'HDFC', 'HDFCBANK', 'hdfc.bank',
                 'HDFC BANK LTD', 'HDFC BANK LIMITED'],
      upiHandles: {'payzapp@hdfcbank', 'hdfc@hdfcbank'},
    ),
    const MerchantProfile(
      id: 'icici_bank',
      canonicalName: 'ICICI Bank',
      category: MerchantCategory.bank,
      aliases: ['ICICI BANK', 'ICICI', 'ICICIBANK', 'icici.bank',
                 'ICICI BANK LTD'],
    ),
    const MerchantProfile(
      id: 'sbi',
      canonicalName: 'State Bank of India',
      category: MerchantCategory.bank,
      aliases: ['SBI', 'STATE BANK OF INDIA', 'STATE BANK', 'SBIBANK',
                 'SBI BANK', 'SBICARDS'],
    ),
    const MerchantProfile(
      id: 'axis_bank',
      canonicalName: 'Axis Bank',
      category: MerchantCategory.bank,
      aliases: ['AXIS BANK', 'AXIS', 'AXISBANK', 'axis.bank', 'AXIS BANK LTD'],
    ),
    const MerchantProfile(
      id: 'kotak_bank',
      canonicalName: 'Kotak Mahindra Bank',
      category: MerchantCategory.bank,
      aliases: ['KOTAK', 'KOTAK BANK', 'KOTAK MAHINDRA', 'KOTAK MAHINDRA BANK',
                 'KMBL'],
    ),

    // ── Investments ───────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'groww',
      canonicalName: 'Groww',
      category: MerchantCategory.investment,
      aliases: ['GROWW', 'Groww', 'groww.in', 'NEXTBILLION TECH',
                 'GROWW MF', 'GROWW SIP'],
      isInvestment: true,
    ),
    const MerchantProfile(
      id: 'zerodha',
      canonicalName: 'Zerodha',
      category: MerchantCategory.investment,
      aliases: ['ZERODHA', 'Zerodha', 'zerodha.com', 'ZERODHA BROKING',
                 'ZERODHA KITE', 'ZERODA'],
      isInvestment: true,
    ),
    const MerchantProfile(
      id: 'kuvera',
      canonicalName: 'Kuvera',
      category: MerchantCategory.investment,
      aliases: ['KUVERA', 'Kuvera', 'kuvera.in', 'KUVERA MF'],
      isInvestment: true,
    ),
    const MerchantProfile(
      id: 'paytm_money',
      canonicalName: 'Paytm Money',
      category: MerchantCategory.investment,
      aliases: ['PAYTM MONEY', 'Paytm Money', 'paytmmoney.com',
                 'PAYTM WEALTH'],
      isInvestment: true,
    ),
    const MerchantProfile(
      id: 'nps',
      canonicalName: 'NPS (National Pension System)',
      category: MerchantCategory.investment,
      aliases: ['NPS', 'NATIONAL PENSION', 'NPSCRA', 'NPS CRA',
                 'NSDL CRA NPS', 'NPS CONTRIBUTION'],
      isInvestment: true,
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'ppf',
      canonicalName: 'PPF',
      category: MerchantCategory.investment,
      aliases: ['PPF', 'PUBLIC PROVIDENT FUND', 'PPF CONTRIBUTION',
                 'POST OFFICE PPF'],
      isInvestment: true,
    ),

    // ── Insurance ─────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'lic',
      canonicalName: 'LIC',
      category: MerchantCategory.insurance,
      aliases: ['LIC', 'LIFE INSURANCE CORPORATION', 'LIC OF INDIA',
                 'LIC INDIA', 'LIC PREMIUM'],
      isInsurance: true,
    ),
    const MerchantProfile(
      id: 'star_health',
      canonicalName: 'Star Health Insurance',
      category: MerchantCategory.insurance,
      aliases: ['STAR HEALTH', 'Star Health', 'STAR HEALTH INSURANCE',
                 'starhealth.in'],
      isInsurance: true,
    ),
    const MerchantProfile(
      id: 'hdfc_ergo',
      canonicalName: 'HDFC ERGO',
      category: MerchantCategory.insurance,
      aliases: ['HDFC ERGO', 'HDFC ERGO INSURANCE', 'hdfcergo.com'],
      isInsurance: true,
    ),
    const MerchantProfile(
      id: 'care_health',
      canonicalName: 'Care Health Insurance',
      category: MerchantCategory.insurance,
      aliases: ['CARE HEALTH', 'Care Health', 'RELIGARE HEALTH',
                 'carehealth.in', 'CARE HEALTH INSURANCE'],
      isInsurance: true,
    ),

    // ── Telecom ───────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'airtel',
      canonicalName: 'Airtel',
      category: MerchantCategory.mobile,
      aliases: ['AIRTEL', 'Airtel', 'BHARTI AIRTEL', 'airtel.in',
                 'AIRTEL RECHARGE', 'AIRTEL BROADBAND', 'AIRTEL PAYMENTS'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'jio',
      canonicalName: 'Reliance Jio',
      category: MerchantCategory.mobile,
      aliases: ['JIO', 'Jio', 'RELIANCE JIO', 'jio.com', 'JIO RECHARGE',
                 'JIO BROADBAND', 'JIO FIBER', 'JIOFIBER', 'RIL JIO'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'vi',
      canonicalName: 'Vi (Vodafone Idea)',
      category: MerchantCategory.mobile,
      aliases: ['VI', 'Vi', 'VODAFONE', 'IDEA', 'VODAFONE IDEA',
                 'VI RECHARGE', 'vodafoneidea.com'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'bsnl',
      canonicalName: 'BSNL',
      category: MerchantCategory.mobile,
      aliases: ['BSNL', 'bsnl.in', 'BSNL BROADBAND', 'BSNL RECHARGE'],
      isSubscription: true,
    ),

    // ── E-commerce ────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'amazon',
      canonicalName: 'Amazon',
      category: MerchantCategory.shopping,
      aliases: ['AMAZON', 'Amazon', 'amazon.in', 'amazon.com',
                 'AMAZON INDIA', 'AMAZON PAY', 'AMZN'],
    ),
    const MerchantProfile(
      id: 'flipkart',
      canonicalName: 'Flipkart',
      category: MerchantCategory.shopping,
      aliases: ['FLIPKART', 'Flipkart', 'flipkart.com', 'FLIPKART INTERNET',
                 'FK FASHION'],
    ),
    const MerchantProfile(
      id: 'myntra',
      canonicalName: 'Myntra',
      category: MerchantCategory.shopping,
      aliases: ['MYNTRA', 'Myntra', 'myntra.com', 'MYNTRA DESIGNS'],
    ),

    // ── Fitness ───────────────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'cult_fit',
      canonicalName: 'Cult.fit',
      category: MerchantCategory.fitness,
      aliases: ['CULT.FIT', 'CULT FIT', 'Cult.fit', 'cult.fit', 'CURE FIT',
                 'CUREFIT'],
      isSubscription: true,
    ),
    const MerchantProfile(
      id: 'healthifyme',
      canonicalName: 'HealthifyMe',
      category: MerchantCategory.fitness,
      aliases: ['HEALTHIFYME', 'HealthifyMe', 'healthifyme.com'],
      isSubscription: true,
    ),

    // ── Government / Tax ──────────────────────────────────────────────────────
    const MerchantProfile(
      id: 'income_tax',
      canonicalName: 'Income Tax',
      category: MerchantCategory.government,
      aliases: ['INCOME TAX', 'IT PAYMENT', 'TDS PAYMENT', 'ADVANCE TAX',
                 'NSDL TAX', 'ITR PAYMENT', 'INCOME TAX INDIA'],
    ),
    const MerchantProfile(
      id: 'epf',
      canonicalName: 'EPF / PF',
      category: MerchantCategory.epf,
      aliases: ['EPFO', 'EPF', 'PF CONTRIBUTION', 'PROVIDENT FUND',
                 'EMPLOYEES PROVIDENT FUND', 'PF DEDUCTION'],
    ),
  ];
}
