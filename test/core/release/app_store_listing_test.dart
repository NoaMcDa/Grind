import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/release/app_store_listing.dart';

void main() {
  group('AppStoreListingLimits', () {
    test('matches App Store Connect field caps', () {
      // These numbers are the contract with App Store Connect and tests
      // elsewhere depend on them. Treat an edit here as a review of the
      // ASC help pages, not a typo fix.
      expect(AppStoreListingLimits.appNameMax, 30);
      expect(AppStoreListingLimits.subtitleMax, 30);
      expect(AppStoreListingLimits.promotionalTextMax, 170);
      expect(AppStoreListingLimits.keywordsMax, 100);
      expect(AppStoreListingLimits.descriptionMax, 4000);
    });
  });

  group('AppStoreListing.violations', () {
    test('is empty for a listing within every cap', () {
      const listing = AppStoreListing(
        name: 'Grind',
        subtitle: 'Goals, reminders, calendar',
        promotionalText: '',
        keywords: 'reminders,goals',
        description: 'A short description.',
        primaryCategory: 'Productivity',
      );
      expect(listing.violations(), isEmpty);
      expect(listing.isValid, isTrue);
    });

    test('names the field and the length for an over-long name', () {
      final listing = AppStoreListing(
        name: 'G' * 31,
        subtitle: 's',
        promotionalText: '',
        keywords: 'k',
        description: 'd',
        primaryCategory: 'Productivity',
      );
      expect(listing.isValid, isFalse);
      expect(listing.violations(), ['name is 31 characters, limit is 30.']);
    });

    test('reports every over-run, not just the first', () {
      final listing = AppStoreListing(
        name: 'G' * 31,
        subtitle: 's' * 31,
        promotionalText: 'p' * 171,
        keywords: 'k' * 101,
        description: 'd' * 4001,
        primaryCategory: 'Productivity',
      );
      final v = listing.violations();
      expect(v, hasLength(5));
      expect(v.any((m) => m.startsWith('name ')), isTrue);
      expect(v.any((m) => m.startsWith('subtitle ')), isTrue);
      expect(v.any((m) => m.startsWith('promotionalText ')), isTrue);
      expect(v.any((m) => m.startsWith('keywords ')), isTrue);
      expect(v.any((m) => m.startsWith('description ')), isTrue);
    });

    test('exactly at the cap is accepted', () {
      final listing = AppStoreListing(
        name: 'G' * 30,
        subtitle: 's' * 30,
        promotionalText: 'p' * 170,
        keywords: 'k' * 100,
        description: 'd' * 4000,
        primaryCategory: 'Productivity',
      );
      expect(listing.isValid, isTrue);
    });

    test('does not flag unset promotional text or empty optional copy', () {
      const listing = AppStoreListing(
        name: 'Grind',
        subtitle: 'Goals',
        promotionalText: '',
        keywords: '',
        description: '',
        primaryCategory: 'Productivity',
      );
      expect(listing.violations(), isEmpty);
    });
  });

  group('AppStoreListing.keywordList', () {
    test('splits on commas, trims whitespace, drops empties', () {
      const listing = AppStoreListing(
        name: 'Grind',
        subtitle: 'Goals',
        promotionalText: '',
        keywords: 'reminders, goals ,,habit',
        description: '',
        primaryCategory: 'Productivity',
      );
      expect(listing.keywordList, ['reminders', 'goals', 'habit']);
    });

    test('is unmodifiable', () {
      const listing = AppStoreListing(
        name: 'Grind',
        subtitle: 'Goals',
        promotionalText: '',
        keywords: 'reminders,goals',
        description: '',
        primaryCategory: 'Productivity',
      );
      expect(() => listing.keywordList.add('nope'), throwsUnsupportedError);
    });
  });

  group('AppStoreListing.copyWith', () {
    const base = AppStoreListing(
      name: 'Grind',
      subtitle: 'Goals, reminders, calendar',
      promotionalText: '',
      keywords: 'reminders,goals',
      description: 'A short description.',
      primaryCategory: 'Productivity',
      secondaryCategory: 'Education',
    );

    test('swaps only the named field', () {
      final next = base.copyWith(name: 'Pip');
      expect(next.name, 'Pip');
      expect(next.subtitle, base.subtitle);
      expect(next.secondaryCategory, base.secondaryCategory);
    });

    test('clears the secondary category when passed null', () {
      final next = base.copyWith(secondaryCategory: null);
      expect(next.secondaryCategory, isNull);
    });

    test('keeps the secondary category when not mentioned', () {
      final next = base.copyWith(name: 'Pip');
      expect(next.secondaryCategory, 'Education');
    });
  });

  group('AppStoreListing equality', () {
    test('is by value', () {
      const a = AppStoreListing(
        name: 'Grind',
        subtitle: 's',
        promotionalText: '',
        keywords: 'k',
        description: 'd',
        primaryCategory: 'Productivity',
      );
      const b = AppStoreListing(
        name: 'Grind',
        subtitle: 's',
        promotionalText: '',
        keywords: 'k',
        description: 'd',
        primaryCategory: 'Productivity',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any text field differs', () {
      const a = AppStoreListing(
        name: 'Grind',
        subtitle: 's',
        promotionalText: '',
        keywords: 'k',
        description: 'd',
        primaryCategory: 'Productivity',
      );
      const b = AppStoreListing(
        name: 'Grind',
        subtitle: 's',
        promotionalText: '',
        keywords: 'k',
        description: 'different',
        primaryCategory: 'Productivity',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('grindAppStoreListingDraft', () {
    test('is within every App Store Connect cap', () {
      // If this fails after a copy edit, the offender is named — fix the
      // length before anyone tries to upload.
      expect(
        grindAppStoreListingDraft.violations(),
        isEmpty,
        reason: 'listing draft must fit App Store Connect field limits',
      );
    });

    test('uses the approved name and category from the handoff doc', () {
      expect(grindAppStoreListingDraft.name, 'Grind');
      expect(grindAppStoreListingDraft.primaryCategory, 'Productivity');
    });

    test('carries the 92-char keywords block from the listing doc', () {
      // The listing doc ships 12 keywords in a specific order; the
      // keyword list surfaces that same order.
      expect(grindAppStoreListingDraft.keywordList, [
        'reminders',
        'goals',
        'habit',
        'planner',
        'calendar',
        'focus',
        'to-do',
        'tasks',
        'routine',
        'productivity',
        'study',
        'fitness',
      ]);
    });

    test(
      'leaves promotional text empty until a <=170 char line is approved',
      () {
        // Intentional: a shorter promo line is still pending per
        // docs/release/app-store-listing.md. Shipping an empty string
        // beats shipping invented copy.
        expect(grindAppStoreListingDraft.promotionalText, isEmpty);
      },
    );

    test('description opens with the approved short copy from HANDOFF §4', () {
      expect(
        grindAppStoreListingDraft.description,
        startsWith('An iOS productivity app that syncs with your calendar'),
      );
    });
  });
}
