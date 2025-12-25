# Product Requirements Document (PRD)
## Exercise Management, Body Weight Tracking, and Health Metrics

**Product**: Workout Tracking App  
**Platform**: iOS 17+ (SwiftData requires iOS 17+)  
**Architecture**: Offline-first, local SwiftData persistence  
**Audience**: Individual users  
**Date**: 2025-12-25

---

## Summary

Enhance the workout tracking app with exercise management capabilities (create, edit, delete), category filtering in template exercise selection, body weight tracking with entry management, and Apple Health-style metric cards on the home screen. These features improve exercise customization, health tracking, and provide visual insights into workout progress.

**Core Principle**: Empower users to customize their exercise library, track body weight over time, and visualize workout metrics at a glance.

---

## User Stories (Gherkin Format)

### Exercise Management

**Scenario: Create New Exercise**
```
Given the user is viewing the Exercises screen
When they tap a "+" or "Add Exercise" button
Then an exercise creation form appears
And they can enter exercise name, category, muscle groups, icon, and notes
And when they save, the exercise is added to the ExerciseTemplate catalog
And the exercise appears in the exercises list immediately
```

**Scenario: Edit Existing Exercise**
```
Given the user is viewing the Exercises screen
And an exercise exists in the catalog
When they swipe left on an exercise row
Or tap an edit button
Then an edit form appears with the exercise's current data
And they can modify any field (name, category, muscle groups, icon, notes)
And when they save, the exercise is updated in SwiftData
And the changes are reflected immediately in the list
```

**Scenario: Delete Exercise**
```
Given the user is viewing the Exercises screen
And an exercise exists in the catalog
When they swipe left on an exercise row
And tap the delete button
Then a confirmation dialog appears
And when they confirm deletion, the exercise is removed from SwiftData
And the exercise disappears from the list
And any workout templates using this exercise still reference it by name (snapshot preserved)
```

### Template Exercise Filtering

**Scenario: Filter Exercises by Category in Template Creation**
```
Given the user is creating or editing a workout template
And they tap "Add Exercise"
When the Add Exercise to Template sheet appears
Then they see category filter buttons (Strength, Cardio, Flexibility, Other, All)
And they can tap a category to filter exercises
And only exercises matching that category are displayed
And the filter persists during their multi-select session
And they can clear the filter by selecting "All"
```

**Scenario: Search and Filter Combined in Template Selection**
```
Given the user is adding exercises to a template
And the Add Exercise sheet is open
When they enter search text
And select a category filter
Then the exercises are filtered by both search text AND category
And the filtered results update in real-time
```

### Body Weight Tracking

**Scenario: Record Body Weight Entry**
```
Given the user is on the Home screen
Or viewing a body weight tracking screen
When they tap "Add Weight" or a "+" button
Then a weight entry form appears
And they can enter weight value (in kg or lbs based on preference)
And optionally add a date/time (defaults to now)
And when they save, the weight entry is stored in SwiftData
And the entry appears in the weight history
```

**Scenario: View Body Weight History**
```
Given the user has recorded body weight entries
When they view the body weight section
Then they see a list of weight entries sorted by date (newest first)
And each entry shows weight value, date, and time
And they can scroll through historical entries
And they see a trend indicator (up/down arrow or chart)
```

**Scenario: Edit Body Weight Entry**
```
Given the user is viewing body weight history
And a weight entry exists
When they tap on an entry
Or swipe left and tap edit
Then an edit form appears with the entry's current data
And they can modify the weight value and/or date
And when they save, the entry is updated in SwiftData
And the changes are reflected in the history list
```

**Scenario: Delete Body Weight Entry**
```
Given the user is viewing body weight history
And a weight entry exists
When they swipe left on an entry
And tap the delete button
Then a confirmation dialog appears
And when they confirm deletion, the entry is removed from SwiftData
And the entry disappears from the history list
```

### Health Metrics Dashboard

**Scenario: View Metric Cards on Home Screen**
```
Given the user is on the Home/Summary tab
When they view the screen
Then they see metric cards displaying:
  - Total Workouts (count of completed workouts)
  - Total Exercise Time (sum of workout durations)
  - Average Workout Duration (average time per workout)
  - Body Weight Trend (current weight vs previous, with change indicator)
  - Workouts This Week (count of workouts in last 7 days)
  - Most Used Exercise (exercise with highest usage count)
And each card has an icon, value, label, and optional trend indicator
And cards are arranged in a grid layout (2 columns on iPhone)
```

**Scenario: Metric Card Visual Design**
```
Given the user is viewing metric cards
When they see each card
Then cards have:
  - Rounded corners and subtle shadow
  - Icon in top-left corner
  - Large value text (primary metric)
  - Small label text below value
  - Optional trend indicator (up/down arrow with percentage)
  - Background color that matches the metric type
And cards are tappable to view detailed information (future enhancement)
```

**Scenario: Metric Card Data Updates**
```
Given metric cards are displayed on the Home screen
When workout data changes (new workout completed, weight entry added)
Then the metric cards update automatically
And the values reflect the latest data from SwiftData
And updates happen without requiring app restart
```

---

## Functional Requirements

### 1. Exercise Management

1.1. **Create Exercise**
- Add "+" button or toolbar item to `ExercisesView` navigation bar
- Create `ExerciseEditView` (reusable for create/edit) at `healthy_swiftdata/Views/ExerciseEditView.swift`
- Form fields:
  - Exercise Name (required, TextField)
  - Category (required, Picker: Strength, Cardio, Flexibility, Other)
  - Muscle Groups (optional, multi-select or comma-separated input)
  - Icon (optional, SF Symbol picker or default)
  - Icon Color (optional, color picker or default)
  - Notes (optional, multi-line TextField)
- Save creates new `ExerciseTemplate` and inserts into ModelContext
- Validation: Name cannot be empty, category must be selected

1.2. **Edit Exercise**
- Add swipe action "Edit" to `ExerciseRow` in `ExercisesView`
- Reuse `ExerciseEditView` with existing exercise data pre-populated
- Update existing `ExerciseTemplate` fields in ModelContext
- Save updates the exercise in SwiftData
- Validation: Same as create

1.3. **Delete Exercise**
- Add swipe action "Delete" (destructive) to `ExerciseRow` in `ExercisesView`
- Show confirmation alert before deletion
- Delete `ExerciseTemplate` from ModelContext
- Note: Deleting an exercise does NOT delete it from workout templates (TemplateExercise stores `exerciseName` snapshot)
- Save context to persist deletion

### 2. Template Exercise Filtering

2.1. **Category Filtering in AddExerciseToTemplateSheet**
- Update `AddExerciseToTemplateSheet` in `WorkoutTemplateEditView.swift` (line 270-325)
- Add `@State private var selectedCategory: String?` for filter state
- Add category filter buttons section (similar to `ExercisesView` pattern)
- Update `filteredTemplates` computed property to filter by `selectedCategory` when not nil
- Combine category filter with existing search text filter
- Display "All" option to clear category filter

2.2. **Filter UI Integration**
- Place category filter buttons above exercise list (similar to ExercisesView:54-82)
- Use `CategoryFilterButton` component (already exists in ExercisesView)
- Filter persists during multi-select session
- Clear filter when sheet is dismissed

### 3. Body Weight Tracking

3.1. **Body Weight Model (NEW)**
- Create `BodyWeightEntry` SwiftData model at `healthy_swiftdata/Models/BodyWeightEntry.swift`
- Fields:
  - `id: UUID` - Unique identifier
  - `weight: Double` - Weight value (in user's preferred unit)
  - `unit: String` - Unit of measurement ("kg" or "lbs", default: "kg")
  - `recordedAt: Date` - Timestamp when weight was recorded
  - `notes: String?` - Optional notes
  - `createdAt: Date` - Creation timestamp
- Purpose: Store body weight measurements over time

3.2. **Body Weight Entry View (NEW)**
- Create `BodyWeightView` at `healthy_swiftdata/Views/BodyWeightView.swift`
- Display list of weight entries sorted by `recordedAt` descending
- Show weight value, unit, date, and optional notes for each entry
- Add "+" button to create new entry
- Swipe actions: Edit and Delete
- Empty state when no entries exist

3.3. **Body Weight Entry Form (NEW)**
- Create `BodyWeightEntryForm` component (reusable for create/edit)
- Form fields:
  - Weight value (required, DecimalTextField)
  - Unit picker (kg/lbs, defaults to user preference or "kg")
  - Date picker (defaults to now, can be adjusted)
  - Notes (optional, multi-line TextField)
- Save creates/updates `BodyWeightEntry` in ModelContext
- Validation: Weight must be > 0

3.4. **Body Weight Integration**
- Add body weight section to `ContentView` Home screen
- Display current weight (most recent entry) with trend indicator
- Add quick link to "View Weight History" or full `BodyWeightView`
- Update ModelContainer schema to include `BodyWeightEntry.self`

### 4. Health Metrics Dashboard

4.1. **Metric Card Component (NEW)**
- Create `MetricCard` reusable component at `healthy_swiftdata/Views/MetricCard.swift`
- Properties:
  - `icon: String` - SF Symbol name
  - `value: String` - Primary metric value
  - `label: String` - Metric description
  - `trend: MetricTrend?` - Optional trend data (up/down, percentage)
  - `color: Color` - Card accent color
- Layout: Icon, value, label, optional trend indicator
- Style: Rounded corners, shadow, background color

4.2. **Metric Calculations**
- Create `MetricsCalculator` utility at `healthy_swiftdata/Utilities/MetricsCalculator.swift`
- Calculate metrics from SwiftData:
  - **Total Workouts**: Count of `WorkoutHistory` entries
  - **Total Exercise Time**: Sum of workout durations (if `WorkoutHistory` has duration field)
  - **Average Workout Duration**: Total time / workout count
  - **Body Weight Trend**: Current weight vs previous weight, calculate change percentage
  - **Workouts This Week**: Count of workouts with `completedAt` in last 7 days
  - **Most Used Exercise**: Count exerciseName occurrences in WorkoutHistory.entries across all workouts, return exercise name with highest count (iterate through all WorkoutHistory entries, count exerciseName strings, return most frequent)
- Return computed values as `MetricData` struct

4.3. **Metrics Display in ContentView**
- Update `ContentView` to include metrics section
- Replace or enhance existing "Statistics" section with metric cards
- Display cards in grid layout (2 columns on iPhone, 3 on iPad)
- Use `LazyVGrid` for efficient rendering
- Cards update automatically when data changes (via @Query)

4.4. **Metric Card Types**
- **Total Workouts Card**: Icon: "figure.strengthtraining.traditional", Color: Blue
- **Total Exercise Time Card**: Icon: "clock.fill", Color: Green, Format: "X hours Y minutes"
- **Average Duration Card**: Icon: "timer", Color: Orange, Format: "X minutes"
- **Body Weight Trend Card**: Icon: "scalemass", Color: Purple, Show trend arrow and change
- **Workouts This Week Card**: Icon: "calendar", Color: Red
- **Most Used Exercise Card**: Icon: "star.fill", Color: Yellow, Show exercise name

---

## Non-Goals

- **Exercise Import/Export**: No bulk import or export of exercises (manual entry only)
- **Exercise Templates**: No exercise templates or presets (users create from scratch)
- **Body Weight Goals**: No weight goal setting or tracking (just historical data)
- **Body Weight Charts**: No detailed charts or graphs (basic trend indicator only)
- **Metric Card Details**: No drill-down into detailed metric views (future enhancement)
- **Unit Conversion**: No automatic unit conversion (user selects unit per entry)
- **Exercise Photos**: No photo uploads for exercises (icon only)
- **Exercise Videos**: No video links or embedded content

---

## Success Metrics

- Users can create, edit, and delete exercises from the Exercises screen
- Category filtering works in template exercise selection sheet
- Users can record, edit, and delete body weight entries
- Body weight entries persist and display in chronological order
- Metric cards display accurate calculated values on Home screen
- Metric cards update automatically when workout data changes
- All operations persist to SwiftData immediately

---

## Affected Files

### Modified Files
- `healthy_swiftdata/Views/ExercisesView.swift` - Add create/edit/delete actions, integrate ExerciseEditView
- `healthy_swiftdata/Views/WorkoutTemplateEditView.swift` - Add category filtering to AddExerciseToTemplateSheet
- `healthy_swiftdata/ContentView.swift` - Add metric cards section, body weight quick view
- `healthy_swiftdata/healthy_swiftdataApp.swift` - Add BodyWeightEntry to ModelContainer schema

### New Files
- `healthy_swiftdata/Views/ExerciseEditView.swift` - Create/edit exercise form
- `healthy_swiftdata/Views/BodyWeightView.swift` - Body weight entry list and management
- `healthy_swiftdata/Views/BodyWeightEntryForm.swift` - Body weight entry create/edit form
- `healthy_swiftdata/Views/MetricCard.swift` - Reusable metric card component
- `healthy_swiftdata/Models/BodyWeightEntry.swift` - Body weight data model
- `healthy_swiftdata/Utilities/MetricsCalculator.swift` - Metric calculation utility

---

## 🔍 Implementation Assumptions

### UI/UX Assumptions (MUST AUDIT)
- **Exercise Edit Form**: ASSUMED reusable form component can handle both create and edit modes (CERTAIN - standard SwiftUI pattern)
- **Swipe Actions**: ASSUMED `.swipeActions(edge: .trailing)` works on ExerciseRow similar to other list rows (CERTAIN - verified pattern exists)
- **Category Filtering**: ASSUMED AddExerciseToTemplateSheet can reuse CategoryFilterButton pattern from ExercisesView (CERTAIN - same component exists)
- **Metric Cards**: ASSUMED LazyVGrid with 2 columns works well on iPhone for metric cards (CERTAIN - standard SwiftUI layout)
- **Body Weight Form**: ASSUMED DecimalTextField or TextField with number format works for weight input (CERTAIN - standard iOS pattern)

### Data Model Assumptions (MUST AUDIT)
- **Body Weight Model**: ASSUMED BodyWeightEntry can be added to existing ModelContainer schema without migration issues (LIKELY - new model, no relationships)
- **Exercise Deletion**: ASSUMED deleting ExerciseTemplate does not cascade delete TemplateExercise references (CERTAIN - TemplateExercise stores exerciseName snapshot, not relationship) ✅ VERIFIED
- **Metric Calculations**: ASSUMED WorkoutHistory has durationSeconds field (CERTAIN - VERIFIED - WorkoutHistory.swift:18 has durationSeconds: Int?) ✅ VERIFIED

### State Management Assumptions (MUST AUDIT)
- **Metric Updates**: ASSUMED @Query on WorkoutHistory and BodyWeightEntry will trigger metric recalculation automatically (CERTAIN - @Query updates trigger view refresh)
- **Filter State**: ASSUMED @State for category filter in AddExerciseToTemplateSheet will persist during multi-select session (CERTAIN - standard @State behavior)

---

## Git Strategy

**Branch**: `feature/exercise-management-body-weight-metrics`

**Commit Strategy**: Phased commits with descriptive messages

1. **Phase 1**: Exercise Management
   - Commit: `feat: add create, edit, and delete functionality for exercises`

2. **Phase 2**: Template Exercise Filtering
   - Commit: `feat: add category filtering to template exercise selection`

3. **Phase 3**: Body Weight Tracking
   - Commit: `feat: add body weight tracking model and views`

4. **Phase 4**: Health Metrics Dashboard
   - Commit: `feat: add Apple Health-style metric cards to home screen`

---

## QA Strategy

### LLM Self-Test Scenarios

**Exercise Management**
- Create new exercise with all fields
- Edit existing exercise and verify changes persist
- Delete exercise and verify removal
- Verify deleted exercise name still appears in workout templates (snapshot preserved)

**Template Exercise Filtering**
- Open Add Exercise sheet in template creation
- Apply category filter
- Verify only filtered exercises appear
- Combine search and category filter
- Verify multi-select works with filters applied

**Body Weight Tracking**
- Record new weight entry
- Edit weight entry and verify update
- Delete weight entry and verify removal
- Verify entries sorted by date (newest first)
- Verify current weight displays on home screen

**Health Metrics**
- Complete a workout and verify metrics update
- Record weight entry and verify weight metric updates
- Verify all metric cards display correct values
- Verify metric cards update automatically when data changes

### Manual User Verification

- Test full workflow: Create exercise → Use in template → Delete exercise → Verify template still works
- Test body weight tracking: Record multiple entries → Edit one → Delete one → Verify trend calculation
- Test metric cards: Complete workouts → Record weight → Verify all cards show accurate data
- Verify UI responsiveness and visual design matches Apple Health style

---

## Technical Architecture Details

### Exercise Edit Form Implementation

**Reusable Component Pattern**:
```swift
struct ExerciseEditView: View {
    let exercise: ExerciseTemplate? // nil for create, existing for edit
    @State private var name: String
    @State private var category: String?
    // ... other fields
    
    init(exercise: ExerciseTemplate? = nil) {
        self.exercise = exercise
        // Initialize @State from exercise if editing
    }
}
```

### Body Weight Model Structure

```swift
@Model
final class BodyWeightEntry {
    var id: UUID
    var weight: Double
    var unit: String // "kg" or "lbs"
    var recordedAt: Date
    var notes: String?
    var createdAt: Date
}
```

### Metric Card Component Structure

```swift
struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let trend: MetricTrend?
    let color: Color
    
    struct MetricTrend {
        let direction: TrendDirection // .up, .down, .neutral
        let percentage: Double?
    }
}
```

### Metrics Calculation Approach

- Use `@Query` to fetch `WorkoutHistory` and `BodyWeightEntry` arrays
- Calculate metrics in computed properties or helper functions
- Cache calculations if performance becomes an issue
- Update calculations when @Query results change

---

## Future Enhancements (Out of Scope)

- Exercise photo uploads
- Body weight goal setting and tracking
- Detailed metric charts and graphs
- Metric card drill-down views
- Exercise templates/presets
- Bulk exercise import/export
- Body weight unit auto-conversion
- Exercise video links
- Advanced metric filtering (date ranges, etc.)

---

## Current State Audit Results

### Data Model Verification

- ✅ **WorkoutHistory.durationSeconds**: VERIFIED - `WorkoutHistory.swift:18` - Field exists as `Int?`, populated when workout finishes (ActiveWorkoutView:235)
- ✅ **WorkoutHistory.totalVolume**: VERIFIED - `WorkoutHistory.swift:19` - Field exists as `Double?`, calculated from sets (ActiveWorkoutView:238-249)
- ✅ **ExerciseTemplate.lastUsed**: VERIFIED - `ExerciseTemplate.swift:21` - Field exists as `Date?`, updated when template is used (WorkoutTemplatesView:161)
- ✅ **TemplateExercise.exerciseName**: VERIFIED - `TemplateExercise.swift:15` - Stores snapshot string, not relationship to ExerciseTemplate (TemplateExercise.swift:14-15 shows optional relationship + snapshot)
- ✅ **ExerciseTemplate fields**: VERIFIED - All fields match PRD: id, name, category, muscleGroups, icon, iconColor, notes, createdAt, lastUsed

### UI Pattern Verification

- ✅ **Swipe Actions Pattern**: VERIFIED - `ActiveWorkoutView.swift:383` and `WorkoutTemplatesView.swift:278` - `.swipeActions(edge: .trailing, allowsFullSwipe: false)` pattern exists, can be applied to ExerciseRow
- ✅ **CategoryFilterButton Component**: VERIFIED - `ExercisesView.swift:116-133` - Component exists and can be reused in AddExerciseToTemplateSheet
- ✅ **ExercisesView Structure**: VERIFIED - `ExercisesView.swift:50-113` - Uses List with ForEach, searchable modifier, category filters - can add toolbar button and swipe actions

### View Structure Verification

- ✅ **ExercisesView Location**: VERIFIED - `healthy_swiftdata/Views/ExercisesView.swift` exists
- ✅ **AddExerciseToTemplateSheet Structure**: VERIFIED - `WorkoutTemplateEditView.swift:291-369` - Sheet exists with List, search, multi-select - can add category filter section
- ✅ **ContentView Structure**: VERIFIED - `healthy_swiftdata/ContentView.swift:26-185` - Has Statistics section at line 142-150, can replace/enhance with metric cards
- ✅ **ModelContainer Schema**: VERIFIED - `healthy_swiftdataApp.swift:18-26` - Schema array exists, can add BodyWeightEntry.self

### Gap Analysis

**Missing Components:**
- ExerciseEditView (needs CREATE)
- BodyWeightEntry model (needs CREATE)
- BodyWeightView (needs CREATE)
- BodyWeightEntryForm (needs CREATE)
- MetricCard component (needs CREATE)
- MetricsCalculator utility (needs CREATE)

**Modifications Needed:**
- ExercisesView: Add toolbar "+" button, swipe actions for edit/delete, integrate ExerciseEditView sheet
- AddExerciseToTemplateSheet: Add category filter state and UI
- ContentView: Add metric cards section, body weight quick view
- ModelContainer: Add BodyWeightEntry to schema

**Assumptions Needing Clarification:**
- **Most Used Exercise Calculation**: CLARIFIED - ExerciseTemplate.lastUsed is only updated for WorkoutTemplate usage, not individual exercise usage. Strategy: Count exerciseName occurrences in WorkoutHistory.entries across all workouts (iterate through all WorkoutHistory entries, count exerciseName strings, return most frequent). This is accurate for actual exercise usage in completed workouts.
- **Body Weight Unit Preference**: CLARIFIED - No user preferences system exists. Strategy: Default to "kg" for all entries, allow per-entry unit selection (kg/lbs) in BodyWeightEntryForm. Each entry stores its own unit.
- **Metric Calculation Performance**: ACCEPTED RISK - @Query will trigger recalculation on each update. With typical usage (<1000 workouts), this should be acceptable. Recommendation: Start simple, optimize with caching if performance issues arise.

**Current Logic:**
- WorkoutHistory durationSeconds is calculated and stored (verified in finishWorkout)
- TemplateExercise stores exerciseName as snapshot (verified in TemplateExercise model)
- Exercise deletion will NOT cascade to TemplateExercise (verified - snapshot pattern)
- Swipe actions pattern exists and can be reused (verified in multiple views)

---

## Executable Implementation Plan

**Status**: ✅ COMPLETED  
**Review Date**: 2025-12-25  
**Completion Date**: 2025-12-25  
**Completeness Score**: 10/10 (all phases implemented and committed)

### Phase Rules

- **Maximum 3 tasks per phase** (excluding validation and commit)
- Each phase must have a validation gate before proceeding
- All changes must be committed before moving to next phase
- Use descriptive commit messages following pattern: `feat:`, `fix:`, `refactor:`

### Production Safety Checklist

- [ ] No mock data or placeholder values
- [ ] All SwiftData models properly initialized with required fields
- [ ] Exercise deletion properly handles TemplateExercise snapshots (no cascade)
- [ ] Body weight validation (weight > 0)
- [ ] Metric calculations handle edge cases (empty arrays, nil values)
- [ ] All user actions persist to SwiftData immediately

---

## Tasks

### Phase 1 (1.0) - Exercise Management ✅ [COMPLETED]

- [x] 1.0 `git commit -m "feat: add create, edit, and delete functionality for exercises"` (commit: 066db67)
- [x] 1.1 Create ExerciseEditView at `healthy_swiftdata/Views/ExerciseEditView.swift` with form fields: name (required), category (Picker), muscleGroups (TextField for comma-separated), icon (default for now), iconColor (default for now), notes (optional)
- [x] 1.2 Update ExercisesView to add "+" toolbar button that presents ExerciseEditView sheet, add swipe actions (Edit and Delete) to ExerciseRow with edit sheet and delete confirmation
- [x] 1.3 Implement save logic in ExerciseEditView: create new ExerciseTemplate for create mode, update existing for edit mode, insert/update in ModelContext, save context, dismiss sheet
- [x] 1.4 Build validation: Verify exercise create/edit/delete works, verify deleted exercise name still appears in workout templates, verify changes persist (linter: no errors)
- [x] 1.5 User confirmation checkpoint - Exercise management working

### Phase 2 (2.0) - Template Exercise Filtering ✅ [COMPLETED]

- [x] 2.0 `git commit -m "feat: add category filtering to template exercise selection"` (commit: 7de1afb)
- [x] 2.1 Update AddExerciseToTemplateSheet to add `@State private var selectedCategory: String?` and `availableCategories` computed property (similar to ExercisesView pattern)
- [x] 2.2 Add category filter buttons section above exercise list using CategoryFilterButton component, update filteredTemplates to combine category filter with search text filter
- [x] 2.3 Build validation: Verify category filtering works, verify combined search + category filter works, verify multi-select works with filters applied (linter: no errors)
- [x] 2.4 User confirmation checkpoint - Template exercise filtering working

### Phase 3 (3.0) - Body Weight Tracking ✅ [COMPLETED]

- [x] 3.0 `git commit -m "feat: add body weight tracking model and views"` (commit: a4547d1)
- [x] 3.1 Create BodyWeightEntry model at `healthy_swiftdata/Models/BodyWeightEntry.swift` with fields: id (UUID), weight (Double), unit (String, default "kg"), recordedAt (Date), notes (String?), createdAt (Date)
- [x] 3.2 Update ModelContainer schema in healthy_swiftdataApp.swift to include BodyWeightEntry.self
- [x] 3.3 Create BodyWeightEntryForm component (reusable for create/edit) with weight TextField, unit Picker (kg/lbs), date picker, notes field
- [x] 3.4 Create BodyWeightView at `healthy_swiftdata/Views/BodyWeightView.swift` with @Query for entries sorted by recordedAt descending, List display, "+" button, swipe actions (Edit/Delete)
- [x] 3.5 Add body weight section to ContentView showing current weight (most recent entry) with trend indicator
- [x] 3.6 Build validation: Verify weight entry create/edit/delete works, verify entries sorted correctly, verify current weight displays on home screen (linter: no errors)
- [x] 3.7 User confirmation checkpoint - Body weight tracking working

### Phase 4 (4.0) - Health Metrics Dashboard ✅ [COMPLETED]

- [x] 4.0 `git commit -m "feat: add Apple Health-style metric cards to home screen"` (commit: 550316f)
- [x] 4.1 Create MetricCard component at `healthy_swiftdata/Views/MetricCard.swift` with icon, value, label, optional trend (MetricTrend struct), color properties
- [x] 4.2 Create MetricsCalculator utility at `healthy_swiftdata/Utilities/MetricsCalculator.swift` with static methods to calculate: Total Workouts (count), Total Exercise Time (sum durationSeconds), Average Duration (total time / count), Body Weight Trend (current vs previous), Workouts This Week (count in last 7 days), Most Used Exercise (count exerciseName occurrences in WorkoutHistory.entries across all workouts, return exercise name with highest count)
- [x] 4.3 Update ContentView to add metrics section with LazyVGrid (2 columns), calculate metrics using MetricsCalculator, display MetricCard components for each metric
- [x] 4.4 Build validation: Verify all metric cards display correct values, verify metrics update when workout data changes, verify edge cases (empty data, nil values) (linter: no errors)
- [x] 4.5 User confirmation checkpoint - Health metrics dashboard working

