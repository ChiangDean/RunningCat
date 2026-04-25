# Tuxedo Cat Battle Animation Plan

Target runtime: `CatNode` battle sprites through `AssetResolver`.

Required actions found in game:

- `idle`: 6 frames, looping, subtle breathing and tail sway.
- `run`: 8 frames, looping, side-view forward run.
- `collide`: 4 frames, one-shot impact brace and recovery.
- `knockback`: 6 frames, one-shot recoil and airborne recovery.
- `stagger`: 4 frames, one-shot dazed wobble.
- `skill`: 6 frames, one-shot tuxedo flourish / strike.
- `death_fly`: 6 frames, one-shot defeat launch and tumble.

Final runtime sheets are copied one level up as `tuxedo_cat_*_right.png`.
The generated working folder keeps raw magenta sheets, normalized raw sheets, transparent sheets, frames, GIF previews, and pipeline metadata.
