# Onboarding Flow — Art Requests

This document lists all images needed for the first-login onboarding flow that do not yet exist in the asset system. Existing assets (cat icons + ref sheets for black_cat, calico_cat, milk_cat, ninja_cat, orange_cat, tuxedo_cat) are already used directly by the onboarding scene via `AssetResolver`.

---

## 1. grey_cat — Full Art Set (MISSING: no art exists at all)

The grey_cat is a registered cat in the database but has zero art assets. It needs a complete set matching the style of the other cats.

### 1a. Icon

**Path:** `assets/sprites/ui/character_refs/grey_cat/grey_cat_icon_v1.png`
**Size:** 128×128 px, transparent background

**Prompt:**
> Cute cartoon cat icon, solid medium grey fur, short tail, big amber round eyes, simple chibi style, white highlight on eyes, flat colour illustration, transparent background, 128×128 pixel art game icon, consistent with a mobile idle game aesthetic.

---

### 1b. Front Reference

**Path:** `assets/sprites/ui/character_refs/grey_cat/grey_cat_ref_front_v1.png`
**Size:** 512×512 px, transparent background

**Prompt:**
> Full-body character reference sheet, front view, cute chibi cartoon cat, solid medium grey fur, white chest patch, short legs, big amber round eyes, long tail curled to one side, sitting upright, simple flat colour illustration with soft shading, transparent background, mobile game character art style.

---

### 1c. Three-Quarter Reference

**Path:** `assets/sprites/ui/character_refs/grey_cat/grey_cat_ref_three_quarter_v1.png`
**Size:** 512×512 px, transparent background

**Prompt:**
> Full-body character reference, three-quarter view (front-right angle), cute chibi cartoon cat, solid medium grey fur, white chest patch, big amber round eyes, sitting pose, simple flat colour illustration with soft shading, transparent background, mobile game character art style.

---

### 1d. Right-Side Reference

**Path:** `assets/sprites/ui/character_refs/grey_cat/grey_cat_ref_right_v1.png`
**Size:** 512×512 px, transparent background

**Prompt:**
> Full-body character reference, right side profile view, cute chibi cartoon cat, solid medium grey fur, white belly, big amber round eye visible, sitting pose, long tail tucked around feet, simple flat colour illustration with soft shading, transparent background, mobile game character art style.

---

## 2. Onboarding Background — Street Corner at Dusk

Used as the scene background for the opening dialogue beats (beats 1–3: the street feeding scene).

**Path:** `assets/sprites/ui/onboarding/bg_street_corner_v1.png`
**Size:** 1280×720 px (landscape)

**Prompt:**
> 2D game background illustration, quiet urban street corner in Taiwan at dusk, warm golden-orange sky, narrow alleyway with old apartment walls, potted plants on window ledges, a metal food bowl on the ground, soft evening light, no people, no cats, painterly flat-colour mobile game background art style, 1280×720.

---

## 3. Onboarding Background — Trap Cage Scene

Used for dialogue beat 4 (the cat is lured into a trap cage with food).

**Path:** `assets/sprites/ui/onboarding/bg_trap_cage_v1.png`
**Size:** 1280×720 px (landscape)

**Prompt:**
> 2D game background illustration, close-up of a humane wire trap cage (誘捕籠) sitting on a sidewalk, a small can of wet cat food placed inside as bait, warm late-afternoon lighting, alley wall behind, no people visible, cute cozy illustration style for a mobile idle game, 1280×720.

---

## 4. Onboarding Background — Destroyed Home Interior

Used for dialogue beat 7 (cat alone at home, has knocked things over and made a mess).

**Path:** `assets/sprites/ui/onboarding/bg_home_destroyed_v1.png`
**Size:** 1280×720 px (landscape)

**Prompt:**
> 2D game background illustration, cozy small apartment living room viewed from the side, overturned items on a coffee table (cups, books, a plant), curtains partially pulled down, scratched sofa corner, sunlight streaming through window blinds, warm colours, cute exaggerated mess but not scary, mobile idle game art style, 1280×720.

---

## 5. Onboarding Background — Home Interior (Normal)

Used for dialogue beats 5–6 and 8–9 (cat at home, owner returns, idle time).

**Path:** `assets/sprites/ui/onboarding/bg_home_normal_v1.png`
**Size:** 1280×720 px (landscape)

**Prompt:**
> 2D game background illustration, cozy small Taiwanese apartment living room, wooden floor, low sofa, bookshelves, litter box in the corner, food bowl on a mat, warm indoor lighting, afternoon light through window, tidy and inviting, cute flat-colour mobile idle game art style, 1280×720.

---

## 6. Dialogue Speaker Portrait — Cat (Neutral)

A generic cat portrait used in the dialogue UI when the cat is speaking. The final game will use per-cat portraits, but this placeholder serves all cats for the initial onboarding.

**Path:** `assets/sprites/ui/onboarding/portrait_cat_neutral_v1.png`
**Size:** 256×256 px, transparent background

**Prompt:**
> Cartoon cat portrait, neutral/calm expression, cute chibi style, head and upper chest only, simple flat colour illustration, generic grey-and-white colouration so it can represent any cat, soft shading, transparent background, used in a dialogue box UI in a mobile idle game.

---

## 7. Dialogue Speaker Portrait — Player / Scooper

Used when the narrator or player's inner voice is speaking in the dialogue.

**Path:** `assets/sprites/ui/onboarding/portrait_player_v1.png`
**Size:** 256×256 px, transparent background

**Prompt:**
> Cartoon human portrait, young adult, gender-neutral, wearing a casual T-shirt, warm friendly expression, head and upper chest only, simple flat colour chibi illustration style, soft shading, transparent background, used in a dialogue box UI in a mobile idle game.

---

## 8. Cat Adoption Banner / Step Header

Decorative banner image shown at the top of the cat picker step.

**Path:** `assets/sprites/ui/onboarding/banner_adopt_v1.png`
**Size:** 800×160 px, transparent background

**Prompt:**
> Horizontal decorative banner for a mobile game UI, text reads "領養你的貓" in rounded cute Chinese font, surrounded by small paw prints and star sparkles, pastel warm colour palette (peach, soft yellow, light coral), transparent background, flat illustration style.

---

## Usage Notes for AssetResolver

Once images are generated and placed at the paths above, update `scripts/utils/asset_resolver.gd`:

- Add `grey_cat` to `CAT_ICONS` mapping → `grey_cat_icon_v1.png`
- Add `grey_cat` to `CAT_SHOWCASE_TEXTURES` mapping → any of the ref images
- Add a new `ONBOARDING_BG` dictionary for the background paths keyed by dialogue beat group
