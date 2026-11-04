/// App Store Connect listing metadata as a typed, validated value object
/// (epic #48).
///
/// App Store Connect has fixed character limits on every text field a
/// submission fills in (app name 30, subtitle 30, promotional text 170,
/// keywords 100, description 4 000). The copy itself lives in
/// `docs/release/app-store-listing.md` and
/// `docs/handoff/HANDOFF.md` §4; this file turns that prose into a Dart
/// value so:
///
///   * One place enforces the limits, with tests that fail on any over-run
///     before a human notices at submission time.
///   * The approved copy becomes importable from any screen that needs it
///     (e.g. a future in-app "About" card that mirrors the listing text),
///     instead of being re-typed into another `const String`.
///   * A future `fastlane deliver` call can read the same constants rather
///     than keeping a parallel set of `.txt` files that drift from the
///     repo's source of truth.
///
/// Scope: pure Dart, no I/O, no plugins. Nothing here reads a file, hits a
/// network, or touches the App Store Connect API — those steps belong to
/// the fastlane / `deliver` side of the pipeline.
library;

/// App Store Connect text-field length caps, in characters.
///
/// Sources (all public): App Store Connect help "App information" and
/// "Version information" pages. The numbers below match the fields
/// Grind's submission will fill in and are the ones the
/// [AppStoreListing.violations] check compares against.
///
/// "Characters" here means `String.length` (UTF-16 code units), the same
/// count App Store Connect displays next to each field.
class AppStoreListingLimits {
  const AppStoreListingLimits._();

  /// App name cap (30). The name shown under the icon on the device home
  /// screen and in search results.
  static const int appNameMax = 30;

  /// Subtitle cap (30). One line under the name on the product page.
  static const int subtitleMax = 30;

  /// Promotional text cap (170). The grey block above the description on
  /// the product page, editable without a new build.
  static const int promotionalTextMax = 170;

  /// Keywords field cap (100). One comma-separated string; Apple
  /// recommends omitting spaces after commas to save budget.
  static const int keywordsMax = 100;

  /// Description cap (4 000). The long body text.
  static const int descriptionMax = 4000;
}

/// One version's worth of App Store Connect text fields.
///
/// Immutable. Equality is by value so tests can compare whole listings
/// without poking at fields. Build via the default constructor with every
/// value explicit, or copy an existing listing with [copyWith].
///
/// The constructor does not throw on an over-long field: use
/// [violations] (or [isValid]) to check. That split keeps the type
/// compile-time-constant friendly (`const AppStoreListing(...)`) while
/// still letting a release step refuse to upload copy that would be
/// rejected by App Store Connect.
class AppStoreListing {
  const AppStoreListing({
    required this.name,
    required this.subtitle,
    required this.promotionalText,
    required this.keywords,
    required this.description,
    required this.primaryCategory,
    this.secondaryCategory,
    this.privacyPolicyUrl,
    this.supportUrl,
    this.marketingUrl,
  });

  /// App name (≤ [AppStoreListingLimits.appNameMax]).
  final String name;

  /// Subtitle, one line under the name
  /// (≤ [AppStoreListingLimits.subtitleMax]).
  final String subtitle;

  /// Promotional text shown above the description
  /// (≤ [AppStoreListingLimits.promotionalTextMax]). May be empty when no
  /// shorter promo line has been approved yet.
  final String promotionalText;

  /// Keywords field, one comma-separated string
  /// (≤ [AppStoreListingLimits.keywordsMax]). Apple recommends omitting
  /// spaces after commas to save characters. See [keywordList] for a
  /// parsed view.
  final String keywords;

  /// Long description (≤ [AppStoreListingLimits.descriptionMax]).
  final String description;

  /// App Store primary category (e.g. "Productivity"). Not length-capped
  /// by App Store Connect — it is picked from a fixed dropdown — so no
  /// limit is enforced here.
  final String primaryCategory;

  /// Optional App Store secondary category, from the same dropdown.
  final String? secondaryCategory;

  /// Privacy policy URL (required at submission under guideline 5.1.1).
  final Uri? privacyPolicyUrl;

  /// Support URL (required at submission).
  final Uri? supportUrl;

  /// Optional marketing URL.
  final Uri? marketingUrl;

  /// The [keywords] field split on commas, trimmed, with empty entries
  /// dropped. Order is preserved. Convenience for an in-app or test view
  /// that wants the list of terms rather than the packed string.
  List<String> get keywordList {
    final out = <String>[];
    for (final raw in keywords.split(',')) {
      final k = raw.trim();
      if (k.isNotEmpty) out.add(k);
    }
    return List.unmodifiable(out);
  }

  /// Every way this listing would be rejected by App Store Connect for
  /// length, as a list of human-readable messages. Empty when the listing
  /// is within every cap, including when fields are empty.
  ///
  /// This checks only the text-length caps in [AppStoreListingLimits]. It
  /// does NOT check that required fields (description, privacy policy
  /// URL, support URL) are filled in, nor that the copy meets App Store
  /// Review Guidelines — those are separate concerns.
  List<String> violations() {
    final out = <String>[];
    void check(String field, String value, int max) {
      if (value.length > max) {
        out.add(
          '$field is ${value.length} characters, limit is $max.',
        );
      }
    }

    check('name', name, AppStoreListingLimits.appNameMax);
    check('subtitle', subtitle, AppStoreListingLimits.subtitleMax);
    check(
      'promotionalText',
      promotionalText,
      AppStoreListingLimits.promotionalTextMax,
    );
    check('keywords', keywords, AppStoreListingLimits.keywordsMax);
    check('description', description, AppStoreListingLimits.descriptionMax);
    return out;
  }

  /// True when [violations] is empty. See its doc for what that means.
  bool get isValid => violations().isEmpty;

  AppStoreListing copyWith({
    String? name,
    String? subtitle,
    String? promotionalText,
    String? keywords,
    String? description,
    String? primaryCategory,
    Object? secondaryCategory = _unset,
    Object? privacyPolicyUrl = _unset,
    Object? supportUrl = _unset,
    Object? marketingUrl = _unset,
  }) => AppStoreListing(
    name: name ?? this.name,
    subtitle: subtitle ?? this.subtitle,
    promotionalText: promotionalText ?? this.promotionalText,
    keywords: keywords ?? this.keywords,
    description: description ?? this.description,
    primaryCategory: primaryCategory ?? this.primaryCategory,
    secondaryCategory: identical(secondaryCategory, _unset)
        ? this.secondaryCategory
        : secondaryCategory as String?,
    privacyPolicyUrl: identical(privacyPolicyUrl, _unset)
        ? this.privacyPolicyUrl
        : privacyPolicyUrl as Uri?,
    supportUrl: identical(supportUrl, _unset)
        ? this.supportUrl
        : supportUrl as Uri?,
    marketingUrl: identical(marketingUrl, _unset)
        ? this.marketingUrl
        : marketingUrl as Uri?,
  );

  static const _unset = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppStoreListing) return false;
    return name == other.name &&
        subtitle == other.subtitle &&
        promotionalText == other.promotionalText &&
        keywords == other.keywords &&
        description == other.description &&
        primaryCategory == other.primaryCategory &&
        secondaryCategory == other.secondaryCategory &&
        privacyPolicyUrl == other.privacyPolicyUrl &&
        supportUrl == other.supportUrl &&
        marketingUrl == other.marketingUrl;
  }

  @override
  int get hashCode => Object.hash(
    name,
    subtitle,
    promotionalText,
    keywords,
    description,
    primaryCategory,
    secondaryCategory,
    privacyPolicyUrl,
    supportUrl,
    marketingUrl,
  );

  @override
  String toString() =>
      'AppStoreListing(name: $name, subtitle: $subtitle, '
      'promotionalText: ${promotionalText.length} chars, '
      'keywords: $keywords, '
      'description: ${description.length} chars, '
      'primaryCategory: $primaryCategory, '
      'secondaryCategory: $secondaryCategory)';
}

/// The current Grind listing draft, seeded from
/// `docs/release/app-store-listing.md` (which is itself sourced from
/// `docs/handoff/HANDOFF.md` §4).
///
/// Fields that still have "TODO(Noa)" against them in the doc — the long
/// description body past the opening paragraph, and the promo line that
/// fits inside 170 characters — are left empty here so an accidental
/// submission would not ship unapproved copy. [AppStoreListing.violations]
/// returns `[]` for this value; tests assert that in both directions so
/// over-runs surface at CI time rather than at upload time.
///
/// The 314-character opening sentence IS the approved short copy from
/// HANDOFF §4 and comfortably fits the 4 000-character description cap,
/// so it's parked there as the first paragraph per the doc's note.
const AppStoreListing grindAppStoreListingDraft = AppStoreListing(
  name: 'Grind',
  subtitle: 'Goals, reminders, calendar',
  // Left empty: the doc calls out that a shorter (<= 170 char) promo line
  // still needs to be written from the 314-char short description. Ship
  // nothing rather than ship invented copy.
  promotionalText: '',
  // 91 chars, well inside the 100-char cap. Order and spelling match
  // docs/release/app-store-listing.md.
  keywords:
      'reminders,goals,habit,planner,calendar,focus,to-do,tasks,'
      'routine,productivity,study,fitness',
  // The approved 314-char short description from HANDOFF §4, used as the
  // opening paragraph per the note in docs/release/app-store-listing.md.
  // The remaining ~300-word body is still pending — see the TODO in that
  // doc — and will land in a follow-up change once approved.
  description:
      'An iOS productivity app that syncs with your calendar, sends '
      'smart reminders, and tracks short- and long-term goals across '
      'learning, investing, fitness and nutrition. See progress as X of '
      "Y or weekly counts, get highlights, learn what's realistic this "
      'week, and let an encouraging AI assistant help you prioritize.',
  primaryCategory: 'Productivity',
  // Secondary is still open between Health & Fitness and Education per
  // the doc; leave unset so a future edit picks one deliberately.
);
