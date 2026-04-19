---
name: swift-standards
description: MotionCore Swift coding standards and conventions. Use when writing, reviewing, or refactoring Swift code. Also use when creating new files or splitting large files.
---
 
# Swift Coding Standards — MotionCore
 
## Naming
 
- Types: `UpperCamelCase` (`ExerciseSet`, `StatBubble`)
- Properties / Methods: `lowerCamelCase` (`totalVolume`, `formatDuration()`)
- CalcEngines: `[Domain]CalcEngine` (`ProgressionCalcEngine`, `RecordCalcEngine`)
- ViewModels: `[Domain]ViewModel` (`ProgressionViewModel`)
- Views: `[Feature]View`, `[Feature]Card`, `[Feature]Sheet`, `[Feature]Row`
- Types files: `[Domain]Types.swift` for enums and small structs that belong to a domain
 
## File Structure
 
Every Swift file follows this order:
 
1. File header (copy from an existing file)
2. `import` statements
3. Main type definition
4. `// MARK: -` sections in this order:
   - Properties
   - Body (for Views)
   - Subviews (as `private var`)
   - Helper Functions
5. Extensions
6. Preview
 
## File Size and Separation
 
- Target: **max 400 lines per file**
- Hard warning: files above **600 lines** should be actively split
- Files approaching or exceeding 800–1000 lines (like `ActiveWorkoutView.swift`) are a clear signal to extract
 
### When to extract into a separate file
 
- A group of related helper functions is reused or could be reused → extract to a utility file
- A subview has its own state (`@State`, `@Binding`) → extract to its own View file
- A `// MARK: -` section exceeds ~150 lines → candidate for extraction
- Multiple files use the same formatting logic → extract to a shared helper (e.g. `AppFormatter.swift`)
- A CalcEngine method group grows beyond its domain → split into a focused CalcEngine
 
### How to name extracted files
 
- Subview extracted from `ActiveWorkoutView` → `ActiveWorkout[Section]View.swift` (e.g. `ActiveWorkoutStatsSection.swift`)
- Shared helper functions → `[Domain]Helper.swift` or add to existing utilities
- Reusable UI components → place in the shared components directory
 
### What stays together
 
- A View and its small, tightly coupled private subviews (under 400 lines total)
- A CalcEngine and its directly related result types (if small)
- An extension that only makes sense in the context of its parent file
 
## SwiftUI Views
 
- Extract subviews as `private var` computed properties
- No business logic in `body` or computed view properties
- Use `@EnvironmentObject` for app-wide state (`AppSettings.shared`)
- Prefer `.task {}` over `.onAppear` for async work
- Use `.onChange(of:)` for reactive updates
- Large lists must use `LazyVStack` / `LazyVGrid`
- Use `scrollViewContentPadding()` instead of manual `.padding(.horizontal)`
- Cards always use `.glassCard()`
- Empty states always use `EmptyState()`
 
## SwiftData Models
 
- All stored properties: optional or with default value
- Inverse relationships are mandatory
- Computed properties for derived data
- Safe accessor pattern: `var safeItems: [Item] { items ?? [] }`
- Prefer `exerciseNameSnapshot` over `exerciseName`
 
## CalcEngine Pattern
 
- CalcEngines are **pure structs** with no state and no side effects
- They receive data through their initializer or method parameters
- They return computed results — they do not modify models
- Views never contain business logic; they call CalcEngines instead
- One CalcEngine per domain (statistics, records, progression, etc.)
 
## Code Quality
 
- No temporary workarounds — find the root cause
- No force-unwraps without a clear, documented reason
- No `\n` in SwiftUI `Text` — use separate views
- No `Timer.scheduledTimer` for background-sensitive timing — use `Date` anchors
- Remove debug `print` statements before completing a task
- Check for existing shared types before creating new ones