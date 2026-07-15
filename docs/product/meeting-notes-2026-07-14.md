# Meeting Notes — App fir Elteren

**Date:** 14 Jul 2026, 12:47  
**Language:** Lëtzebuergesch  
**Context:** Stakeholder discussion on a parent coordination app (now **Common Ground Co-Parent**)

---

## Summary (EN)

Parents who **no longer talk daily** still need to **organize the child's everyday life** — calendar, messages, shared costs, photos, school info, and “what happened today” — in one place instead of WhatsApp or notes on the fridge.

**Pricing idea from meeting:** ~**€1/month** for interested clients.

---

## Decisions

| Topic | Decision |
|-------|----------|
| Product relevance | App development is relevant |
| Core focus | Communication & coordination **between parents** |
| Calendar | Essential — no debate |
| Chat | Essential |
| Expenses | Yes — Tricount-style split for child-related costs (holidays, activities) |
| Extended family | Optional **read-only** access (e.g. grandparents) — **no chat** |
| Child access | Optional later — simplified layout when child logs in |
| Information parity | Both parents see the same child info (school godparent, emergency contacts, etc.) |

---

## Feature requests (from transcript)

### Must-have (MVP alignment)

- [ ] **Kalenner** — child schedule: school, sport, matches, fixed events
- [ ] **Chat** — co-parent messaging without WhatsApp
- [ ] **Depensen** — shared child expenses, settle-up (Tricount-like)
- [ ] **Fotoen deelen** — photos shared between households
- [ ] **Alldag informéieren** — log what happened (e.g. parent absent, school update) — readable later, not only “day counting”
- [ ] **Bilansgespréicher** — school / parent-teacher communication
- [ ] **Kontakter & Notfall** — phone, address, email, emergency contacts, school contacts (godmother at school, etc.)
- [ ] **Eng Plaz fir alles** — replace fridge notes / one parent holding all info

### Should-have (v1.1+)

- [ ] **Grousselteren / Liesaccès** — grandparents: **view only**, configurable what they see, **no messaging**
- [ ] **Granulär Permissiounen** — per-area toggles (“däerf gesinn / däerf net gesinn”) like Alalux block notes
- [ ] **Kand-Login** — optional child account, limited UI, share photo/info to both parents

### Business

- [ ] **Präis** — ~€1/month subscription for end users (to validate)

---

## Action items (original)

- [x] Entwécklung vun der App starten → **Common Ground built, TestFlight path ready**
- [x] Funktiounen definéieren (Kalenner, Chat, Depensen) → **implemented in v1.0**
- [ ] Stakeholder review on TestFlight
- [ ] Align grandparent permissions with meeting (read-only, no chat)
- [ ] Decide on €1/month pricing & App Store IAP
- [ ] Luxembourgish / French localization (market: Lëtzebuerg)

---

## Product alignment — Common Ground today

| Meeting ask | Status | Notes |
|-------------|--------|-------|
| Kalenner (custody + events) | ✅ Built | Schedule builder, exchange reminders, Apple Calendar sync |
| Chat | ✅ Built | Immutable co-parent threads |
| Depensen (Tricount-style) | ✅ Built | Split, reimburse, receipts |
| Fotoen | ✅ Built | Timeline, documents, child photos |
| Schoul / Bilans | 🟡 Partial | School info, teachers, portal stub — not full parent-teacher workflow |
| Alldag / “wat geschitt ass” | 🟡 Partial | Timeline + messages — could emphasize **daily log** UX |
| Notfall & Schoulkontakter | ✅ Built | Emergency info, school contacts on child profile |
| Grousselteren Liesaccès | 🟡 Gap | Grandparent role exists but **still has messaging** — meeting wants **view only** |
| Granulär Permissiounen | 🟡 Gap | Role defaults only — no per-block toggles in UI |
| Kand-Login | ❌ Not built | Future |
| €1/Month | ❌ Not built | App is free; no IAP yet |

---

## Recommended next steps

1. **TestFlight demo** for meeting participants — focus on calendar, chat, expenses, child profile.
2. **Quick fix:** change default `MemberPermissions` for `.grandparent` → `canSendMessages: false` (match meeting).
3. **v1.1:** “Daily update” entry type on timeline (informative, non argumentative).
4. **v1.1:** Permissions UI — toggles per member for calendar / expenses / medical / messages.
5. **Business:** validate €1/month vs free core + optional pro (court export already pro-tier candidate).

---

## Original transcript (Lëtzebuergesch)

Wéi vu Geschäftsidee ass, déi s du kanns esou net aussoen. Also, wann déi, also, dat ass dat Éischt, wat ech da soen, ne? Wann s de déi baust an déi gëtt e Succès, kéint ech 50 % net déi net. Da so him, da so him elo mol eng Kéier, wat s de gären häss. Mee da soe mer mol d'Iddien, d'Iddien, also eng App fir Elteren, wou, De s de bien passé, Monsieur. Merci. Ech gëtt ee war hei sépar och? Wou, d'Iddien ass kloer, dës Elteren, déi vläicht net méi mateneen schwätzen a mussen awer all Dag vun de Kanner organiséieren. Also Kalenner, kloer, keng Diskussioun. Eng Chat App, kloer, dass de kanns mateneen kommunizéieren. Och kloer. Wat, finanziell Iergend, eppes. Kanns, kanns de eigentlech och abauen. Wat? Dass de, dass de Depensen akanns, kanns ginn, déi am Interêt vum Kand sinn, dass de, dass de, dass de, dass de Kand quasi wéi en Tricount maachen. Jo. Iwwert d'Depensen, dat ass also eng Zousazfunktioun, wou s de esou bezuelen, well dat ass jo dann 9 Nivelles iwwerlooss. Déi eng Kéier en Elementer an déi aner net. Wou s de sees okay, mir, mir, mir maachen dat ënnereneen an dat wat mer ausginn, fir eist Kand, seng Vakanz, egal ob et mat mir oder mat dir ass a wat fir sech, wat weess, dass de kanns déi Fraise komplett deelen. Dat kanns de och maachen. Haaptsächlech soen ech mol awer, dass de kanns Fotoen deelen, dass de kanns Bilansgespréicher, weess de kommunizéieren, wat wou deen ee vläicht abstinent war, well en net kéint do sinn oder well en huet misse schaffen, wat och ëmmer, dass der effektiv all déi Saache kanns och informatesch androen an net nëmmen zielen. D'Organisatioun eeben vum Alldag, respektiv eeben och wat geschitt ass am Alldag, kanns deen aneren informéieren, ouni dass de muss deem eng, wéi soll soen, eng WhatsApp oder iergendeng Informatioun esou schreiwen, mee dass dat kanns an d'App, an dass dat och do bleift, dass dat kann nogelies ginn. De Kalenner vum Kand, also wat si seng, wéi huet et d'Schoul, wéi huet et Sport, wou huet et e Match, weess de, alleguerten déi Events, déi feststinn, dass de eventuell souguer kéins, dat ass eng Optioun, muss kucken ob een dat wëll, aner Leit kann Accès ginn, och keng Kommunikatiounsaccès, mee Liesaccès. Als Beispill d'Grousselteren, oder Gott weess wat, dass déi kënnen, déi suivéieren, voilà, awer dass do kann ugeklickt ginn, dat däerfen déi gesinn, dat däerfen déi net gesinn, also wësst de, wësst de wéi op d'Alaluxen, dass de sees, dat doten ass Blockknotte, de Kand-Aktiounsaccès, wéi d'Kand-Aktiounsaccès, géif ech net maachen, mee, also dach optional, well d'Kënner ginn och méi grouss, a kënnen dann effektiv eng Informatioun, eng Foto deelen, an déi direkt bei béid Elteren ukrennen. Weess de, respektiv, voilà, dat ass mäin, dat ass mäi Vakanzeplanung. Jo, du kanns och soen, dass, sou, wann d'Kand sech alokst, als Beispill, Jo, huet et nëmmen Accès op, Da gëtt, da gëtt just dat, an da gëtt, da gëtt och de Layout ass, ass, d'ITRA TRULAL, eppeschen esou, weess de, weess de, dat. Weess de, dass du och deng, deng Angabe kanns aginn, wéi sou, deng Telefonsnummer, deng Andress, deng E-Mail, wat der ëmmer, deng Notfall, Notfallagence, Notfalldenger, dass dat kanns soen, Notfallkontakter. Dass du déi kënns direkt doriwwer kontaktéieren, dass du kanns aginn, wien huet déi an der Schoul als Jëffer, wéi ass deem seng Telefonsnummer, weess de, am Endeffekt, dass de den, dat wat d'Mamm weess, blöd geschwat, well déi Informatiounen, déi déi majoritär d'Mamm ëmmer huet, dass de Papp déi och huet. Jo. An zwar op enger Plaz, wou en elo kucke kann an net doheem um Frigo hänken, wou en do seet, jo, dat hänkt elo doheem um Frigo, wéi et Jëffer heescht, ne, an a wéi enger Schoul mäi Kand geet, an, wéi d'Turnjëffer heescht, an, an, an, an, an. Dass de eeben einfach den Alldag vum Kand, wou iwwert deen s de net méi kommunizéiert ass, informatesch nachsinn ass. Okay. A wann s de do vu potenzielle Clientë schwätzt, déi dat interesséieren, da maachen s de do een Euro de Mount, weess de.
