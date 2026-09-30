# omamp Development Guidelines

When developing or modifying code in `omamp`:

1. **Title Formatting**:
   - Always strip parenthetical and bracketed content like `(feat. ...)`, `[Remix]` using `MediaModel.cleanTitle()`.
   - Keep titles static with `elide: Text.ElideRight` without marquee or oscillating text animations.

2. **Bar Widget Lifecycle & Visibility**:
   - The bar widget must hide (`visible: root.hasMedia` with `implicitWidth: visible ? button.implicitWidth : 0`) when no media is loaded.
   - Distinct state handling:
     - **Playing**: Shows pause icon `󰏤`, visible.
     - **Paused**: Shows play icon `󰐊`, visible (user can resume or toggle popup).
     - **Idle / Stopped / No metadata**: Hidden completely.

3. **Shell Application**:
   - After code changes, always apply by running:
     ```bash
     omarchy restart shell
     ```
