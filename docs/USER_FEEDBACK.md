# User Feedback — Real User (Lazybizbabe)
> Collected after first real install. This is gold. Treat every line as a design requirement.

---

## Raw Feedback (verbatim)

1. "I'll be very very honest"
2. "I'm not a tech person so my opinions may not be I dunno"
3. "But it looks obviously created by AI 🤢"
4. "I dunno especially d font give it more personality I guess"
5. "I actually like d features a lot but it's not sending reminders"
6. "D fonts are just one style and even size"
7. "D intro if I can call it that is 🤢🤢 — Maybe add some kind of animation 🤷"
8. "Also the streak counter make it bigger — Like I dunno how to describe it"
9. [Drew on screenshot] "Make this bigger" — pointing at streak/progress ring
10. "The d habit should be under — do u understand what I mean?" (habits list below progress)
11. "Yes d streak should be d first thing that catches ur eye — as a person who has over 20 productivity apps/habit trackers and adhd if I see my tasks first I get overwhelmed and stressed and I won't do anything so it's better if I see my progress first — My opinion"
12. "This is what made it very very obvious it was made with ai" (re: onboarding)
13. [You replied]: "Okay than just a classic onboarding we will use no fancy things"

---

## Translated Requirements

### 🎨 Design / Personality
| Complaint | Requirement |
|---|---|
| Looks AI-made | More human, opinionated design choices. Less "correct", more intentional. |
| Fonts one style/size | Real typographic hierarchy. Streak number = MASSIVE. Labels = small. Body = medium. Mix weights intentionally. |
| No personality | Bolder color usage, more contrast, less safe/grey |

### 🏠 Home Screen Hierarchy (MOST IMPORTANT)
| Current | Required |
|---|---|
| Progress ring → Habit list | Streak number HERO (giant, first thing seen) → Progress ring → Habit list |
| Streak shown inside card, small | Streak shown ABOVE everything, enormous |
| Tasks visible immediately | Progress/wins shown first. Tasks secondary. |

This is grounded in real ADHD UX research:
> Showing tasks first → overwhelm → paralysis → app abandoned
> Showing wins first → dopamine → motivation → action

### 📱 Onboarding
| Current | Required |
|---|---|
| 3-page gradient, animated, "AI-feeling" | Classic. Clean. Simple. No fancy gradients. No over-engineered animations. Just: name → first habit → reminder time. Human. |

### 🔔 Notifications
| Current | Required |
|---|---|
| Not firing | Actually fire. Fix the timezone and the missing zonedSchedule param. Test with a 1-minute test notification. |

---

## Priority Order (from feedback weight)
1. **Notifications** — functional, users need this
2. **Home screen hierarchy** — streak as hero
3. **Typography** — real size/weight variation
4. **Onboarding** — strip it down, make it human
5. **Overall personality** — bolder, less safe

---
