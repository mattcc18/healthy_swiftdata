# Product Requirements Document (PRD)
## Workout App Enhancements and UX Improvements

**Product**: Workout Tracking App  
**Platform**: iOS 17+ (SwiftData requires iOS 17+)  
**Architecture**: Offline-first, local SwiftData persistence  
**Audience**: Individual users  
**Date**: 2025-12-24

---

## Summary

Enhance the workout tracking app with improved UX features including set deletion, keyboard dismissal, exercise filtering, template seeding, multi-select exercises, and timer minimization. These improvements focus on making the app more intuitive and efficient to use during active workout sessions.

**Core Principle**: Improve workflow efficiency and reduce friction during active workouts.

---

## User Stories (Gherkin Format)

### Set Management

**Scenario: Delete Set from Active Workout**
```
Given the user is in an active workout
And viewing an exercise with multiple sets
When they swipe left on a set row
Then a delete action appears
And when they tap delete, the set is removed from the workout
And the set is deleted from SwiftData
And the workout view updates to reflect the deletion
```

**Scenario: Swipe to Delete Set**
```
Given the user is viewing sets in an active workout
When they perform a swipe gesture on a set row
Then a delete button appears
And the delete action is clearly labeled
And tapping delete removes only that specific set
```

### Keyboard Management

**Scenario: Dismiss Keyboard When Timer Starts**
```
Given the user has entered data in a set (reps or weight)
And the keyboard is visible
When they mark the set as complete (green checkbox)
And the rest timer starts
Then the keyboard is automatically dismissed
And the timer overlay is visible
```

**Scenario: Dismiss Keyboard on Set Completion**
```
Given the user is editing a set (typing in reps or weight field)
And the keyboard is visible
When they tap the completion checkbox
Then the keyboard is immediately dismissed
And the set is marked as complete
And the rest timer starts (if rest time > 0)
```

### Exercise Selection and Filtering

**Scenario: Filter Exercises by Category in Add Exercise Sheet**
```
Given the user is in an active workout
And they tap "Add Exercise"
When the Add Exercise sheet appears
Then they see category filter buttons (Strength, Cardio, Flexibility, Other)
And they can tap a category to filter exercises
And only exercises matching that category are displayed
And the filter persists during their selection
```

**Scenario: Default Filter to Strength Exercises**
```
Given the user is adding an exercise to a workout
When the Add Exercise sheet opens
Then the exercises are filtered by "Strength" category by default
And only Strength exercises are displayed initially
And the user can change the filter if needed
```

**Scenario: Rename Exercise Templates to Exercises**
```
Given the user is viewing any screen that references "Exercise Templates"
When they see the text "Exercise Templates"
Then it should display as "Exercises" instead
And this change applies to all UI text and navigation labels
```

### Template Management

**Scenario: Multi-Select Exercises in Template Creation**
```
Given the user is creating or editing a workout template
And they tap "Add Exercise"
When the exercise selection sheet appears
Then they can select multiple exercises before confirming
And selected exercises are visually indicated (checkmark or highlight)
And they can tap "Add Selected" or "Done" to add all selected exercises at once
And all selected exercises are added to the template
```

**Scenario: Browse Templates Quick Link**
```
Given the user is on the Home/Overview screen
When they view the workout status section
Then they see a quick link button to "Browse Templates"
And tapping it navigates to the Templates tab
And they can quickly start a workout from a template
```

**Scenario: Seed Example Workout Templates**
```
Given the app is launched for the first time
Or the user has no workout templates
When the app initializes
Then example workout templates are created and saved
And templates include common workout routines (e.g., "Push Day", "Pull Day", "Leg Day")
And each template has pre-configured exercises, sets, reps, and rest times
And templates are immediately available for use
```

### Timer Enhancements

**Scenario: Minimize Rest Timer**
```
Given a rest timer is active and displayed as an overlay
When the user taps a minimize button or gesture
Then the timer is minimized to a compact indicator (e.g., small floating button or status bar)
And the timer continues counting down in the background
And the user can tap the minimized timer to restore the full overlay
And the minimized timer shows time remaining
```

**Scenario: Restore Minimized Timer**
```
Given a rest timer is minimized
And displayed as a compact indicator
When the user taps the minimized timer indicator
Then the full timer overlay is restored
And the timer display returns to normal size
And all timer controls (+15/-15, Skip) are accessible again
```

---

## Functional Requirements

### 1. Set Deletion

1.1. **Delete Set Functionality**
- Add swipe-to-delete gesture to `SetRowView` in `ActiveWorkoutView`
- Implement `deleteSet(_ set: WorkoutSet)` function in `ActiveWorkoutView`
- Remove set from `WorkoutEntry.sets` array
- Delete set from ModelContext
- Save context to persist deletion
- Update UI to reflect changes immediately

1.2. **UI Implementation**
- Use `.swipeActions(edge: .trailing)` modifier on set row
- Display red delete button with trash icon
- Confirm deletion is immediate (no confirmation dialog needed for single set)
- Handle edge case: last set in exercise (allow deletion, exercise can have 0 sets)

### 2. Keyboard Dismissal

2.1. **Dismiss on Timer Start**
- When rest timer starts, call `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)` or use `@FocusState` to dismiss keyboard
- Trigger dismissal in `ActiveWorkoutView` when `restTimerManager.startTimer()` is called
- Ensure keyboard dismisses before timer overlay appears

2.2. **Dismiss on Set Completion**
- Add keyboard dismissal to `SetRowView` completion button action
- Dismiss keyboard immediately when completion checkbox is tapped
- Use SwiftUI `@FocusState` or `UIResponder.resignFirstResponder` pattern
- Ensure dismissal happens before rest timer trigger logic

### 3. Exercise Selection Improvements

3.1. **Category Filtering in Add Exercise Sheet**
- Update `AddExerciseSheet` to include category filter buttons (similar to `ExercisesView`)
- Add `@State private var selectedCategory: String?` with default value `"Strength"`
- Display horizontal scrollable filter buttons at top of sheet
- Filter `exerciseTemplates` by `selectedCategory` when filter is active
- Show "All" option to clear filter

3.2. **Default Strength Filter**
- Set `selectedCategory` initial state to `"Strength"` in `AddExerciseSheet`
- Apply filter on sheet appearance
- Display only Strength category exercises by default
- User can change filter to view other categories

3.3. **Rename Exercise Templates**
- Find all occurrences of "Exercise Templates" text in UI
- Update to "Exercises" in:
  - `AddExerciseSheet` section header (line 387)
  - `ContentView` statistics label (line 130)
  - Any other UI labels or navigation titles
- Keep model name `ExerciseTemplate` unchanged (only UI text changes)

### 4. Template Management Enhancements

4.1. **Multi-Select Exercises in Template Creation**
- Update `AddExerciseToTemplateSheet` to support multi-select
- Add `@State private var selectedExercises: Set<UUID>` to track selections
- Display checkmark indicator for selected exercises
- Change "Add Exercise" button to "Add Selected (N)" showing count
- Update `onSelectExercise` callback to handle multiple exercises
- Add selected exercises to template in bulk

4.2. **Browse Templates Quick Link**
- Update `ContentView` to include "Browse Templates" button/link
- Place in workout status section or quick actions area
- Navigate to Templates tab by setting `selectedTab = 4`
- Use clear visual indicator (button with icon or NavigationLink style)

4.3. **Seed Example Workout Templates**
- Create `seedWorkoutTemplates(modelContext:)` function in `DataSeeder`
- Call from `ContentView.onAppear` after exercise seeding
- Create 3-5 example templates:
  - "Push Day": Bench Press, Overhead Press, Tricep Extension (3 sets each, 8 reps, 90s rest)
  - "Pull Day": Pull-up, Barbell Row, Bicep Curl (3 sets each, 8 reps, 90s rest)
  - "Leg Day": Squat, Deadlift, Lunges (3 sets each, 8 reps, 90s rest)
- Only seed if no templates exist (check count before seeding)
- Use existing ExerciseTemplates from seeded data

### 5. Timer Minimization

5.1. **Minimize Timer State**
- Add `@Published var isMinimized: Bool = false` to `RestTimerManager`
- Add `minimizeTimer()` and `restoreTimer()` methods
- Update `RestTimerView` to accept minimized state

5.2. **Minimized Timer UI**
- Create `MinimizedTimerView` component showing compact timer (e.g., circular button with time)
- Display minimized timer as floating button or status indicator
- Position at top-right or bottom of screen (non-intrusive)
- Show time remaining in MM:SS format
- Tappable to restore full overlay

5.3. **Timer Controls**
- Add minimize button to `RestTimerView` (e.g., minimize icon in top-right)
- Add restore gesture/button to minimized timer view
- Ensure timer continues counting when minimized
- Preserve all timer functionality (adjustments, skip) when restored

---

## Non-Goals

- **Set Reordering**: No drag-to-reorder sets within an exercise (future enhancement)
- **Bulk Set Operations**: No multi-select sets for bulk delete (single set deletion only)
- **Keyboard Shortcuts**: No keyboard shortcuts for set operations (touch-only)
- **Timer Notifications**: No background notifications when minimized timer completes
- **Template Import/Export**: No template sharing or export functionality
- **Custom Timer Sounds**: No audio alerts for timer (visual only, even when minimized)
- **Template Duplication**: No duplicate template functionality in this phase

---

## Success Metrics

- Users can delete sets from active workouts via swipe gesture
- Keyboard automatically dismisses when timer starts or set is completed
- Exercise filtering works in Add Exercise sheet with Strength as default
- All "Exercise Templates" text renamed to "Exercises" in UI
- Users can multi-select exercises when creating templates
- Quick link to browse templates accessible from Home screen
- Example workout templates available on first launch
- Rest timer can be minimized and restored without losing state

---

## Affected Files

### Modified Files
- `healthy_swiftdata/Views/ActiveWorkoutView.swift` - Add set deletion, keyboard dismissal, update AddExerciseSheet integration
- `healthy_swiftdata/Views/RestTimerView.swift` - Add minimize/restore functionality, minimized timer UI
- `healthy_swiftdata/Views/WorkoutTemplateEditView.swift` - Update AddExerciseToTemplateSheet for multi-select
- `healthy_swiftdata/ContentView.swift` - Add browse templates link, seed templates on first launch, rename "Exercise Templates" to "Exercises"
- `healthy_swiftdata/Utilities/DataSeeder.swift` - Add seedWorkoutTemplates function

### New Files
- None (all enhancements use existing structure)

---

## 🔍 Implementation Assumptions

### UI/UX Assumptions (MUST AUDIT)
- **Swipe Actions**: ASSUMED `.swipeActions(edge: .trailing)` works on SetRowView in List context (CERTAIN - standard SwiftUI pattern)
- **Keyboard Dismissal**: ASSUMED `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)` works in SwiftUI or `@FocusState` can be used (CERTAIN - standard iOS pattern)
- **Category Filtering**: ASSUMED AddExerciseSheet can reuse filter pattern from ExercisesView (LIKELY - similar List structure)
- **Multi-Select UI**: ASSUMED Set<UUID> with checkmark indicators works for multi-select (CERTAIN - standard selection pattern)
- **Minimized Timer**: ASSUMED floating overlay or status indicator can be implemented with ZStack (CERTAIN - standard SwiftUI overlay pattern)

### Data Model Assumptions (MUST AUDIT)
- **Set Deletion**: ASSUMED deleting WorkoutSet from ModelContext and removing from WorkoutEntry.sets array works (CERTAIN - verified cascade delete pattern exists)
- **Template Seeding**: ASSUMED we can create WorkoutTemplate and TemplateExercise objects similar to ExerciseTemplate seeding (CERTAIN - same SwiftData pattern)

### State Management Assumptions (MUST AUDIT)
- **Timer Minimized State**: ASSUMED @Published var in RestTimerManager will update UI when changed (CERTAIN - ObservableObject pattern verified)
- **Default Filter State**: ASSUMED @State with initial value "Strength" will apply filter on view appearance (CERTAIN - standard @State behavior)

---

## Git Strategy

**Branch**: `feature/workout-enhancements-ux`

**Commit Strategy**: Phased commits with descriptive messages

1. **Phase 1**: Set Deletion
   - Commit: `feat: add swipe-to-delete for sets in active workout`

2. **Phase 2**: Keyboard Dismissal
   - Commit: `feat: dismiss keyboard on timer start and set completion`

3. **Phase 3**: Exercise Filtering and Renaming
   - Commit: `feat: add category filtering to Add Exercise sheet with Strength default`
   - Commit: `refactor: rename "Exercise Templates" to "Exercises" in UI`

4. **Phase 4**: Template Multi-Select
   - Commit: `feat: add multi-select exercises in template creation`

5. **Phase 5**: Template Seeding and Quick Link
   - Commit: `feat: seed example workout templates on first launch`
   - Commit: `feat: add browse templates quick link to home screen`

6. **Phase 6**: Timer Minimization
   - Commit: `feat: add minimize/restore functionality to rest timer`

---

## QA Strategy

### LLM Self-Test Scenarios

**Set Deletion**
- Swipe left on a set in active workout
- Verify delete button appears
- Verify set is deleted and removed from UI
- Verify last set in exercise can be deleted

**Keyboard Dismissal**
- Open keyboard by tapping reps field
- Mark set as complete
- Verify keyboard dismisses immediately
- Verify timer starts after keyboard dismissal

**Exercise Filtering**
- Open Add Exercise sheet
- Verify Strength exercises shown by default
- Change filter to Cardio
- Verify only Cardio exercises displayed
- Select "All" filter
- Verify all exercises displayed

**Template Multi-Select**
- Start creating new template
- Tap Add Exercise
- Select multiple exercises
- Verify checkmarks appear
- Tap "Add Selected"
- Verify all selected exercises added to template

**Timer Minimization**
- Start rest timer
- Tap minimize button
- Verify timer minimizes to compact view
- Verify timer continues counting
- Tap minimized timer
- Verify full overlay restores

### Manual User Verification

- Test full workflow: Delete set → Add exercise with filtering → Complete set with keyboard → Minimize timer
- Verify example templates appear on fresh app install
- Test quick link navigation from Home to Templates
- Verify all "Exercise Templates" text changed to "Exercises"

---

## Technical Architecture Details

### Keyboard Dismissal Implementation

**Option 1: UIResponder Pattern**
```swift
UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
```

**Option 2: @FocusState Pattern**
```swift
@FocusState private var isTextFieldFocused: Bool
// Then set isTextFieldFocused = false to dismiss
```

**Recommendation**: Use UIResponder pattern for simplicity, as it works globally and doesn't require tracking focus state.

### Multi-Select Implementation

Store selected exercise IDs in `Set<UUID>`:
- Display checkmark when exercise ID is in set
- Toggle selection on tap
- Show count in "Add Selected (N)" button
- Pass all selected ExerciseTemplates to callback

### Timer Minimization UI

**Minimized State**:
- Small circular button with time (e.g., "1:30")
- Positioned as floating overlay
- Tap to restore full view
- Timer continues counting in background

**Full State**:
- Existing RestTimerView overlay
- Minimize button in top-right corner
- Tap to minimize

---

## Future Enhancements (Out of Scope)

- Drag-to-reorder sets within exercise
- Bulk delete multiple sets
- Timer customization (colors, sizes)
- Keyboard shortcuts for power users
- Template categories/tags
- Timer sound alerts
- Export/import templates

---

## Current State Audit Results

### UI Pattern Verification

- ✅ **Swipe Actions Pattern**: VERIFIED - `healthy_swiftdata/Views/WorkoutTemplatesView.swift:278` - `.swipeActions(edge: .trailing, allowsFullSwipe: false)` pattern exists, can be applied to SetRowView
- ✅ **Category Filtering Pattern**: VERIFIED - `healthy_swiftdata/Views/ExercisesView.swift:54-82` - Category filter buttons with ScrollView pattern exists, can be reused in AddExerciseSheet
- ✅ **ModelContext Delete Pattern**: VERIFIED - `healthy_swiftdata/Views/WorkoutTemplatesView.swift:125` - `modelContext.delete()` and `try? modelContext.save()` pattern exists
- ✅ **RestTimerManager Structure**: VERIFIED - `healthy_swiftdata/Views/RestTimerView.swift:13-61` - `@Published` properties exist, can add `isMinimized` property
- ✅ **DataSeeder Pattern**: VERIFIED - `healthy_swiftdata/Utilities/DataSeeder.swift:12-129` - Seeding pattern with count check exists, can add `seedWorkoutTemplates`

### View Structure Verification

- ✅ **SetRowView Structure**: VERIFIED - `healthy_swiftdata/Views/ActiveWorkoutView.swift:292-357` - SetRowView exists in ForEach within List, can add swipeActions modifier
- ✅ **AddExerciseSheet Structure**: VERIFIED - `healthy_swiftdata/Views/ActiveWorkoutView.swift:361-430` - AddExerciseSheet has List structure, can add category filter section similar to ExercisesView
- ✅ **AddExerciseToTemplateSheet Structure**: VERIFIED - `healthy_swiftdata/Views/WorkoutTemplateEditView.swift:270-325` - Sheet exists with ForEach, can add multi-select state and checkmarks
- ✅ **ContentView Structure**: VERIFIED - `healthy_swiftdata/ContentView.swift:11-237` - ContentView has workout status section, can add browse templates link
- ✅ **RestTimerOverlay Structure**: VERIFIED - `healthy_swiftdata/Views/RestTimerView.swift:158-189` - ViewModifier pattern exists, can extend for minimized state

### Text/Label Verification

- ✅ **"Exercise Templates" Text Locations**: VERIFIED - `healthy_swiftdata/Views/ActiveWorkoutView.swift:387` (Section header) and `healthy_swiftdata/ContentView.swift:130` (Statistics label) - Both need rename to "Exercises"
- ✅ **ExerciseTemplate Model Name**: VERIFIED - Model name `ExerciseTemplate` is used in code, only UI text needs to change (no model rename needed)

### Gap Analysis

**Missing Components:**
- Set deletion function in ActiveWorkoutView (needs ADD)
- Keyboard dismissal logic (needs ADD - no existing pattern found)
- Category filtering in AddExerciseSheet (needs MODIFY - add filter state and UI)
- Default Strength filter (needs MODIFY - change initial state)
- Multi-select state in AddExerciseToTemplateSheet (needs MODIFY - add Set<UUID> and checkmarks)
- Template seeding function (needs ADD to DataSeeder)
- Browse templates link (needs ADD to ContentView)
- Timer minimization state and UI (needs MODIFY - add isMinimized to RestTimerManager, create MinimizedTimerView)

**Current Logic:**
- All existing patterns (swipeActions, filtering, seeding, ModelContext operations) match requirements
- No conflicts found with proposed changes
- SetRowView is already in ForEach within List, perfect for swipeActions
- ExercisesView category filtering pattern can be directly reused

---

## Executable Implementation Plan

**Status**: ✅ COMPLETED  
**Review Date**: 2025-12-24  
**Completion Date**: 2025-12-24  
**Completeness Score**: 10/10 (all phases implemented and committed)

### Phase Rules

- **Maximum 3 tasks per phase** (excluding validation and commit)
- Each phase must have a validation gate before proceeding
- All changes must be committed before moving to next phase
- Use descriptive commit messages following pattern: `feat:`, `fix:`, `refactor:`

### Production Safety Checklist

- [ ] No mock data or placeholder values
- [ ] All SwiftData models properly initialized with required fields
- [ ] Keyboard dismissal works reliably
- [ ] Set deletion properly removes from arrays and ModelContext
- [ ] Template seeding only runs when templates don't exist
- [ ] Timer minimization preserves countdown state
- [ ] All user actions persist to SwiftData immediately

---

## Tasks

### Phase 1 (1.0) - Set Deletion ✅ [COMPLETED]

- [x] 1.0 `git commit -m "feat: add swipe-to-delete for sets in active workout"` (commit: 8c44fdd)
- [x] 1.1 Add `deleteSet(_ set: WorkoutSet)` function to ActiveWorkoutView that removes set from WorkoutEntry.sets array, calls modelContext.delete(set), and saves context
- [x] 1.2 Update SetRowView to add `.swipeActions(edge: .trailing)` modifier with delete button (reuse pattern from WorkoutTemplatesView:278)
- [x] 1.3 Pass delete callback from ActiveWorkoutView to SetRowView via new `onDeleteSet: (WorkoutSet) -> Void` parameter
- [x] 1.4 Build validation: Verify swipe-to-delete works, verify set is removed from UI and SwiftData, verify last set can be deleted (linter: no errors)
- [x] 1.5 User confirmation checkpoint - Set deletion working

### Phase 2 (2.0) - Keyboard Dismissal ✅ [COMPLETED]

- [x] 2.0 `git commit -m "feat: dismiss keyboard on timer start and set completion"` (commit: 96e4e61)
- [x] 2.1 Add keyboard dismissal helper function using `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)`
- [x] 2.2 Update ActiveWorkoutView to dismiss keyboard when calling `restTimerManager.startTimer()` via onSetComplete callback
- [x] 2.3 Update SetRowView completion button action to dismiss keyboard before marking set complete and triggering timer
- [x] 2.4 Build validation: Verify keyboard dismisses when set is completed, verify keyboard dismisses when timer starts (linter: no errors)
- [x] 2.5 User confirmation checkpoint - Keyboard dismissal working

### Phase 3 (3.0) - Exercise Filtering and Renaming ✅ [COMPLETED]

- [x] 3.0 `git commit -m "feat: add category filtering to Add Exercise sheet with Strength default and rename Exercise Templates to Exercises"` (commit: f6b6fe4)
- [x] 3.1 Update AddExerciseSheet to add `@State private var selectedCategory: String? = "Strength"` and category filter buttons section (reuse pattern from ExercisesView)
- [x] 3.2 Update filteredTemplates computed property to filter by selectedCategory when not nil, combine with search text filter
- [x] 3.3 Update Section header in AddExerciseSheet from "Exercise Templates" to "Exercises"
- [x] 3.4 Update statistics label in ContentView from "Exercise Templates" to "Exercises"
- [x] 3.5 Build validation: Verify Strength filter applied by default, verify category filtering works, verify "Exercise Templates" renamed to "Exercises" (linter: no errors)
- [x] 3.6 User confirmation checkpoint - Exercise filtering and renaming working

### Phase 4 (4.0) - Template Multi-Select ✅ [COMPLETED]

- [x] 4.0 `git commit -m "feat: add multi-select exercises in template creation"` (commit: aaa947e)
- [x] 4.1 Update AddExerciseToTemplateSheet to add `@State private var selectedExercises: Set<UUID> = []` for multi-select state
- [x] 4.2 Update exercise list to show checkmark indicator for selected exercises, toggle selection on tap instead of immediate add
- [x] 4.3 Change button to show "Add Selected (N)" with count, update callback signature to `onSelectExercises: ([ExerciseTemplate]) -> Void`
- [x] 4.4 Update WorkoutTemplateEditView to add `addExercisesToTemplate(exerciseTemplates:)` function and update sheet callback
- [x] 4.5 Build validation: Verify multi-select works, verify checkmarks appear, verify all selected exercises added to template (linter: no errors)
- [x] 4.6 User confirmation checkpoint - Multi-select working

### Phase 5 (5.0) - Template Seeding and Quick Link ✅ [COMPLETED]

- [x] 5.0 `git commit -m "feat: seed example workout templates on first launch and add browse templates quick link"` (commit: 7bbae91)
- [x] 5.1 Add `seedWorkoutTemplates(modelContext:)` function to DataSeeder (similar pattern to seedExerciseTemplates)
- [x] 5.2 Create 3 example templates: "Push Day" (Bench Press, Overhead Press, Tricep Extension), "Pull Day" (Pull-up, Barbell Row, Bicep Curl), "Leg Day" (Squat, Deadlift, Lunges) - each with 3 sets, 8 reps, 90s rest
- [x] 5.3 Update ContentView.onAppear to call `DataSeeder.seedWorkoutTemplates(modelContext: modelContext)` after exercise seeding
- [x] 5.4 Update ContentView to add "Browse Templates" button/link in Quick Links section, set selectedTab = 4 on tap
- [x] 5.5 Build validation: Verify templates seed on first launch, verify quick link navigates to Templates tab (linter: no errors)
- [x] 5.6 User confirmation checkpoint - Template seeding and quick link working

### Phase 6 (6.0) - Timer Minimization ✅ [COMPLETED]

- [x] 6.0 `git commit -m "feat: add minimize/restore functionality to rest timer"` (commit: d053173)
- [x] 6.1 Update RestTimerManager to add `@Published var isMinimized: Bool = false` and `minimizeTimer()` / `restoreTimer()` methods
- [x] 6.2 Create MinimizedTimerView component showing compact timer with exercise name and time in MM:SS format
- [x] 6.3 Update RestTimerView to add minimize button in top-right corner of header
- [x] 6.4 Update ActiveWorkoutView overlay to show MinimizedTimerView when isMinimized is true, full RestTimerView when false
- [x] 6.5 Ensure timer continues counting when minimized (timer persists in RestTimerManager), preserve state when restored
- [x] 6.6 Build validation: Verify timer can be minimized, verify countdown continues, verify timer can be restored (linter: no errors)
- [x] 6.7 User confirmation checkpoint - Timer minimization working

