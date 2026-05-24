# MotionCore

**Personal iOS Fitness Tracker** — built with SwiftUI, SwiftData & HealthKit.

> Track cardio, outdoor activities, and strength training — all in one app with Apple Watch companion, CloudKit sync, and a Supabase-powered exercise database.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Data Models](#data-models)
- [Services & Integrations](#services--integrations)
- [Design Language](#design-language)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Author](#author)

---

## Overview

MotionCore is a personal fitness tracking app for iOS with an Apple Watch companion. It supports three distinct workout types, each with its own autonomous data model:

| Workout Type | Model | Description |
|---|---|---|
| **Cardio** | `CardioSession` | Indoor equipment (Crosstrainer, Ergometer) |
| **Outdoor** | `OutdoorSession` | Cycling, running, hiking with route & weather data |
| **Strength** | `StrengthSession` | Set-based strength training with progression tracking |

The app is designed around clean architecture principles, with a clear separation between business logic (CalcEngines) and presentation (Views).

---

## Features

### Workout Tracking
- **Live Sessions** — start, pause, and complete workouts in real-time
- **Manual Entry** — log past workouts with full detail
- **Session Resume** — recover interrupted sessions after app restart
- **Exercise Sets** — track weight, reps, RPE, RIR, rest times, and set types (work, warmup, drop, AMRAP)
- **Live Activity** — Dynamic Island / Lock Screen widget showing current workout progress and rest timer
- **Last Session Reference** — previous session values shown as subtle reference during active sets via `LastSessionReferenceCalcEngine`

### Training Plans
- Create reusable workout templates with predefined exercises and set configurations
- Start sessions directly from a plan — sets are pre-populated
- Track which sessions were derived from which plan

### Exercise Library
- Supabase-powered exercise database with German translations
- Filter by muscle group, equipment, category, difficulty, and movement pattern
- Exercise detail views with video demonstrations and instructions
- Support for custom exercises alongside system exercises
- Favorite and archive functionality

### Auto-Progression (RIR-based)
- `ProgressionCalcEngine` compares logged RIR against target RIR across the last N sessions
- Generates a `ProgressionRecommendation` with suggested weight increase when criteria are met
- Visual notification via `ProgressionBannerView` during active workouts

### Personal Records
- Automatic PR detection via `PRDetectionService`
- Tracked across exercises with banner notifications during workouts

### Statistics & Summary
- **Summary Dashboard** — aggregated stats across all workout types (week/month/year/all)
- **Workout type breakdown** — cardio vs. strength vs. outdoor distribution
- **Strength Statistics** — 1RM estimation charts, volume tracking per exercise
- **Records Overview** — personal bests across all categories
- **Streak Tracking** — weekly goal-based workout streaks

### Body Measurements
- Track body composition metrics over time (`BodyMeasurement` model)
- Ratio analysis via `BodyMeasurementRatioCalcEngine`
- Radar chart for body composition profile via `BodyMeasurementRadarCalcEngine`
- Trend visualization via `BodyMeasurementTrendCalcEngine`

### Health Integration
- Apple HealthKit integration for heart rate, calories, steps, exercise minutes, and sleep data
- Calorie hero card with active/basal/dietary breakdown
- Sleep stage analysis with trend charts
- Health metric trend visualization

### Apple Watch
- Companion watch app via `WatchSessionManager` / `PhoneSessionManager`
- Watch complications for streak display and weekly progress
- Active workout view on the wrist

### Sync & Backup
- **CloudKit** — automatic iCloud sync across devices (with local fallback)
- **Supabase** — post-workout session streaming to remote database
- **Resync Service** — detects locally modified sessions and re-uploads them
- App Group container shared between main app, widgets, and watch

---

## Architecture

### CalcEngine Pattern

All business logic lives in dedicated **CalcEngine** structs — pure value types with no SwiftUI dependencies. Views are strictly presentational.

```
View (SwiftUI)  →  CalcEngine (pure logic)  →  Model (SwiftData)
```

| CalcEngine | Responsibility |
|---|---|
| `CoreSessionCalcEngine` | Cross-session calculations and filtering |
| `SummaryCalcEngine` | Aggregated statistics across all workout types |
| `StatisticCalcEngine` | General workout statistics and trends |
| `StrengthStatisticCalcEngine` | Strength-specific stats (1RM, volume) |
| `HealthMetricCalcEngine` | HealthKit data processing and formatting |
| `RecordCalcEngine` | Personal record detection and ranking |
| `ProgressionCalcEngine` | RIR-based auto-progression recommendations |
| `LastSessionReferenceCalcEngine` | Previous session values as in-workout reference |
| `BodyMeasurementRatioCalcEngine` | Body measurement ratio calculations |
| `BodyMeasurementRadarCalcEngine` | Body measurement radar chart data |
| `BodyMeasurementTrendCalcEngine` | Body measurement trend analysis |

### Key Principles
- **Autonomous models** — each workout type has its own independent model (no shared base class)
- **German code comments, English variable/method names**
- **No testing code** — production-only focus
- **Singleton services** — shared instances for managers (`HealthKitManager.shared`, `ActiveSessionManager.shared`, etc.)
- **Single schema source** — all SwiftData models registered in `App/AppSchema.swift`

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Cloud Sync | CloudKit (automatic) |
| Remote Database | Supabase (PostgreSQL + RPC) |
| Health Data | HealthKit |
| Watch Connectivity | WatchConnectivity Framework |
| Live Activities | ActivityKit |
| Widgets | WidgetKit |

### Minimum Requirements
- iOS 17+ (SwiftData requirement)
- watchOS 10+
- Xcode 15+

---

## Data Models

### Core Session Models

**CardioSession** — Indoor cardio workouts
- Device type (Crosstrainer, Ergometer), training program, intensity
- Distance, duration, calories, heart rate, METs calculation
- Subjective rating (RPE, energy level)

**StrengthSession** — Set-based strength workouts
- Relationship to `ExerciseSet[]` (cascade delete)
- Optional reference to source `TrainingPlan`
- Computed: total volume, grouped sets, progress percentage, trained muscle groups

**OutdoorSession** — Outdoor activities
- Activity type (cycling, running, hiking), route info
- Elevation gain, speed data, weather conditions
- Start/end location tracking

### Supporting Models

**ExerciseSet** — Individual set within a strength session
- Weight, reps, RPE, RIR (calculated), rest seconds
- Set types: work, warmup, drop, AMRAP
- Target values for progression (targetRepsMin/Max, targetRIR)
- Superset grouping support
- Dual relationship: belongs to `StrengthSession` OR `TrainingPlan`

**Exercise** — Exercise definition (library)
- Category, equipment, difficulty, movement pattern, body position
- Primary/secondary muscle groups
- Video/poster paths (Supabase Storage)
- Instructions, tips, variations
- Progression step configuration (default 2.5 kg)

**TrainingPlan** — Reusable workout template
- Template sets with predefined exercises and configurations
- Plan types: cardio, strength, outdoor, mixed
- Tracks derived sessions

**BodyMeasurement** — Body composition tracking
- Weight, body fat percentage, muscle mass, and circumferences
- Timestamped for trend analysis via `BodyMeasurementTrendCalcEngine`

### Shared Protocols

**CoreSession** — Protocol adopted by all session types for unified handling in cross-type views and calculations.

---

## Services & Integrations

### Supabase Backend
- **`SupabaseClient`** — Base HTTP client with JSON encoding/decoding (snake_case conversion, ISO8601 dates with microseconds)
- **`SupabaseExerciseService`** — Exercise search with server-side filtering via RPC
- **`SupabaseSessionService`** — Post-workout session upload
- **`SupabaseResyncService`** — Detects & re-uploads locally modified sessions
- **`SupabaseMigrationService`** — Database migration support
- **`SupabaseFilterService`** — Server-side filter options (muscles, equipment)
- **`SupabaseStorageBucket`** — Video/poster file access from Supabase Storage

### HealthKit
- **`HealthKitManager`** — Singleton managing all HealthKit queries
- Publishes: heart rate, resting HR, steps, exercise minutes, calories (active/dietary/basal), sleep stages
- Uses `HKAnchoredObjectQuery` for live data, `HKStatisticsQuery` for daily totals

### Watch Connectivity
- **`PhoneSessionManager`** (iPhone side) — sends workout state to watch
- **`WatchSessionManager`** (Watch side) — receives state, manages watch UI
- **`WatchComplicationService`** — provides data for watch face complications

### Session Management
- **`ActiveSessionManager`** — manages active workout lifecycle (start, pause, resume, complete)
- **`SessionResumeStore`** — persists active session state for crash recovery

### Data Management
- **`IODataManager`** — import/export functionality
- **`DataRepairService`** — fixes data integrity issues on launch
- **`ExerciseImportManager`** — bulk exercise import from Supabase
- **`SwiftDataFactory`** — model container creation utilities

---

## Design Language

MotionCore uses a **Liquid Glass / Glassmorphism** design language:

- **Glass Cards** — frosted glass effect with blur material, white overlay, and subtle border stroke (`GlassCard` modifier)
- **Glass Buttons** — matching button style with hover/press states
- **Blue gradient palette**: `#F0F7FF` → `#C9E6FF` → `#9BD2FF`
- **Animated Blobs** — decorative background animation (`AnimatedBlob`)
- **Corner radius**: 22pt (cards), continuous rounding
- Theme support: System / Light / Dark

### Key UI Components

| Component | Purpose |
|---|---|
| `GlassCard` | ViewModifier for frosted glass card styling |
| `GlassButton` | Matching button component |
| `GlassDivider` | Styled divider |
| `FilterChip` | Selectable filter tag |
| `StatBubble` | Compact stat display |
| `FloatingButton` | Floating action button |
| `EmptyState` | Placeholder for empty lists |
| `HeaderView` | Section header |
| `DeviceBadge` / `DeviceButton` | Device source indicators |

---

## Project Structure

```
MotionCore/
├── App/
│   ├── MotionCoreApp.swift              # Entry point, ModelContainer setup
│   ├── AppSchema.swift                  # SwiftData schema (single source)
│   └── BaseView.swift                   # Tab-based main navigation
│
├── Models/
│   ├── CardioSession.swift              # Cardio workout model
│   ├── StrengthSession.swift            # Strength workout model
│   ├── OutdoorSession.swift             # Outdoor workout model
│   ├── ExerciseSet.swift                # Individual set model
│   ├── Exercise.swift                   # Exercise library model
│   ├── TrainingPlan.swift               # Workout template model
│   ├── BodyMeasurement.swift            # Body composition tracking model
│   └── CoreSession.swift                # Shared session protocol
│
├── Models/Types/
│   ├── CardioTypes.swift                # Cardio enums (device, program)
│   ├── StrengthTypes.swift              # Strength enums (workout type, set kind)
│   ├── OutdoorTypes.swift               # Outdoor enums (activity type, weather)
│   ├── ExerciseTypes.swift              # Exercise enums (category, equipment, muscles)
│   ├── TrainingTypes.swift              # Plan type enums
│   ├── FilterTypes.swift                # Filter-related enums
│   ├── UITypes.swift                    # UI state types
│   ├── UserTypes.swift                  # User profile types
│   ├── SleepTypes.swift                 # Sleep stage types
│   └── ErrorTypes.swift                 # Error definitions
│
├── CalcEngines/
│   ├── CoreSessionCalcEngine.swift      # Cross-session logic
│   ├── SummaryCalcEngine.swift          # Aggregated stats
│   ├── StatisticCalcEngine.swift        # General statistics
│   ├── StrengthStatisticCalcEngine.swift # Strength-specific stats
│   ├── HealthMetricCalcEngine.swift     # HealthKit processing
│   ├── RecordCalcEngine.swift           # PR detection logic
│   ├── ProgressionCalcEngine.swift      # RIR auto-progression
│   ├── LastSessionReferenceCalcEngine.swift # Previous session reference
│   ├── BodyMeasurementRatioCalcEngine.swift # Body ratio calculations
│   ├── BodyMeasurementRadarCalcEngine.swift # Body radar chart data
│   └── BodyMeasurementTrendCalcEngine.swift # Body trend analysis
│
├── Services/
│   ├── Database/Local/
│   │   ├── SwiftDataFactory.swift       # Container creation
│   │   ├── IODataManager.swift          # Import/Export
│   │   └── DataRepairService.swift      # Data integrity
│   │
│   ├── Database/Remote/
│   │   ├── SupabaseClient.swift         # HTTP client
│   │   ├── SupabaseConfig.swift         # URL & key config
│   │   ├── SupabaseExerciseService.swift
│   │   ├── SupabaseSessionService.swift
│   │   ├── SupabaseResyncService.swift
│   │   ├── SupabaseMigrationService.swift
│   │   ├── SupabaseFilterService.swift
│   │   └── SupabaseStorageBucket.swift
│   │
│   ├── Plan/
│   │   └── PlanUpdateApplicator.swift   # Plan update application logic
│   │
│   ├── HealthKitManager.swift           # HealthKit integration
│   ├── PRDetectionService.swift         # Personal record detection
│   ├── ActiveSessionManager.swift       # Workout lifecycle
│   └── SessionResumeStore.swift         # Crash recovery
│
├── Views/
│   ├── Summary/                         # Dashboard views
│   ├── Workouts/                        # Workout list, detail, edit
│   ├── ActiveWorkout/                   # Live workout UI
│   ├── Training/                        # Training plan management
│   ├── Exercises/                       # Exercise library & search
│   ├── Statistics/                      # Stats, records, charts
│   ├── Body/                            # Body measurements
│   ├── HealthMetrics/                   # HealthKit display
│   └── Settings/                        # App configuration
│
├── Components/
│   ├── Cards/                           # GlassCard, StatBubble, etc.
│   ├── Buttons/                         # GlassButton, FloatingButton, etc.
│   └── Shared/                          # FilterChip, EmptyState, etc.
│
├── Utils/
│   ├── Formatters/                      # AppFormatter, NumberFormatting
│   ├── Extensions/                      # Color, View extensions
│   └── Mappers/                         # MuscleGroupMapper
│
├── Watch/
│   ├── MotionCoreWatchApp.swift         # Watch entry point
│   ├── WatchSessionManager.swift        # Watch connectivity
│   ├── WatchActiveWorkoutView.swift     # Workout on wrist
│   ├── WatchComplicationService.swift   # Complication data
│   ├── StreakComplication.swift          # Streak display
│   └── WeeklyProgressComplication.swift # Weekly progress
│
├── Widgets/
│   ├── MotionCoreWidgets.swift          # Home screen widget
│   ├── MotionCoreWidgetsLiveActivity.swift # Live Activity UI
│   └── WorkoutActivityAttributes.swift  # Live Activity data model
│
└── Theme/
    ├── AppTheme.swift                   # Light/Dark/System
    ├── BackgroundSettings.swift         # Animated backgrounds
    └── AnimatedBlob.swift               # Decorative blobs
```

---

## Configuration

### Supabase
Credentials are managed via `.xcconfig` files (not checked into version control):

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key
```

These are read by `SupabaseConfig.swift` at runtime. If credentials are missing, the app degrades gracefully (Supabase features disabled, local data unaffected).

### CloudKit
- Requires an iCloud container configured in Xcode capabilities
- App Group: `group.com.barto.motioncore` (shared between app, widgets, watch)
- CloudKit is automatically disabled in the Simulator
- Fallback to local-only storage if CloudKit initialization fails

### HealthKit
- Requires HealthKit capability in Xcode
- Permission requests handled by `HealthKitManager` on first launch
- Read access: heart rate, resting HR, steps, active energy, dietary energy, basal energy, exercise time, sleep analysis

---

## Author

**Bartosz Stryjewski**

© 2025–2026 Bartosz Stryjewski. All rights reserved.
