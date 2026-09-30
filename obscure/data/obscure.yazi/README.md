# obscure.yazi

Yazi previewer plugin shipped by the `omaconf/obscure` microcomponent.

Any file whose name matches `~/.config/obscure/patterns` with backup codes and recovery keys and passwords and secrets renders a lock screen instead of a preview, so shoulder surfers never see sensitive content on hover.

Opening such a file runs `obscure-view`, which asks for the system login password before showing anything. No separate password exists.

## Layout

Layout holds main lua file where peek and seek both render the lock screen. The preview is never unlocked in place and viewing always goes through the password gate.
