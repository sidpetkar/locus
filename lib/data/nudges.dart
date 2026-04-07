// Nudge template database for Memento Mori cycling headlines.
//
// Template markup:
//   *text* → bold span
//   \n     → explicit line break (2-line nudges only)
//
// Rules:
//   - Single-line nudges: ≤ ~20 chars total, rendered at 48px
//   - Two-line nudges: each line ≤ ~20 chars, rendered at 24px
//   - NEVER more than 2 lines — no long sentences that wrap on their own
//
// Placeholder tokens (resolved at runtime by NudgeService):
//   {month}       — current month name (April)
//   {year}        — current year (2026)
//   {daysLeft}    — days remaining in current month
//   {hoursLeft}   — whole hours remaining in current month
//   {dayOfWeek}   — current day of week name (Tuesday)
//   {nextDay}     — tomorrow's day name
//   {dayNumber}   — current day of month (7)
//   {daysGone}    — days elapsed in month so far
//   {weeksLeft}   — full weeks remaining in month
//   {monthsLeft}  — months remaining in the year
//   {timeOfDay}   — Morning / Afternoon / Evening / Night
//
// Context tags control when a nudge is eligible to appear:
//   'always'      — shown any time
//   'morning'     — 5am–11:59am
//   'afternoon'   — 12pm–5:59pm
//   'evening'     — 6pm–9:59pm
//   'night'       — 10pm–4:59am
//   'weekend'     — Sat–Sun
//   'pre_weekend' — Fri only
//   'pre_monday'  — Sun only
//   'month_start' — days 1–7
//   'month_mid'   — days 8–22
//   'month_end'   — days 23–last
//   'year_end'    — Oct–Dec

class NudgeTemplate {
  final String template;
  final List<String> contexts;

  const NudgeTemplate({required this.template, required this.contexts});
}

const List<NudgeTemplate> kNudgeTemplates = [
  // --- Hours / time remaining ---
  NudgeTemplate(
    template: '*{hoursLeft}hr* left\nfor *{month}*.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{daysLeft} days* left\nin *{month}*.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{daysLeft} days* left.\n*Make it count.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{daysGone}* gone.\n*{daysLeft}* remain.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{weeksLeft} weeks* left.\n*Ship something.*',
    contexts: ['always'],
  ),

  // --- Day of week awareness ---
  NudgeTemplate(
    template: '*{dayOfWeek}*\naround the corner.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Another *{dayOfWeek}*.\n*What will you build?*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{nextDay}* is coming.\n*Are you ready?*',
    contexts: ['evening', 'night'],
  ),
  NudgeTemplate(
    template: 'Friday closes.\n*Make hours count.*',
    contexts: ['pre_weekend'],
  ),
  NudgeTemplate(
    template: '*Weekend* ahead.\n*Rest, then attack.*',
    contexts: ['pre_weekend'],
  ),
  NudgeTemplate(
    template: '*Weekend* is fuel.\n*Monday demands.*',
    contexts: ['weekend'],
  ),
  NudgeTemplate(
    template: '*Sunday* rehearsal.\n*Monday is the show.*',
    contexts: ['pre_monday'],
  ),
  NudgeTemplate(
    template: '*Monday* in 24hrs.\n*Plan tonight.*',
    contexts: ['pre_monday'],
  ),

  // --- Time of day awareness ---
  NudgeTemplate(
    template: '*Morning* in *{month}*.\n*Day won\'t wait.*',
    contexts: ['morning'],
  ),
  NudgeTemplate(
    template: 'Early *{month}*.\n*Claim the silence.*',
    contexts: ['morning'],
  ),
  NudgeTemplate(
    template: '*{timeOfDay}* in *{month}*.\n*Build something.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*Afternoon* half gone.\n*What did you finish?*',
    contexts: ['afternoon'],
  ),
  NudgeTemplate(
    template: 'Evening, day *{dayNumber}*.\n*Account for today.*',
    contexts: ['evening'],
  ),
  NudgeTemplate(
    template: 'Day *{dayNumber}* closing.\n*Did you move?*',
    contexts: ['evening', 'night'],
  ),
  NudgeTemplate(
    template: 'Night, day *{dayNumber}*.\n*Tomorrow starts now.*',
    contexts: ['night'],
  ),

  // --- Month progress ---
  NudgeTemplate(
    template: '*{monthsLeft}* months left.\n*Act.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Day *{dayNumber}* of *{month}*.\n*Every one counts.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{month}*: *{daysGone}* gone,\n*{daysLeft}* to go.',
    contexts: ['month_mid'],
  ),
  NudgeTemplate(
    template: '*{month}* almost over.\n*Finish strong.*',
    contexts: ['month_end'],
  ),
  NudgeTemplate(
    template: '*{daysLeft} days* left.\n*Leave nothing pending.*',
    contexts: ['month_end'],
  ),
  NudgeTemplate(
    template: '*{month}* just started.\n*{daysLeft}* days. Go.*',
    contexts: ['month_start'],
  ),
  NudgeTemplate(
    template: 'First week of *{month}*.\n*Set the trajectory.*',
    contexts: ['month_start'],
  ),

  // --- Year-end urgency ---
  NudgeTemplate(
    template: '*Q4* of *{year}*.\n*Last sprint. Run.*',
    contexts: ['year_end'],
  ),
  NudgeTemplate(
    template: '*{year}* is closing.\n*{monthsLeft}* months left.*',
    contexts: ['year_end'],
  ),
  NudgeTemplate(
    template: 'End of *{year}*.\n*Finish what you started.*',
    contexts: ['year_end'],
  ),

  // --- Existence / high-agency memento mori ---
  NudgeTemplate(
    template: '*This hour* is yours\nto spend or waste.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Time doesn\'t wait.\n*Neither should you.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Each *{month}* day\n*is a one-time offer.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{month} {year}*.\n*Won\'t get it back.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Regret is heavy.\n*Action is lighter.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'The clock moved.\n*Did you?*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*Presence* is power.\n*{month}* is now.',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Another *{dayOfWeek}*.\n*Not a rehearsal.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{daysLeft} days*.\n*Same 24hrs. Choose.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{month}* is the margin.\n*Use it.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Comfort compounds.\n*So does effort.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'No one remembers\n*who played it safe.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{daysGone}* days spent.\n*What was built?*',
    contexts: ['month_mid', 'month_end'],
  ),
  NudgeTemplate(
    template: 'Your future self\n*is watching today.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{month}* hours:\n*non-refundable.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'The gap is between\n*thinking and doing.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*Show up* today.\n*Future you will know.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: 'Best time was then.\n*Next best is now.*',
    contexts: ['always'],
  ),
  NudgeTemplate(
    template: '*{month}* won\'t repeat.\n*Neither will today.*',
    contexts: ['always'],
  ),
];
