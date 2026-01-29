# Donation Page Redesign Implementation Plan

## Overview

Redesign the public donation page ("Cegiełka na EDK") with new visual identity: new main image, updated fonts, colors, and text content.

## Current State Analysis

### Files to Modify:
- `app/views/public/donations/_header.html.erb` - Header section with logo and title
- `app/views/layouts/public.html.erb` - Layout with font imports
- `app/assets/images/` - Main image asset

### Current Configuration:
- **Title font**: Bangers (Google Font)
- **Title color**: `text-indigo-500` (Tailwind blue/purple)
- **Body font**: Inter (Google Font)
- **Main image**: `edk-logo-2025.jpg`
- **Paczkomat**: Only InPost mentioned in text

### Key Discoveries:
- Header uses `font-bangers` custom class defined in layout:16-26
- Title has two-line layout: "CEGIEŁKA" and "NA EDK"
- Text content is hardcoded in `_header.html.erb`:21-29
- Layout loads fonts via Google Fonts CDN

## Desired End State

After implementation:
1. Main image shows new "wspieram" photo (people helping each other climb)
2. Title "CEGIEŁKA NA EDK" in Patrick Hand SC (or Gloria Hallelujah) font, color #5d1655
3. Body text in Poppins font with proper styling
4. Text mentions both Orlen Paczka and InPost as shipping options
5. Letter spacing and line height match Canva design

### Verification:
- Visual comparison with provided mockup images
- Font loads correctly from Google Fonts
- Color matches #5d1655 exactly
- All text content matches specification

## What We're NOT Doing

- Changing form functionality or validation logic
- Modifying the actual paczkomat selection widget (it uses Furgonetka API)
- Changing payment processing
- Modifying email templates or confirmation pages

## Implementation Approach

Single-phase implementation changing fonts, colors, image, and text content simultaneously since all changes are in view layer and do not affect functionality.

---

## Phase 1: Visual Redesign

### Overview
Update all visual elements: fonts, colors, main image, and text content.

### Changes Required:

#### 1. Copy New Main Image
**Action**: Copy the new image to assets directory

```bash
cp /Users/qiun/Downloads/wspieram-foto.jpg app/assets/images/edk-cegiełka-2025.jpg
```

#### 2. Update Layout - Font Imports
**File**: `app/views/layouts/public.html.erb`

**Current (lines 14-27)**:
```erb
<!-- Fonty -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bangers&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

<style>
  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  .font-bangers {
    font-family: 'Bangers', cursive;
    letter-spacing: 0.02em;
  }
</style>
```

**New**:
```erb
<!-- Fonty -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Patrick+Hand+SC&family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">

<style>
  body {
    font-family: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  .font-title {
    font-family: 'Patrick Hand SC', cursive;
    letter-spacing: 0.1em;
    line-height: 1.24;
  }
</style>
```

**Note**: Patrick Hand SC is a good alternative. If user prefers different style, alternatives include:
- `Gloria+Hallelujah` - more casual handwriting
- `Schoolbell` - nostalgic childlike
- `Gochi+Hand` - playful quirky

#### 3. Update Header Partial
**File**: `app/views/public/donations/_header.html.erb`

**Replace entire content with**:
```erb
<div class="mb-8">
  <!-- Logo and Title Row -->
  <div class="flex flex-col sm:flex-row items-center sm:items-start gap-6 mb-8">
    <!-- EDK Logo -->
    <div class="flex-shrink-0 w-[180px] h-[180px] rounded-2xl overflow-hidden shadow-xl">
      <%= image_tag "edk-cegiełka-2025.jpg",
          alt: "EDK logo - ludzie pomagający sobie wspinać się",
          class: "w-full h-full object-cover" %>
    </div>

    <!-- Title -->
    <div class="text-center sm:text-left">
      <h1 class="font-title" style="color: #5d1655;">
        <span class="block text-5xl sm:text-6xl lg:text-7xl leading-tight">CEGIEŁKA</span>
        <span class="block text-4xl sm:text-5xl lg:text-6xl leading-tight mt-1">NA EDK</span>
      </h1>
    </div>
  </div>

  <!-- Info List -->
  <div class="space-y-1 text-sm leading-relaxed" style="font-family: 'Poppins', sans-serif;">
    <p class="font-semibold text-gray-900">EDK to dom dla idealistów. Dołóż cegiełkę, bo warto.</p>
    <p class="font-semibold text-gray-900">Idealiści chodzą na EDK, potem zmieniają siebie, i wreszcie świat.</p>
    <p class="font-semibold text-gray-900">Twoja cegiełka ma znaczenie!!! Bez niej niczego nie zbudujemy.</p>
    <p class="font-semibold text-gray-900">Cegiełka to darowizna na EDK w wysokości 50 zł. Możesz dołożyć więcej, niż jedną cegiełkę</p>
    <p class="font-semibold mt-3" style="color: #5d1655;">Uwaga:</p>
    <p class="text-gray-700">Do każdej cegiełki możesz otrzymać mały upominek, pakiet EDK 2025.</p>
    <p class="text-gray-700">W skład pakietu wchodzą: książeczka z rozważaniami, opaska na rękę, odblask. Podarunek wysyłamy na nasz koszt.</p>
    <p class="text-gray-700">Oczywiście, jeśli wybierzesz podarunek, musisz pozostawić dodatkowo dane teleadresowe i wybrać pośrednika: Orlen Paczkę lub Inpost. Każda cegiełka to szansa na jeden pakiet.</p>
    <p class="font-semibold mt-3" style="color: #5d1655;">Pamiętaj, uczymy się wdzięczności. Bądź z nami.</p>
  </div>
</div>
```

#### 4. Update Gift Section Labels (optional - for consistency)
**File**: `app/views/public/donations/_gift_section.html.erb`

**Change line 22**:
```erb
<!-- FROM -->
Wybierz paczkomat InPost <span class="text-indigo-500">*</span>

<!-- TO -->
Wybierz paczkomat InPost lub ORLEN Paczka <span style="color: #5d1655;">*</span>
```

**Change line 33**:
```erb
<!-- FROM -->
Wybierz paczkomat InPost

<!-- TO -->
Wybierz paczkomat InPost lub ORLEN Paczka
```

**Note**: The actual Furgonetka widget integration determines which carriers are shown. This change is cosmetic text only.

---

### Success Criteria:

#### Automated Verification:
- [x] New image file exists: `ls app/assets/images/edk-cegiełka-2025.jpg`
- [x] Assets compile without errors: `bin/rails assets:precompile`
- [x] No syntax errors in views: `bin/rails runner "ApplicationController.render inline: ''"` (general syntax check)

#### Manual Verification:
- [ ] Main image displays correctly (people climbing with moon background)
- [ ] Title "CEGIEŁKA NA EDK" shows in Patrick Hand SC font
- [ ] Title color is #5d1655 (dark burgundy/purple)
- [ ] Body text uses Poppins font
- [ ] All Polish text displays correctly with diacritics
- [ ] Text mentions both "Orlen Paczkę lub Inpost" in the description
- [ ] Layout looks correct on mobile and desktop
- [ ] Gift section label mentions both shipping options

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the visual changes match the mockup.

---

## Testing Strategy

### Visual Testing:
1. Open donation page in browser: `/cegielka`
2. Compare side-by-side with mockup images
3. Check responsive design on mobile viewport
4. Verify font rendering on different browsers

### Cross-browser Testing:
- Chrome (primary)
- Safari (macOS)
- Firefox
- Mobile Safari/Chrome

---

## Alternative Font Options

If Patrick Hand SC doesn't match the desired style closely enough, here are alternatives to try:

| Font Name | Style | Google Fonts URL |
|-----------|-------|------------------|
| Patrick Hand SC | Casual handwriting, small caps | `Patrick+Hand+SC` |
| Gloria Hallelujah | Bold, casual | `Gloria+Hallelujah` |
| Schoolbell | Nostalgic, childlike | `Schoolbell` |
| Gochi Hand | Playful, quirky | `Gochi+Hand` |
| Architects Daughter | Neat hand-drawn | `Architects+Daughter` |

To change font, update the Google Fonts URL in `public.html.erb`:
```erb
<link href="https://fonts.googleapis.com/css2?family=FONT_NAME_HERE&family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

And update the `.font-title` class:
```css
.font-title {
  font-family: 'FONT_NAME_HERE', cursive;
  ...
}
```

---

## References

- Current header: `app/views/public/donations/_header.html.erb`
- Current layout: `app/views/layouts/public.html.erb`
- New image source: `/Users/qiun/Downloads/wspieram-foto.jpg`
- Design mockup: `/Users/qiun/Downloads/WhatsApp Image 2026-01-27 at 12.58.10.jpeg`
- Font styling reference: `/Users/qiun/Downloads/WhatsApp Image 2026-01-27 at 15.26.05 (1).jpeg`
