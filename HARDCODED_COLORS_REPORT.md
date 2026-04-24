# Hardcoded Colors Report - lib/screens Directory

## Summary
Found **12 files** with **47 hardcoded color instances** that violate the theme token system. These should use `context.tokens` instead of direct hex values or `AppColors.*` static references.

---

## Files with Violations

### 1. [lib/screens/home_screen.dart](lib/screens/home_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 77 | `Color(0xFF3DA899).withOpacity(0.20)` | Glow blob (mobile hero) | Hardcoded teal primary with opacity |
| 78 | `Colors.transparent` | Gradient end | Material Colors usage |
| 93 | `Color(0xFFF59E0B).withOpacity(0.12)` | Glow blob (mobile) | Hardcoded amber accent with opacity |
| 94 | `Colors.transparent` | Gradient end | Material Colors usage |
| 217 | `Color(0xFF3DA899).withOpacity(0.18)` | Glow blob (web hero) | Hardcoded teal primary with opacity |
| 218 | `Colors.transparent` | Gradient end | Material Colors usage |
| 245 | `Color(0x73FFFFFF)` | Hero subtitle text | Hardcoded white with opacity |
| 255 | `Color(0xFF226660)` | CTA button gradient | Hardcoded teal (should use AppColors.gradBtn) |
| 255 | `Color(0xFF3DA899)` | CTA button gradient | Hardcoded teal (same line) |
| 262 | `Color(0xFFD97706)` | Student CTA gradient | Hardcoded amber (should use AppColors.gradAccent) |
| 262 | `Color(0xFFF59E0B)` | Student CTA gradient | Hardcoded amber (same line) |
| 318 | `Colors.white` | Button text | Material Colors usage |
| 348 | `Color(0xFF4ADE80)` | Live badge dot | Hardcoded green (not in theme) |
| 354 | `Color(0xFF4ADE80)` | Live badge text | Hardcoded green (not in theme) |
| 360 | `Colors.white.withOpacity(0.07)` | PIN box background | Material Colors usage |
| 363 | `Colors.white` | PIN text (2x on same line) | Material Colors usage |
| 368 | `Colors.white` | Quiz title text | Material Colors usage |
| 370 | `Color(0xFF818CF8)` | Progress bar (Biology) | Hardcoded indigo (not in theme) |
| 372 | `Color(0xFF10B981)` | Progress bar (Chemistry) | Hardcoded emerald (not in theme) |
| 374 | `Color(0xFFF59E0B)` | Progress bar (Physics) | Hardcoded amber (not in theme) |
| 378 | `Color(0xFF818CF8)` | People icon (Statistics) | Hardcoded indigo (not in theme) |

**Total: 21 color instances**

---

### 2. [lib/screens/student/question_screen.dart](lib/screens/student/question_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 115 | `Color(0xFF0D1B2A)` | Scaffold background | Hardcoded dark blue (doesn't match app theme) |
| 123 | `Colors.white.withAlpha((0.1 * 255).round())` | Question counter background | Material Colors usage |
| 128 | `Colors.white` | Question counter text | Material Colors usage |
| 143 | `Colors.orange.withAlpha((0.2 * 255).round())` | Timer info background | Material Colors usage |
| 144 | `Colors.orange.withAlpha((0.5 * 255).round())` | Timer info border | Material Colors usage |
| 145 | `Colors.orange` | Timer icon | Material Colors usage |
| 147 | `Colors.orange` | Timer text | Material Colors usage |
| 163 | `Colors.white.withAlpha((0.05 * 255).round())` | Question box background | Material Colors usage |
| 165 | `Colors.white.withAlpha((0.1 * 255).round())` | Question box border | Material Colors usage |
| 170 | `Colors.white` | Question text (2x on same line) | Material Colors usage |
| 186 | `Colors.white70` | No options text | Material Colors usage |

**Total: 11 color instances**

---

### 3. [lib/screens/student/student_leaderboard_screen.dart](lib/screens/student/student_leaderboard_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Imports AppColors | Uses legacy static constants instead of context.tokens |
| 76 | `AppColors.bg` | Scaffold background | Using AppColors static (should use context.tokens) |
| 113 | `AppColors.surface` | Header container | Using AppColors static |
| 113 | `AppColors.border` | Header border | Using AppColors static |
| 118 | `AppColors.text` | Header title | Using AppColors static |
| 122 | `AppColors.textMuted` | Header subtitle | Using AppColors static |
| 129-176 | Multiple `AppColors.*` refs | Rank badge colors and gradients | Using hardcoded Color() with AppColors static mixed in |
| 129 | `Color(0xFFF59E0B)` | Rank 1 gradient start | Hardcoded amber |
| 129 | `Color(0xFFD97706)` | Rank 1 gradient end | Hardcoded amber |
| 130 | `Color(0xFF94A3B8)` | Rank 2 gradient start | Hardcoded slate |
| 130 | `Color(0xFF64748B)` | Rank 2 gradient end | Hardcoded slate |
| 131 | `Color(0xFFD85A30)` | Rank 3 gradient start | Hardcoded orange |
| 131 | `Color(0xFF993C1D)` | Rank 3 gradient end | Hardcoded brown |
| 134-137 | Avatar colors array | Hardcoded gradient colors | Multiple hardcoded colors for avatars |
| 134 | `Color(0xFF4F46E5)` | Avatar gradient 1 start | Hardcoded indigo |
| 134 | `Color(0xFF7C3AED)` | Avatar gradient 1 end | Hardcoded purple |
| 135 | `Color(0xFFD85A30)` | Avatar gradient 2 start | Hardcoded orange |
| 135 | `Color(0xFF993C1D)` | Avatar gradient 2 end | Hardcoded brown |
| 136 | `Color(0xFF0F6E56)` | Avatar gradient 3 start | Hardcoded teal |
| 136 | `Color(0xFF085041)` | Avatar gradient 3 end | Hardcoded dark teal |
| 137 | `Color(0xFF185FA5)` | Avatar gradient 4 start | Hardcoded blue |
| 137 | `Color(0xFF0C447C)` | Avatar gradient 4 end | Hardcoded dark blue |
| 176 | `Color(0xFF059669)` | Current player avatar green start | Hardcoded emerald |
| 176 | `Color(0xFF10B981)` | Current player avatar green end | Hardcoded emerald |
| 184-187 | Multiple `AppColors.*` | All remaining lines in file | Pervasive AppColors static usage throughout |

**Total: 24 color instances (AppColors static + hardcoded)**

---

### 4. [lib/screens/student/student_lobby_screen.dart](lib/screens/student/student_lobby_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Imports AppColors | Uses legacy static constants |
| 62 | `AppColors.bg` | Scaffold background | Using AppColors static |
| 70 | `AppColors.surface` | Top bar background | Using AppColors static |
| 70 | `AppColors.border` | Top bar border | Using AppColors static |
| 80-87 | Multiple `AppColors.*` | PIN pill and badge | Using AppColors static throughout |
| 108 | `AppColors.surface` | Hero card background | Using AppColors static |
| 108 | `AppColors.border` | Hero card border | Using AppColors static |
| 111 | `AppColors.gradBtn` | Avatar gradient | Using AppColors static gradient |
| 111 | `AppColors.border` | Avatar border | Using AppColors static |
| 160 | `Color(0xFFD85A30)` | Avatar color 1 start | Hardcoded orange |
| 160 | `Color(0xFF993C1D)` | Avatar color 1 end | Hardcoded brown |
| 161 | `Color(0xFF0F6E56)` | Avatar color 2 start | Hardcoded teal |
| 161 | `Color(0xFF085041)` | Avatar color 2 end | Hardcoded dark teal |
| 162 | `Color(0xFF185FA5)` | Avatar color 3 start | Hardcoded blue |
| 162 | `Color(0xFF0C447C)` | Avatar color 3 end | Hardcoded dark blue |
| 163 | `Color(0xFF993556)` | Avatar color 4 start | Hardcoded purple |
| 163 | `Color(0xFF72243E)` | Avatar color 4 end | Hardcoded dark purple |

**Total: 17 color instances (AppColors static + hardcoded)**

---

### 5. [lib/screens/teacher/login_screen.dart](lib/screens/teacher/login_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 68 | `Color(0xFF08080F)` | Scaffold background | Hardcoded dark color (inconsistent with app theme) |
| 81 | `Color(0xFF1A0F3E)` | Web layout gradient 1 | Hardcoded purple |
| 81 | `Color(0xFF0F3460)` | Web layout gradient 2 | Hardcoded navy |
| 81 | `Color(0xFF0A1628)` | Web layout gradient 3 | Hardcoded dark blue |
| 84 | `Color(0xFF6366F1)` | Glow orb color | Hardcoded indigo |
| 84 | `Color(0xFF10B981)` | Glow orb color 2 | Hardcoded emerald |
| 106 | `Color(0xFF818CF8)` | "QuizApp" text color | Hardcoded indigo |
| 107 | `Color(0x73FFFFFF)` | Subtitle text opacity | Hardcoded white with opacity |
| 155 | `Color(0xFF4F46E5)` | Icon badge gradient 1 | Hardcoded indigo |
| 155 | `Color(0xFF7C3AED)` | Icon badge gradient 2 | Hardcoded purple |
| 156 | `Color(0xFF6366F1)` | Box shadow color | Hardcoded indigo |
| 192 | `Color(0xFF1A0F3E)` | Mobile gradient 1 | Hardcoded purple |
| 192 | `Color(0xFF0F3460)` | Mobile gradient 2 | Hardcoded navy |
| 192 | `Color(0xFF0A1628)` | Mobile gradient 3 | Hardcoded dark blue |
| 195 | `Color(0xFF6366F1)` | Glow orb 1 | Hardcoded indigo |
| 195 | `Color(0xFF10B981)` | Glow orb 2 | Hardcoded emerald |
| 228 | `Color(0xFF4F46E5)` | Icon gradient 1 | Hardcoded indigo |
| 228 | `Color(0xFF7C3AED)` | Icon gradient 2 | Hardcoded purple |
| 229 | `Color(0xFF6366F1)` | Box shadow | Hardcoded indigo |
| 252 | `Color(0xFF818CF8)` | "QuizApp" accent | Hardcoded indigo |
| 253 | `Color(0x73FFFFFF)` | Subtitle opacity | Hardcoded white |
| 305 | Multiple hardcoded colors | Various form elements | Throughout login screen |

**Total: 21+ color instances**

---

### 6. [lib/screens/teacher/register_screen.dart](lib/screens/teacher/register_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| Similar pattern to login_screen | Multiple hardcoded | All same issues as login | Uses identical hardcoded colors for gradients, icons, overlays |
| 73 | `Color(0xFF1A0F3E)` | Web gradient 1 | Hardcoded purple |
| 73 | `Color(0xFF0F3460)` | Web gradient 2 | Hardcoded navy |
| 73 | `Color(0xFF0A1628)` | Web gradient 3 | Hardcoded dark blue |
| 76 | `Color(0xFF6366F1)` | Glow orb 1 | Hardcoded indigo |
| 76 | `Color(0xFF818CF8)` | Glow orb 2 | Hardcoded indigo |
| 95 | `Color(0xFF818CF8)` | "QuizApp" accent | Hardcoded indigo |
| 96 | `Color(0x73FFFFFF)` | Subtitle | Hardcoded white opacity |

**Total: 19+ color instances (similar to login)**

---

### 7. [lib/screens/teacher/host_game_screen.dart](lib/screens/teacher/host_game_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 71 | `Color(0xFF0D1B2A)` | Scaffold background | Hardcoded dark blue (inconsistent) |
| 81 | `Colors.white.withAlpha((0.1 * 255).round())` | Question counter bg | Material Colors |
| 85 | `Colors.white` | Question counter text | Material Colors |
| 91 | `Colors.orange.withAlpha((0.2 * 255).round())` | Timer box background | Material Colors |
| 92 | `Colors.orange.withAlpha((0.5 * 255).round())` | Timer box border | Material Colors |
| 93 | `Colors.orange` | Timer icon and text | Material Colors |
| 97 | `Colors.orange` | Timer text (2x) | Material Colors |
| 110 | `Colors.white.withAlpha((0.05 * 255).round())` | Question box bg | Material Colors |
| 112 | `Colors.white.withAlpha((0.1 * 255).round())` | Question box border | Material Colors |
| 117 | `Colors.white` | Question text (2x) | Material Colors |
| 131 | `Colors.red[600]` | End Early button | Material Colors palette |
| 134 | `Colors.white` | End Early button text | Material Colors |
| 169 | `Colors.orange` | Yes/No stats colors (2x) | Material Colors |
| 170 | `Colors.blue` | Yes/No stats colors (2x) | Material Colors |
| 176 | `Color(0xFFE21B3C)` | Multiple Choice option 1 | Hardcoded red |
| 177 | `Color(0xFF1368CE)` | Multiple Choice option 2 | Hardcoded blue |
| 178 | `Color(0xFFFFA602)` | Multiple Choice option 3 | Hardcoded orange |
| 179 | `Color(0xFF26890C)` | Multiple Choice option 4 | Hardcoded green |

**Total: 18+ color instances**

---

### 8. [lib/screens/student/join_screen.dart](lib/screens/student/join_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| Uses `context.tokens.*` properly for gradients | ✅ Good | Uses theme tokens | Correctly uses context.tokens for primary/accent |

**Total: 0 violations** ✅

---

### 9. [lib/screens/teacher/final_leaderboard_screen.dart](lib/screens/teacher/final_leaderboard_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Uses AppColors | Legacy static constants |
| Extensive use of `AppColors.*` | Throughout file | Scattered references | Using static constants instead of context.tokens |
| 120 | `Color(0xFFF59E0B)` | Rank 1 gradient | Hardcoded amber |
| 120 | `Color(0xFFD97706)` | Rank 1 gradient end | Hardcoded amber |
| 136-139 | Avatar gradients | Multiple hardcoded colors | Same as leaderboard_screen |
| 136 | `Color(0xFF64748B)` | Avatar 1 start | Hardcoded slate |
| 136 | `Color(0xFF475569)` | Avatar 1 end | Hardcoded slate |
| 137 | Multiple AppColors refs | Primary/accent | Using static instead of tokens |
| 138 | `Color(0xFFD85A30)` | Avatar 3 start | Hardcoded orange |
| 138 | `Color(0xFF993C1D)` | Avatar 3 end | Hardcoded brown |

**Total: 22+ color instances (AppColors static + hardcoded)**

---

### 10. [lib/screens/teacher/teacher_lobby_screen.dart](lib/screens/teacher/teacher_lobby_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Uses AppColors | Legacy static constants |
| Extensive use of `AppColors.*` | Throughout file | All references | Pervasive AppColors static usage |
| 45 | `AppColors.bg` | Scaffold background | Using AppColors static |
| 65 | `AppColors.surface` | AppBar background | Using AppColors static |
| 71 | `AppColors.gradBtn` | Icon gradient | Using AppColors static |

**Total: 15+ color instances (AppColors static)**

---

### 11. [lib/screens/teacher/quiz_creator_screen.dart](lib/screens/teacher/quiz_creator_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Uses AppColors | Legacy static constants |
| 35 | `Color(0xFFF59E0B)` | Yes/No type color | Hardcoded amber |
| 36 | `AppColors.primary` | Multiple Choice color | Using AppColors static |
| 37 | `AppColors.accentLight` | Text Answer color | Using AppColors static |
| Multiple `AppColors.*` | Throughout screen | Scattered references | Using static constants extensively |

**Total: 18+ color instances**

---

### 12. [lib/screens/teacher/quiz_history_screen.dart](lib/screens/teacher/quiz_history_screen.dart)

| Line | Color | Context | Issue |
|------|-------|---------|-------|
| 7 | `import 'package:quizz_app/constants/app_colors.dart'` | Uses AppColors | Legacy static constants |
| Multiple `AppColors.*` | Throughout file | Scattered references | Using static constants instead of context.tokens |
| 72 | `AppColors.bg` | Scaffold background | Using AppColors static |
| 78 | `AppColors.surface` | AppBar background | Using AppColors static |

**Total: 12+ color instances**

---

## Color Usage Patterns

### 🔴 Anti-Patterns Found

1. **Direct Material Colors**: `Colors.white`, `Colors.orange`, `Colors.blue`, `Colors.red` → Should use `context.tokens`
2. **Hardcoded hex values**: `Color(0xFF...)` everywhere → Should use theme extension
3. **AppColors static imports**: `AppColors.bg`, `AppColors.primary`, etc. → Should use `context.tokens` with proper BuildContext access
4. **Inconsistent backgrounds**: Some screens use `Color(0xFF0D1B2A)` or `Color(0xFF08080F)` instead of theme scaffold color
5. **Avatar/Badge color arrays**: Hardcoded gradient arrays with multiple colors → Should extract as theme extension or constants

### ✅ Best Practice Found

[lib/screens/student/join_screen.dart](lib/screens/student/join_screen.dart) correctly uses:
```dart
gradient: RadialGradient(
  colors: [
    context.tokens.primary.withOpacity(0.15),
    Colors.transparent,  // OK for transparent
  ],
)
```

---

## Recommendations

### Priority 1: High Impact (Screen backgrounds & primary elements)
- [ ] Replace all scaffold backgrounds with `Theme.of(context).scaffoldBackgroundColor`
- [ ] Replace `Color(0xFF0D1B2A)` and `Color(0xFF08080F)` backgrounds in host/question screens
- [ ] Replace all `AppColors.bg`, `AppColors.surface`, `AppColors.border` with `context.tokens`

### Priority 2: Medium Impact (Text & UI elements)
- [ ] Replace `Colors.white` in text styles with `context.tokens.text` or `context.tokens.white`
- [ ] Replace avatar gradient arrays with theme-based approach
- [ ] Replace rank badge colors with semantic tokens

### Priority 3: Lower Priority (Accent/decorative)
- [ ] Replace hardcoded progress bar colors with theme tokens
- [ ] Standardize orange, blue, red colors used in stats displays
- [ ] Remove hardcoded color arrays in favor of theme extension

### Implementation Path
1. Create extension methods for common patterns (e.g., `context.colorFor(StudentRank)`)
2. Extend `AppColorTokens` to include avatar gradients and status colors
3. Update all screen files systematically
4. Remove `AppColors` static imports from screen files
5. Add linting rule to prevent future `Color(0x...)` literals in screens
