---
name: Obsidian Mint Precision
colors:
  surface: '#131315'
  surface-dim: '#131315'
  surface-bright: '#39393b'
  surface-container-lowest: '#0e0e10'
  surface-container-low: '#1c1b1d'
  surface-container: '#201f21'
  surface-container-high: '#2a2a2c'
  surface-container-highest: '#353437'
  on-surface: '#e5e1e4'
  on-surface-variant: '#b9cbbf'
  inverse-surface: '#e5e1e4'
  inverse-on-surface: '#313032'
  outline: '#84958a'
  outline-variant: '#3b4a41'
  surface-tint: '#00e29e'
  primary: '#b7ffd9'
  on-primary: '#003824'
  primary-container: '#00f0a8'
  on-primary-container: '#006847'
  inverse-primary: '#006c4a'
  secondary: '#4dffb2'
  on-secondary: '#003822'
  secondary-container: '#00e296'
  on-secondary-container: '#005f3d'
  tertiary: '#f1eef7'
  on-tertiary: '#303036'
  tertiary-container: '#d4d2da'
  on-tertiary-container: '#5b5a61'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#46ffb8'
  primary-fixed-dim: '#00e29e'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#4dffb2'
  secondary-fixed-dim: '#00e296'
  on-secondary-fixed: '#002112'
  on-secondary-fixed-variant: '#005234'
  tertiary-fixed: '#e4e1ea'
  tertiary-fixed-dim: '#c8c5cd'
  on-tertiary-fixed: '#1b1b21'
  on-tertiary-fixed-variant: '#47464d'
  background: '#131315'
  on-background: '#e5e1e4'
  surface-variant: '#353437'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  label-xs:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system delivers an uncompromising, functional utility aesthetic built for high-performance offline video manipulation. Designed for content creators, video operators, and technical power users, the UI prioritizes rapid operational clarity, absolute low-latency visual feedback, and technical precision.

The design movement is **Technical Minimalist / Flat Utility**:
- **Zero Distraction:** Eliminates all non-essential decorative elements, skeuomorphic depth, radial fills, and gradients.
- **Utilitarian Confidence:** Communicates raw computing power, local sandbox safety, and determinism through rigorous structural framing and visible borders.
- **Electric Accent Contrast:** A calculated shock of electric mint punctuates monochromatic black surfaces, instantly routing attention to actionable controls and state changes.
- **Monospaced Micro-data:** Integrates dense technical parameters (codecs, framerates, hash changes, byte sizes) directly alongside user actions with clean, modern grotesque and monospaced typography.

## Colors

The palette is engineered exclusively for an immersive, zero-bleed dark mode context:

### Surface & Frame Tokens
- **Canvas Base (`#0a0a0c`):** The absolute foundational background. Deep, pure black engineered to conserve battery on OLED devices during compute-heavy workloads.
- **Surface Layer 1 (`#16161a`):** Segmented card panels, modal sheets, and standard module containers.
- **Surface Layer 2 (`#202026`):** Interactive inputs, nested parameters, and hover/pressed containment.
- **Border Crisp (`#2a2a32`):** Universal dividing lines and outlines. 1px solid, clean separation across all surface transitions.
- **Border Active (`#00F0A8`):** Direct focus states, active drags, and selected state outlines.

### Accent & Feedback Tokens
- **Electric Mint (`#00F0A8`):** The primary kinetic signal. Reserved strictly for executable primary actions, active switches, checked markers, and affirmative progress states. Contrast on `#0a0a0c` exceeds 14:1.
- **Mint Press / Secondary (`#10E599`):** Secondary interactive mint, used for pressed states and secondary badges.
- **Destructive Red (`#FF453A`):** Purged cache indicators, cancellation actions, and file corruption alerts.

### Typography & Content Tokens
- **Text Primary (`#FFFFFF`):** 100% white for titles, numerical outputs, and primary labels.
- **Text Muted (`#8E8E99`):** Metadata, inactive states, secondary subtitles, and technical units (e.g., `MB`, `fps`).
- **Text Inverse (`#0A0A0C`):** High-contrast black text on top of electric mint primary action buttons.

## Typography

Typography pairs the structural clarity of **Inter** for primary UI narratives with the computational authority of **JetBrains Mono** for numerical values, processing statuses, file sizes, metadata, and badges.

- **Legibility Over Ornamentation:** Optical sizes, neutral apertures, and zero serif distractions ensure immediate reading even under direct outdoor sunlight or rapid scrolling.
- **Numerical Regularity:** JetBrains Mono is mandatory for all live counters, timecodes, processing percentages, frame counts, and file signatures to guarantee fixed tabular widths without layout shift.
- **Letter Spacing Discipline:** Body copy uses default tracking (`0`), whereas uppercase mono labels (`label-xs`, `label-sm`) require `+0.05em` letter spacing for micro-scale definition.

## Layout & Spacing

The layout is built around a rigorous **4px base grid** optimized for mobile edge-to-edge utility:

- **Mobile Viewport Canvas:** Employs an edge gutter of `1rem` (16px) with stacked full-width utility modules. Dense vertical layout prioritizes top-of-screen previews with thumb-accessible control blocks in the lower 60% of the viewport.
- **Vertical Rhythm:**
  - Component internals: Spaced in increments of `space-xs` (4px) and `space-sm` (8px).
  - Inter-module stacking: Regulated strictly by `space-md` (16px).
  - Major pipeline stages (Input / Parameter Modifiers / Output Actions): Separated by `space-lg` (24px).
- **Reflow & Tablet Adaptation:** When viewport width exceeds 600px, content splits into a 2-column utility grid: Column 1 holds live video player and technical inspect data; Column 2 holds modifier toggles and action controls. Gutter scales to `1.5rem` (24px).

## Elevation & Depth

This design system is purely flat: **zero drop shadows, zero ambient glow, and zero simulated light sources**.

Visual hierarchy is executed strictly through **Tonal Stacking** and **Crisp Borders**:
- **Layer 0 (Base Canvas):** `#0a0a0c`. The ground surface.
- **Layer 1 (Card/Container):** `#16161a` bordered with a 1px solid `#2a2a32`.
- **Layer 2 (Interactive Inset/Row):** `#202026` bordered with a 1px solid `#2a2a32`.
- **Layer 3 (Overlays/Bottom Sheets):** `#16161a` framed by a 1px solid `#2a2a32` perimeter border and a 70% opacity solid `#0a0a0c` scrim without blur.
- **Active Focus:** Any element transitioning to an active or selected state switches its 1px border from `#2a2a32` to `#00F0A8`.

## Shapes

The shape system adopts a **controlled, industrial soft-corner discipline (`roundedness: 1`)**:
- Standard components (buttons, input containers, cards) feature `0.25rem` (4px) corner radii.
- Large module cards and sheet containers use `0.5rem` (8px) corner radii.
- The system deliberately avoids full-pill shapes (`9999px`) on structural controls to maintain a serious, machine-like identity; pills are strictly reserved for tiny numerical badges and toggle indicator thumbs.

## Components

### Buttons
- **Primary Utility Button:**
  - Background: Solid `#00F0A8`.
  - Border: None.
  - Text: `#0a0a0c`, `Inter` SemiBold (14px), all-caps or title-case.
  - Hover/Active State: Background shifts to `#10E599`; zero vertical translation or shadow.
- **Secondary / Ghost Button:**
  - Background: `#16161a`.
  - Border: 1px solid `#2a2a32`.
  - Text: `#FFFFFF`, `Inter` Medium (14px).
  - Active: Border color transitions to `#00F0A8`.
- **Destructive Button:**
  - Background: Transparent; 1px solid `#FF453A`.
  - Text: `#FF453A`.

### Switch (Toggle) Components
- **Track:** 48px width by 24px height. 
  - Off State: Background `#202026` with 1px solid `#2a2a32`.
  - On State: Background `#00F0A8` with 1px solid `#00F0A8`.
- **Thumb:** 18px diameter, perfectly flat circular disc.
  - Off State: `#8E8E99`.
  - On State: `#0A0A0C`.
  - Transition: Linear 150ms slide.

### Dashed Border File / Video Picker
- Dedicated upload and media drop targets feature a 1.5px dashed border (`stroke-dasharray: 6 6`) in `#2a2a32` against `#16161a` background.
- On file drag-over or active selection, dashed stroke turns solid `#00F0A8`.
- Includes centered icon, primary callout in `body-md` (`#FFFFFF`), and format specs in `label-sm` (`#8E8E99`).

### Badge Chips & Status Pills
- **Technical Chip:**
  - Background: `#202026`.
  - Border: 1px solid `#2a2a32`.
  - Text: `label-xs` (`JetBrains Mono`, `#8E8E99`).
  - Active State: Background `#00F0A8` at 10% opacity, border `#00F0A8`, text `#00F0A8`.

### Input Fields & Steppers
- Input containers sit on `#16161a` with 1px solid `#2a2a32`.
- Caret and active border: `#00F0A8`.
- Inline numeric scrubbers/steppers use mono typefaces accompanied by segmented `[-]` and `[+]` boundary buttons separated by 1px solid internal grid dividers.

### Cards & Process Modules
- Composed of `#16161a` fill, 1px solid `#2a2a32` border, and standard padding of `1rem` (16px).
- Internal content headers feature title text (`Inter` SemiBold) paired with right-aligned mono status tags.

### Processing Progress Strip
- Height: 4px flat bar.
- Track: `#202026`.
- Bar Fill: `#00F0A8`.
- Accompanied below by monospace elapsed time, remaining seconds, and estimated final file footprint in `label-sm` (`#8E8E99`).