/// What a user without PRO — signed in or not — may open.
///
/// A taster, not a trial: enough of the real thing to judge whether the app is
/// worth paying for, without giving away the bank. Both lists live here rather
/// than in the screens that draw them, so the rule cannot drift between the
/// list, the badge on a tile, and the check that actually starts the test.
class FreeAccess {
  FreeAccess._();

  /// Exam tickets 1..5 open to everyone; 6..63 need PRO.
  static const int freeVariantCount = 5;

  static bool isVariantFree(int variantNumber) =>
      variantNumber >= 1 && variantNumber <= freeVariantCount;

  /// Topics open to everyone, by the id the website and this app share.
  ///
  ///   `1` — Umumiy qoidalar
  ///   `2` — Haydovchining umumiy vazifalari
  ///
  /// The two a learner starts with, and the two that make the least sense to
  /// charge for: someone who cannot open the general rules has no reason to
  /// believe the rest is any good.
  static const Set<String> freeTopicIds = {'1', '2'};

  static bool isTopicFree(String topicId) => freeTopicIds.contains(topicId);
}
