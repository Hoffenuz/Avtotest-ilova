/// Text normalisation for every search box in the app.
///
/// THE APOSTROPHE PROBLEM (docs/MOBILE-CONTENT-PROMPT.md §6.3): the question
/// bank mixes apostrophe characters. Question and answer text uses the
/// straight `'` throughout; explanations use both it and the curly `'`, in
/// roughly equal measure — about 4,800 of one against 3,600 of the other.
/// `o'q` and `o'q` are therefore different strings, and a search that compares
/// them literally finds whichever form the typist did not use: nothing.
///
/// Rewriting 8,000+ stored strings is not a change to make unasked, and it
/// would not help anyway — the user typing on a phone keyboard produces
/// whatever their layout emits, which may be a third character again. Folding
/// at comparison time fixes it for good and touches no data.
///
/// `ʻ` (U+02BB) and `ʼ` (U+02BC) are in the list because they are the
/// *correct* characters for Uzbek Latin o'/g', and several keyboards produce
/// them; `´` and `′` because they are common mistypes for the same key.
library;

final RegExp _apostrophes = RegExp("[‘’ʻʼ´′`]");

/// Lower-cased, with every apostrophe variant folded to the straight `'`.
/// Apply to BOTH sides of a comparison — the query and the stored text.
String foldForSearch(String value) =>
    value.toLowerCase().replaceAll(_apostrophes, "'");
