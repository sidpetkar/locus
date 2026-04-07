// Memento Mori page nudge templates — filter-specific.
//
// Each nudge explains what the dots represent and relates to the user's
// age / time remaining in the context of the active filter.
//
// Same markup rules as nudges.dart:
//   *text* → bold span
//   \n     → line break (max 2 lines, each ≤ ~20 chars)
//
// Placeholders:
//   {age}          — user's current age in years
//   {weeksLived}   — total weeks lived
//   {weeksLeft}    — weeks remaining (out of 80yr lifespan)
//   {yearsLeft}    — years remaining to 80
//   {decadeStart}  — starting age of current decade (e.g. 20)
//   {decadeEnd}    — ending age of current decade (e.g. 29)
//   {decadeWeeksLeft} — weeks remaining in current decade
//   {yearWeeksGone}   — weeks used in current year of age
//   {yearWeeksLeft}   — weeks remaining in current year of age

class MoriNudgeTemplate {
  final String template;
  final String filter; // 'lifetime', 'decade', 'year'

  const MoriNudgeTemplate({required this.template, required this.filter});
}

const List<MoriNudgeTemplate> kMoriNudgeTemplates = [
  // ── LIFETIME ─────────────────────────────────────────────────────────────
  // Each dot = 1 week. 80 rows × 52 cols = 4160 weeks.
  MoriNudgeTemplate(
    template: 'Each dot is *one week*.\n*{weeksLived}* are behind you.',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: '*{weeksLeft}* weeks remain\nout of *4160*.',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: '*80 rows*. *52 dots* each.\nOne row per year.',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: 'Filled dots: *lived*.\nEmpty: *still ahead.*',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: '*{age} rows* filled.\n*{yearsLeft}* rows to go.',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: 'Your life in *weeks*.\n*Every dot counts.*',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: '*{weeksLived}* weeks spent.\n*How many mattered?*',
    filter: 'lifetime',
  ),
  MoriNudgeTemplate(
    template: 'Scroll down to see\n*what\'s left.*',
    filter: 'lifetime',
  ),

  // ── DECADE ───────────────────────────────────────────────────────────────
  // 10 rows for ages decadeStart..decadeEnd, 52 dots each.
  MoriNudgeTemplate(
    template: 'Your *{decadeStart}s*.\n*10 rows, 52 dots each.*',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: 'Each row is *one year*\nof your *{decadeStart}s*.',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: 'Age *{age}* row is\n*your current year.*',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: '*{decadeWeeksLeft}* weeks left\nin your *{decadeStart}s*.',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: 'Filled: *weeks lived*.\nEmpty: *weeks ahead.*',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: 'Bold row = *age {age}*.\n*That\'s you, now.*',
    filter: 'decade',
  ),
  MoriNudgeTemplate(
    template: '*520 weeks* per decade.\n*Make this one count.*',
    filter: 'decade',
  ),

  // ── YEAR ─────────────────────────────────────────────────────────────────
  // 52 dots (4 rows × 13) for the current year of life.
  MoriNudgeTemplate(
    template: '*52 dots*. One per week\nof age *{age}*.',
    filter: 'year',
  ),
  MoriNudgeTemplate(
    template: '*{yearWeeksGone}* weeks used.\n*{yearWeeksLeft}* weeks left.',
    filter: 'year',
  ),
  MoriNudgeTemplate(
    template: '*4 rows* of 13 dots.\nOne row per quarter.',
    filter: 'year',
  ),
  MoriNudgeTemplate(
    template: 'Your year at *{age}*.\n*Each dot = 1 week.*',
    filter: 'year',
  ),
  MoriNudgeTemplate(
    template: 'Filled: *past weeks*.\nEmpty: *your runway.*',
    filter: 'year',
  ),
  MoriNudgeTemplate(
    template: '*{yearWeeksLeft} weeks* left\nat age *{age}*. Go.',
    filter: 'year',
  ),
];
