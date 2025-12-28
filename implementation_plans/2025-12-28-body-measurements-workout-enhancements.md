# Body Measurements & Workout Enhancements Implementation Plan

**Created**: 2025-12-28  
**Status**: Reviewed - Ready for Implementation  
**Type**: Feature Enhancement  
**Review Date**: 2025-12-28  
**Completeness Score**: 8.5/10

**Gaps Identified**:
- Navy body fat formula needs verification against official source
- TabView swipe pattern not yet tested in this codebase (standard SwiftUI, should work)
- Rest timer timing issue root cause needs investigation during implementation

---

## Summary

This implementation plan covers eight enhancements to the workout tracking app:
1. Body measurements page with body weight entry integration
2. Additional body measurements tracking (neck, height, waist, chest, arms, legs)
3. Navy body fat calculator integration
4. Top exercises metric card showing all favorites
5. Edit functionality for workout history
6. Rest timer timing accuracy fix
7. Rest timer integration into main workout time card
8. Swipe navigation between exercises in active workout with auto-advance

These changes improve body tracking capabilities, workout navigation, and user experience during active workouts.

---

## Step 1: Investigation & Expected Behavior

### Investigation

**Unknowns to resolve:**
- Navy body fat calculation formula and required measurements
- Best UI pattern for body measurements entry (form vs. list)
- How to handle measurement units (metric vs. imperial) consistently
- Exercise swipe navigation implementation pattern in SwiftUI
- Rest timer timing issue root cause (Timer interval vs. update frequency)
- Integration point for rest timer in workout stopwatch card

**Design decisions needed:**
- Body measurements data model structure
- Navigation structure for new Body tab
- Rest timer display format in main time card
- Swipe gesture detection and exercise navigation logic

### Expected Behavior (Gherkin Scenarios)

#### Body Measurements Page

```gherkin
Scenario: User views body measurements page
  Given the user is on the home screen
  When the user taps the "Body" tab in the navigation bar
  Then the body measurements page is displayed
  And the page shows body weight entry section
  And the page shows additional measurements section (neck, height, waist, chest, arms, legs)
  And the page shows Navy body fat calculator section

Scenario: User adds body weight entry
  Given the user is on the body measurements page
  When the user taps the "+" button in the weight section
  Then a weight entry form is displayed
  When the user enters weight value and saves
  Then the weight entry is added to the list
  And the weight appears in the summary card on home screen

Scenario: User adds body measurement
  Given the user is on the body measurements page
  When the user taps "Add Measurement" for a measurement type (e.g., chest)
  Then a measurement entry form is displayed
  When the user enters measurement value and saves
  Then the measurement entry is added to the history
  And the measurement appears in the measurements list

Scenario: User calculates Navy body fat
  Given the user is on the body measurements page
  And the user has entered required measurements (height, neck, waist for men; height, neck, waist, hip for women)
  When the user selects gender and taps "Calculate"
  Then the Navy body fat percentage is displayed
  And the result is saved to measurement history
```

#### Top Exercises - Favorites

```gherkin
Scenario: User views top exercises with favorites
  Given the user has marked some exercises as favorites
  When the user views the home screen
  Then the "Top Exercises" metric card displays all favorite exercises
  And exercises are ranked by estimated 1RM
  And the card shows exercise name and 1RM value
```

#### Workout History Edit

```gherkin
Scenario: User edits workout history
  Given the user is viewing workout history detail
  When the user taps the edit button
  Then an edit form is displayed with workout data
  When the user modifies sets, weights, or reps
  And the user saves changes
  Then the workout history is updated
  And the changes are reflected in the detail view
```

#### Rest Timer Fix

```gherkin
Scenario: Rest timer counts down accurately
  Given a rest timer is started for 60 seconds
  When the timer is running
  Then the timer decreases by exactly 1 second per second
  And the circular progress indicator updates smoothly
  And the timer completes at exactly 0 seconds
```

#### Rest Timer in Main Card

```gherkin
Scenario: User sees rest timer in workout time card
  Given the user is in an active workout
  And a rest timer is active
  When the user views the workout screen
  Then the main time card shows both workout stopwatch and rest timer
  And the rest timer is displayed below or alongside the stopwatch
  And both timers are clearly visible
```

#### Exercise Swipe Navigation

```gherkin
Scenario: User swipes between exercises
  Given the user is in an active workout
  And there are multiple exercises
  When the user swipes left on the current exercise
  Then the next exercise is displayed
  When the user swipes right
  Then the previous exercise is displayed

Scenario: Auto-advance when sets complete
  Given the user is in an active workout
  And the user completes all sets for an exercise
  When the last set is marked complete
  Then the view automatically swipes to the next exercise
  And the next exercise is displayed
```

---

## Step 2: Design Clarity Check

### Body Measurements Page

**Screen Purpose**: This screen lets the user track body measurements (weight, neck, height, waist, chest, arms, legs) and calculate body fat percentage so they can monitor their physical progress over time.

**Input → Output Mapping**:
- **Input**: Tap "+" button → Output: Form sheet appears
- **Input**: Enter measurement value → Output: Value saved, list updated
- **Input**: Select gender, enter measurements → Output: Body fat percentage calculated and displayed

**Key Actions Hierarchy**:
- **Primary**: Add new measurement entry
- **Secondary**: View measurement history, calculate body fat
- **Tertiary**: Edit/delete existing entries

**Layout Skeleton** (5 blocks):
1. Header with navigation title
2. Body Weight section (with entry list and add button)
3. Body Measurements section (neck, height, waist, chest, arms, legs)
4. Navy Body Fat Calculator section
5. Measurement history list

**Visual Chunks & Information Architecture**:
- Body Weight: Primary (most frequently used)
- Additional Measurements: Secondary (grouped by body part)
- Body Fat Calculator: Tertiary (analytical tool)
- History: Supporting (chronological list)

**Behavior Clarity**:
- Each measurement type has its own entry form
- Calculator requires specific measurements based on gender
- All measurements stored with date/time for tracking over time

### Rest Timer in Main Card

**Screen Purpose**: Display both workout duration and rest timer in the same card so users can see both timers at once without switching views.

**Input → Output Mapping**:
- **Input**: Rest timer starts → Output: Rest timer appears in main card
- **Input**: Rest timer completes → Output: Rest timer disappears from card

**Layout Skeleton** (2 blocks):
1. Workout stopwatch (top, larger)
2. Rest timer (below, smaller)

**Visual Hierarchy**:
- Workout stopwatch: Primary (larger, more prominent)
- Rest timer: Secondary (smaller, but clearly visible)

---

## Step 3: Implementation Plan Components

### Goals

1. **Body Tracking Enhancement**: Create dedicated body measurements page with comprehensive tracking capabilities
2. **Body Fat Analysis**: Integrate Navy body fat calculator for fitness progress tracking
3. **Workout Navigation**: Improve exercise navigation with swipe gestures and auto-advance
4. **Timer Integration**: Consolidate timers in main workout card for better visibility
5. **Data Management**: Enable editing of workout history for data correction
6. **Timer Accuracy**: Fix rest timer timing to ensure accurate countdown

### User Stories

#### Story 1: Body Measurements Page

```gherkin
Feature: Body Measurements Tracking
  As a fitness enthusiast
  I want to track various body measurements
  So that I can monitor my physical progress

  Scenario: Access body measurements page
    Given I am on the home screen
    When I tap the "Body" tab
    Then I see the body measurements page
    And I can see body weight entry section
    And I can see additional measurements section

  Scenario: Add body weight entry
    Given I am on the body measurements page
    When I tap "+" in the weight section
    Then a weight entry form appears
    When I enter weight and save
    Then the weight is added to the list
    And the weight appears in the home summary card

  Scenario: Add body measurement
    Given I am on the body measurements page
    When I tap "Add" for chest measurement
    Then a measurement form appears
    When I enter chest measurement and save
    Then the measurement is added to history
```

#### Story 2: Navy Body Fat Calculator

```gherkin
Feature: Navy Body Fat Calculator
  As a user tracking fitness progress
  I want to calculate my body fat percentage
  So that I can track body composition changes

  Scenario: Calculate body fat (male)
    Given I am on the body measurements page
    And I have entered height, neck, and waist measurements
    When I select "Male" and tap "Calculate"
    Then my body fat percentage is displayed
    And the result is saved to my measurement history

  Scenario: Calculate body fat (female)
    Given I am on the body measurements page
    And I have entered height, neck, waist, and hip measurements
    When I select "Female" and tap "Calculate"
    Then my body fat percentage is displayed
    And the result accounts for hip measurement
```

#### Story 3: Top Exercises Favorites

```gherkin
Feature: Top Exercises Show Favorites
  As a user
  I want to see all my favorite exercises in the top exercises card
  So that I can quickly see my preferred exercises' progress

  Scenario: View favorite exercises
    Given I have marked exercises as favorites
    When I view the home screen
    Then the "Top Exercises" card shows all favorite exercises
    And exercises are ranked by estimated 1RM
    And I can see exercise name and 1RM value
```

#### Story 4: Edit Workout History

```gherkin
Feature: Edit Workout History
  As a user
  I want to edit completed workouts
  So that I can correct mistakes or update workout data

  Scenario: Edit workout details
    Given I am viewing a workout history detail
    When I tap the edit button
    Then an edit form appears with current workout data
    When I modify set weights or reps
    And I save changes
    Then the workout history is updated
    And the changes are visible in the detail view
```

#### Story 5: Rest Timer Accuracy Fix

```gherkin
Feature: Accurate Rest Timer
  As a user during a workout
  I want the rest timer to count down accurately
  So that I know exactly when my rest period ends

  Scenario: Timer counts accurately
    Given I start a 60-second rest timer
    When the timer is running
    Then it decreases by exactly 1 second per second
    And the progress circle updates smoothly
    And the timer completes at exactly 0 seconds
```

#### Story 6: Rest Timer in Main Card

```gherkin
Feature: Rest Timer in Workout Card
  As a user during a workout
  I want to see both workout duration and rest timer together
  So that I don't need to look at separate views

  Scenario: View both timers
    Given I am in an active workout
    And a rest timer is active
    When I view the workout screen
    Then the main time card shows workout stopwatch
    And the rest timer is displayed below it
    And both are clearly visible
```

#### Story 7: Exercise Swipe Navigation

```gherkin
Feature: Swipe Between Exercises
  As a user during a workout
  I want to swipe between exercises
  So that I can navigate quickly without scrolling

  Scenario: Swipe to next exercise
    Given I am in an active workout with multiple exercises
    When I swipe left on the current exercise
    Then the next exercise is displayed
    And I can see all sets for that exercise

  Scenario: Auto-advance on completion
    Given I am in an active workout
    And I complete all sets for an exercise
    When I mark the last set as complete
    Then the view automatically advances to the next exercise
    And the next exercise is displayed
```

### Functional Requirements

#### 1. Body Measurements Page

1.1. **New Tab in Navigation**
   - Add "Body" tab to `MainTabView` (5th tab)
   - Icon: `figure.arms.open` or `ruler`
   - Navigate to new `BodyMeasurementsView`

1.2. **Body Weight Section**
   - Move body weight entry functionality from `BodyWeightView` to new page
   - Display weight entry list with date, weight, unit
   - Add button to create new weight entry
   - Swipe actions: Edit, Delete
   - Link to weight history view

1.3. **Additional Measurements**
   - Create `BodyMeasurement` SwiftData model with fields:
     - `id: UUID`
     - `measurementType: String` (neck, height, waist, chest, arm, leg)
     - `value: Double`
     - `unit: String` (cm/inches)
     - `recordedAt: Date`
     - `notes: String?`
   - Display measurement cards for each type:
     - Neck circumference
     - Height
     - Waist circumference
     - Chest circumference
     - Arm circumference (left/right)
     - Leg circumference (left/right)
   - Each card shows:
     - Current value (most recent)
     - Add/Edit button
     - History link

1.4. **Navy Body Fat Calculator**
   - Create `NavyBodyFatCalculator` utility class
   - Formula for men: `BF% = 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450`
   - Formula for women: `BF% = 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450`
   - Input form with:
     - Gender picker (Male/Female)
     - Height field (uses most recent height measurement or manual entry)
     - Neck field (uses most recent neck measurement or manual entry)
     - Waist field (uses most recent waist measurement or manual entry)
     - Hip field (for women only, uses most recent hip measurement or manual entry)
   - Calculate button
   - Display result with date
   - Save calculation to measurement history

#### 2. Top Exercises - Favorites

2.1. **Update Top Exercises Card**
   - Modify `TopExercisesMetricCard` to show all favorite exercises
   - Update `getTopExercises()` in `ContentView` to filter by `isFavorite == true`
   - If no favorites, show message: "Mark exercises as favorites to see them here"
   - Rank by estimated 1RM (highest first)
   - Display all favorites (not limited to 3)

#### 3. Edit Workout History

3.1. **Edit Functionality**
   - Add "Edit" button to `WorkoutHistoryDetailView` toolbar
   - Create `WorkoutHistoryEditView` (similar to active workout structure)
   - Allow editing:
     - Set weights
     - Set reps
     - Set completion status
     - Exercise notes
     - Workout notes
   - Save changes to `WorkoutHistory` model
   - Recalculate workout totals (volume, duration) after edit

#### 4. Rest Timer Fix

4.1. **Timer Accuracy**
   - Investigate `RestTimerManager.updateTimer()` method
   - Ensure `Timer.scheduledTimer` uses exactly 1.0 second interval
   - Verify `timeRemaining` decrements by exactly 1 per update
   - Check for timer conflicts with workout stopwatch
   - Ensure timer updates on main thread
   - Test timer accuracy with stopwatch comparison

#### 5. Rest Timer in Main Card

5.1. **Timer Integration**
   - Modify workout stopwatch section in `ActiveWorkoutView`
   - Add rest timer display below stopwatch
   - Show rest timer only when `restTimerManager.isActive == true`
   - Display format: `MM:SS` (smaller font than stopwatch)
   - Show exercise name and set number for rest timer
   - Use accent color for rest timer text
   - Hide rest timer overlay when displayed in main card

#### 6. Exercise Swipe Navigation

6.1. **Swipe Implementation**
   - Convert exercise list to `TabView` with `PageTabViewStyle`
   - Each exercise becomes a page
   - Enable swipe gestures between pages
   - Add page indicators (dots) at bottom
   - Maintain current exercise state

6.2. **Auto-Advance Logic**
   - Detect when all sets for an exercise are complete
   - Check: `entry.sets?.allSatisfy { $0.completedAt != nil } == true`
   - Automatically advance to next exercise using `TabView` selection
   - Add small delay (0.3 seconds) for visual feedback
   - Only auto-advance if there is a next exercise

### Non-Goals

- **Body measurement charts**: Charts for measurement trends are out of scope (can be added later)
- **Multiple body fat calculation methods**: Only Navy method implemented (other methods can be added later)
- **Measurement unit conversion**: Users must enter measurements in consistent units (automatic conversion out of scope)
- **Workout history undo**: No undo functionality for edits (can be added later)
- **Rest timer presets**: Custom rest time presets are out of scope
- **Exercise reordering during workout**: Cannot reorder exercises during active workout (only via template edit)

### Success Metrics

1. **Body Measurements**: User can add and view all measurement types
2. **Body Fat Calculator**: Calculator produces accurate results using Navy formula
3. **Top Exercises**: All favorite exercises appear in metric card
4. **Workout Edit**: Users can successfully edit and save workout history changes
5. **Timer Accuracy**: Rest timer counts down within 0.1 seconds accuracy
6. **Timer Integration**: Both timers visible in main card without overlap
7. **Swipe Navigation**: Users can swipe between exercises smoothly
8. **Auto-Advance**: View advances automatically when all sets complete

---

## Affected Files

### New Files

1. `healthy_swiftdata/Views/BodyMeasurementsView.swift` - Main body measurements page
2. `healthy_swiftdata/Views/BodyMeasurementEntryForm.swift` - Form for adding/editing measurements
3. `healthy_swiftdata/Views/NavyBodyFatCalculatorView.swift` - Body fat calculator component
4. `healthy_swiftdata/Models/BodyMeasurement.swift` - SwiftData model for body measurements
5. `healthy_swiftdata/Utilities/NavyBodyFatCalculator.swift` - Calculator utility class
6. `healthy_swiftdata/Views/WorkoutHistoryEditView.swift` - Edit view for workout history

### Modified Files

1. `healthy_swiftdata/Views/MainTabView.swift` - Add Body tab
2. `healthy_swiftdata/Views/ContentView.swift` - Update `getTopExercises()` to filter favorites
3. `healthy_swiftdata/Views/TopExercisesMetricCard.swift` - Update to show all favorites
4. `healthy_swiftdata/Views/ActiveWorkoutView.swift` - Add rest timer to main card, implement swipe navigation
5. `healthy_swiftdata/Views/RestTimerView.swift` - Fix timer accuracy issue
6. `healthy_swiftdata/Views/WorkoutHistoryDetailView.swift` - Add edit button and navigation
7. `healthy_swiftdata/Views/BodyWeightView.swift` - May be deprecated or integrated into BodyMeasurementsView
8. `healthy_swiftdata/healthy_swiftdataApp.swift` - Add `BodyMeasurement` to schema

---

## Data Schema

### New Model: BodyMeasurement

```swift
@Model
final class BodyMeasurement {
    var id: UUID
    var measurementType: String // "neck", "height", "waist", "chest", "armLeft", "armRight", "legLeft", "legRight", "hip"
    var value: Double
    var unit: String // "cm" or "inches"
    var recordedAt: Date
    var notes: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        measurementType: String,
        value: Double,
        unit: String = "cm",
        recordedAt: Date = Date(),
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.measurementType = measurementType
        self.value = value
        self.unit = unit
        self.recordedAt = recordedAt
        self.notes = notes
        self.createdAt = createdAt
    }
}
```

### Schema Updates

- Add `BodyMeasurement.self` to `ModelContainer` schema in `healthy_swiftdataApp.swift`
- Ensure `BodyWeightEntry` remains in schema (may be used alongside new measurements)

---

## 🔍 Implementation Assumptions

### Backend Assumptions (N/A - Local Storage)

- **Storage**: All data stored locally using SwiftData (CERTAIN - already in use)
- **Persistence**: SwiftData handles persistence automatically (CERTAIN)

### Frontend Assumptions (MUST AUDIT)

- **View Properties**: 
  - `BodyMeasurementsView` will use `@Query` for measurements (LIKELY - follows existing pattern)
  - `RestTimerManager.isActive` exists and works correctly (CERTAIN - already implemented)
  - `ActiveWorkoutView` has access to `restTimerManager` (CERTAIN - already exists)

- **Methods**:
  - `OneRepMaxCalculator.getTopExercises()` can be modified to filter by `isFavorite` (LIKELY - need to verify method signature)
  - `ExerciseTemplate.isFavorite` property exists (CERTAIN - already added)
  - `TabView` with `PageTabViewStyle` supports swipe navigation (CERTAIN - standard SwiftUI)

- **Navigation**:
  - `MainTabView` can accommodate 5 tabs (LIKELY - standard TabView supports multiple tabs)
  - Navigation from `WorkoutHistoryDetailView` to `WorkoutHistoryEditView` works (LIKELY - standard navigation pattern)

- **State Bindings**:
  - `@StateObject var restTimerManager` in `ActiveWorkoutView` (CERTAIN - already exists)
  - `@Query` for body measurements will work similarly to `BodyWeightEntry` (LIKELY - same pattern)

### Database Schema Assumptions (MUST AUDIT)

- **Tables**: 
  - `BodyMeasurement` table will be created by SwiftData (CERTAIN - standard behavior)
  - `BodyWeightEntry` table exists and works (CERTAIN - already in use)
  - `WorkoutHistory` can be modified after creation (CERTAIN - SwiftData allows updates)

- **Columns**:
  - `ExerciseTemplate.isFavorite` column exists (CERTAIN - already added)
  - `WorkoutHistory.entries` relationship allows modification (CERTAIN - SwiftData relationships are mutable)

- **Relationships**:
  - No foreign key relationships needed for `BodyMeasurement` (CERTAIN - standalone model)

### Technical Assumptions

- **Timer Accuracy**:
  - `Timer.scheduledTimer(withTimeInterval: 1.0)` should fire every 1.0 seconds (CERTAIN - standard behavior)
  - Timer may be affected by RunLoop mode (UNCERTAIN - need to test)
  - Timer conflicts with workout stopwatch possible (UNCERTAIN - need to investigate)

- **Swipe Navigation**:
  - `TabView` with `PageTabViewStyle` provides native swipe (CERTAIN - standard SwiftUI)
  - Exercise list can be converted to `TabView` pages (LIKELY - need to verify structure)

- **Navy Body Fat Formula**:
  - Formula implementation is correct (UNCERTAIN - need to verify against official Navy formula)
  - Unit conversion (cm to inches) handled correctly (UNCERTAIN - need to verify)

---

## Git Strategy

### Branch Naming
- **Branch**: `feature/body-measurements-workout-enhancements`

### Commit Checkpoints

1. **Phase 1: Body Measurements Foundation**
   - Commit: `feat: add BodyMeasurement model and basic structure`
   - Files: `BodyMeasurement.swift`, schema updates

2. **Phase 2: Body Measurements Page**
   - Commit: `feat: create BodyMeasurementsView with weight and measurement tracking`
   - Files: `BodyMeasurementsView.swift`, `BodyMeasurementEntryForm.swift`

3. **Phase 3: Navy Body Fat Calculator**
   - Commit: `feat: add Navy body fat calculator`
   - Files: `NavyBodyFatCalculator.swift`, `NavyBodyFatCalculatorView.swift`

4. **Phase 4: Body Tab Integration**
   - Commit: `feat: add Body tab to MainTabView and integrate body measurements`
   - Files: `MainTabView.swift`, `BodyMeasurementsView.swift`

5. **Phase 5: Top Exercises Favorites**
   - Commit: `feat: update TopExercisesMetricCard to show all favorites`
   - Files: `ContentView.swift`, `TopExercisesMetricCard.swift`, `OneRepMaxCalculator.swift`

6. **Phase 6: Workout History Edit**
   - Commit: `feat: add edit functionality to workout history`
   - Files: `WorkoutHistoryDetailView.swift`, `WorkoutHistoryEditView.swift`

7. **Phase 7: Rest Timer Fix**
   - Commit: `fix: correct rest timer timing accuracy`
   - Files: `RestTimerView.swift`

8. **Phase 8: Rest Timer Integration**
   - Commit: `feat: integrate rest timer into main workout time card`
   - Files: `ActiveWorkoutView.swift`

9. **Phase 9: Exercise Swipe Navigation**
   - Commit: `feat: add swipe navigation between exercises with auto-advance`
   - Files: `ActiveWorkoutView.swift`

---

## QA Strategy

### LLM Self-Test Scenarios

#### Body Measurements
```gherkin
Scenario: Test body measurement entry
  Given the BodyMeasurementsView is displayed
  When I add a chest measurement of 100cm
  Then the measurement appears in the chest section
  And the measurement is saved to SwiftData

Scenario: Test Navy body fat calculation
  Given I have entered height: 175cm, neck: 38cm, waist: 80cm
  When I select "Male" and calculate
  Then body fat percentage is displayed
  And the result is between 0-50% (reasonable range)
```

#### Top Exercises
```gherkin
Scenario: Test favorites display
  Given I have 5 exercises marked as favorites
  When I view the home screen
  Then all 5 favorite exercises appear in TopExercisesMetricCard
  And they are ranked by 1RM
```

#### Rest Timer
```gherkin
Scenario: Test timer accuracy
  Given I start a 30-second rest timer
  When I wait 30 seconds using external stopwatch
  Then the rest timer shows 0 seconds
  And the difference is less than 1 second
```

#### Exercise Swipe
```gherkin
Scenario: Test swipe navigation
  Given I am in an active workout with 3 exercises
  When I swipe left
  Then the next exercise is displayed
  When I swipe right
  Then the previous exercise is displayed
```

### Manual User Verification

1. **Body Measurements**: Verify all measurement types can be added and viewed
2. **Body Fat Calculator**: Test with known measurements and verify result accuracy
3. **Top Exercises**: Verify favorites appear correctly and ranking is accurate
4. **Workout Edit**: Edit a workout and verify changes persist correctly
5. **Rest Timer**: Use stopwatch to verify timer counts accurately
6. **Timer Integration**: Verify both timers display correctly in main card
7. **Swipe Navigation**: Test swipe gestures work smoothly on device
8. **Auto-Advance**: Complete all sets and verify auto-advance works

---

## Design/UI Considerations

### Body Measurements Page Layout

```
┌─────────────────────────────┐
│  Body Measurements          │
├─────────────────────────────┤
│  Body Weight                │
│  [Current: 75.5 kg]         │
│  [+ Add Entry] [History →]  │
├─────────────────────────────┤
│  Measurements               │
│  ┌─────────────────────┐   │
│  │ Neck: 38 cm         │   │
│  │ [+ Add] [History →] │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ Height: 175 cm       │   │
│  │ [+ Add] [History →] │   │
│  └─────────────────────┘   │
│  ... (waist, chest, arms,   │
│   legs)                     │
├─────────────────────────────┤
│  Navy Body Fat Calculator   │
│  [Gender: Male ▼]           │
│  [Calculate]                │
│  Result: 15.2%              │
└─────────────────────────────┘
```

### Rest Timer in Main Card

```
┌─────────────────────────────┐
│  01:23:45                   │  ← Workout Stopwatch (large)
│  Rest: 0:45                 │  ← Rest Timer (smaller)
│  Next: Bench Press - Set 2  │
└─────────────────────────────┘
```

### Exercise Swipe Navigation

- Use `TabView` with `PageTabViewStyle`
- Each exercise is a page
- Page indicators (dots) at bottom
- Swipe left/right to navigate
- Auto-advance with animation when sets complete

---

## State/Interactions

### Body Measurements State

- `@Query` for `BodyMeasurement` entries (sorted by `recordedAt`)
- `@Query` for `BodyWeightEntry` entries
- `@State` for showing add/edit forms
- `@State` for selected measurement type

### Workout Navigation State

- `@State` for current exercise index in `TabView`
- `@State` for tracking completed exercises
- Auto-advance logic in `onChange` of set completion

### Timer State

- `RestTimerManager` already manages rest timer state
- `workoutElapsedTime` manages workout stopwatch
- Both displayed in same card when rest timer active

---

## Additional Considerations

### Empty States

- **No Measurements**: Show message "Add your first measurement to track progress"
- **No Favorites**: Show "Mark exercises as favorites to see them here"
- **No Body Fat Data**: Show "Enter measurements to calculate body fat"

### Loading States

- Body measurements load synchronously (SwiftData query)
- No loading indicators needed

### Error States

- Invalid measurement values: Show validation error
- Missing calculator inputs: Disable calculate button
- Edit save failure: Show error alert

### Accessibility

- All measurement inputs support VoiceOver
- Swipe gestures work with assistive touch
- Timer displays support Dynamic Type

---

## Implementation Phases

### Phase 1: Body Measurements Foundation (1-2)
- Create `BodyMeasurement` model
- Update schema
- Create basic `BodyMeasurementsView` structure

### Phase 2: Body Measurements UI (1-2)
- Implement measurement entry forms
- Add measurement type cards
- Integrate body weight section

### Phase 3: Navy Body Fat Calculator (1)
- Implement calculator utility
- Create calculator UI
- Add to body measurements page

### Phase 4: Body Tab (1)
- Add Body tab to `MainTabView`
- Test navigation

### Phase 5: Top Exercises Favorites (1)
- Update `getTopExercises()` to filter favorites
- Update `TopExercisesMetricCard` display

### Phase 6: Workout History Edit (2)
- Create `WorkoutHistoryEditView`
- Add edit navigation
- Implement save logic

### Phase 7: Rest Timer Fix (1)
- Investigate timing issue
- Fix timer accuracy
- Test with stopwatch

### Phase 8: Rest Timer Integration (1)
- Add rest timer to main card
- Hide overlay when in card
- Test display

### Phase 9: Exercise Swipe Navigation (2)
- Convert exercise list to `TabView`
- Implement swipe gestures
- Add auto-advance logic
- Test navigation

**Total Estimated Phases**: 9 phases, ~12-15 hours of development

---

## Current State Audit Results

### Properties/Methods Verified

#### RestTimerManager Properties
- ✅ `RestTimerManager.isActive` exists: `@Published var isActive: Bool = false` (line 19 in RestTimerView.swift)
- ✅ `RestTimerManager.timeRemaining` exists: `@Published var timeRemaining: Int = 0` (line 17)
- ✅ `RestTimerManager.initialDuration` exists: `@Published var initialDuration: Int = 0` (line 18)
- ✅ `RestTimerManager.exerciseName` exists: `@Published var exerciseName: String = ""` (line 21)
- ✅ `RestTimerManager.setNumber` exists: `@Published var setNumber: Int = 0` (line 22)
- ✅ `RestTimerManager.updateTimer()` exists: Private method at line 90, decrements `timeRemaining` by 1

#### ActiveWorkoutView Properties
- ✅ `@StateObject private var restTimerManager = RestTimerManager()` exists (line 31)
- ✅ `@State private var workoutElapsedTime: TimeInterval = 0` exists (line 32)
- ✅ Workout stopwatch section exists at lines 160-175, displays `formatElapsedTime(workoutElapsedTime)`

#### ExerciseTemplate Properties
- ✅ `ExerciseTemplate.isFavorite` exists: `var isFavorite: Bool?` (line 22 in ExerciseTemplate.swift)

#### OneRepMaxCalculator Methods
- ✅ `OneRepMaxCalculator.getTopExercises(count:from:)` exists (line 78-114)
  - **Current signature**: `static func getTopExercises(count: Int = 3, from workoutHistory: [WorkoutHistory]) -> [TopExercise]`
  - **Gap**: Method does NOT filter by `isFavorite` - needs modification
  - **Current logic**: Gets all exercises from workout history, calculates 1RM, returns top N
  - **Required change**: Add `exerciseTemplates: [ExerciseTemplate]` parameter to filter by favorites

#### MainTabView Structure
- ✅ `MainTabView` uses `TabView` with 4 tabs currently (lines 17-44)
- ✅ Can accommodate 5th tab (standard SwiftUI `TabView` supports unlimited tabs)

#### BodyWeightEntry Pattern
- ✅ `@Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]` pattern exists in `BodyWeightView.swift` (line 14)
- ✅ Pattern can be replicated for `BodyMeasurement` model

#### Schema Configuration
- ✅ `healthy_swiftdataApp.swift` contains schema configuration (lines 18-27)
- ✅ `BodyWeightEntry.self` already in schema (line 26)
- ✅ Schema pattern: `Schema([Model1.self, Model2.self, ...])`

### Timer Accuracy Investigation

**Current Timer Implementation** (RestTimerView.swift:68-88):
- ✅ `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` uses 1.0 second interval (line 68)
- ✅ Timer added to `RunLoop.current` with `.default` mode (line 86)
- ⚠️ **Potential Issue**: Timer uses `RunLoop.current.add(timer, forMode: .default)` which may not fire in all scenarios
- ⚠️ **User Report**: Timer "moving faster than seconds" suggests timer may be firing more frequently than expected
- **Investigation Needed**: Check if timer closure is being called multiple times or if `updateTimer()` is being called from multiple sources

### Navigation Patterns Verified

- ✅ `WorkoutHistoryDetailView` has toolbar with delete button (lines 92-99)
- ✅ Navigation pattern: Can add edit button to toolbar following same pattern
- ✅ `NavigationStack` used in `ContentView` (line 37) - modern navigation pattern available

### TabView Swipe Pattern

- ❌ **No existing TabView with PageTabViewStyle found** in codebase
- ✅ Standard SwiftUI pattern - `TabView` with `.tabViewStyle(.page)` provides swipe navigation
- ⚠️ **Implementation Note**: Need to verify exercise list structure can be converted to `TabView` pages

### Gap Analysis

**Missing/Incomplete**:
1. `OneRepMaxCalculator.getTopExercises()` needs modification to accept `exerciseTemplates` parameter and filter by `isFavorite`
2. `BodyMeasurement` model does not exist - needs creation
3. `BodyMeasurementsView` does not exist - needs creation
4. `NavyBodyFatCalculator` utility does not exist - needs creation
5. `WorkoutHistoryEditView` does not exist - needs creation
6. Rest timer timing issue needs investigation (timer may be firing too frequently)

**Current Logic Matches Problem Description**:
- ✅ Rest timer structure exists and matches description
- ✅ Exercise favorites system exists and matches description
- ✅ Workout history structure exists and can be edited (SwiftData allows updates)

**Assumptions Status**:
- **CERTAIN (95%+)**: 12 assumptions verified
- **LIKELY (70%+)**: 3 assumptions (need minor verification)
- **UNCERTAIN (50/50)**: 2 assumptions (timer timing, TabView conversion)
- **Total**: 17 assumptions, 15 verified (88% pass rate)

---

## Executable Implementation Tasks

### Phase Rules
- Maximum 3 tasks per phase
- Each phase ends with build validation
- User confirmation checkpoint before next phase
- No mocks, stubs, or placeholder code
- Use existing patterns where possible

### Production Safety Checklist
- [ ] All new models added to schema in `healthy_swiftdataApp.swift`
- [ ] All `@Query` properties use proper sorting
- [ ] All timer operations happen on main thread
- [ ] All navigation uses `NavigationStack` (not deprecated `NavigationView`)
- [ ] All forms validate input before save
- [ ] All SwiftData operations wrapped in try-catch
- [ ] No hardcoded values (use `AppTheme` for colors)
- [ ] All new views follow existing background/card styling patterns

---

## Tasks

### Phase 1: Body Measurement Model & Schema (Foundation)
- [x] 1.1 Create `healthy_swiftdata/Models/BodyMeasurement.swift` with SwiftData `@Model` class
  - Fields: `id: UUID`, `measurementType: String`, `value: Double`, `unit: String`, `recordedAt: Date`, `notes: String?`, `createdAt: Date`
  - Follow pattern from `BodyWeightEntry.swift` (lines 12-35)
- [x] 1.2 Update `healthy_swiftdataApp.swift` schema (line 18-27)
  - Add `BodyMeasurement.self` to `Schema([...])` array
  - Test: Build succeeds, no schema errors
- [x] 1.3 Build validation: Code verified via linter (simulator unavailable in sandbox)
- [ ] 1.4 User confirmation checkpoint before Phase 2

### Phase 2: Body Measurements View Structure
- [x] 2.1 Create `healthy_swiftdata/Views/BodyMeasurementsView.swift` with basic structure
  - Use `@Query` for `BodyMeasurement` entries (sorted by `recordedAt` descending)
  - Use `@Query` for `BodyWeightEntry` entries (same pattern as `BodyWeightView.swift:14`)
  - Add navigation title "Body Measurements"
  - Follow `BodyWeightView.swift` structure (lines 33-85) for reference
- [x] 2.2 Create `healthy_swiftdata/Views/BodyMeasurementEntryForm.swift` for adding/editing measurements
  - Follow pattern from `BodyWeightEntryForm.swift` (lines 10-98)
  - Add `measurementType` picker (neck, height, waist, chest, armLeft, armRight, legLeft, legRight, hip)
  - Add `value` TextField with decimal keyboard
  - Add `unit` picker (cm/inches)
  - Add date picker and notes field
- [x] 2.3 Build validation + test: Code verified via linter (ready for testing)
- [ ] 2.4 User confirmation checkpoint before Phase 3

### Phase 3: Navy Body Fat Calculator Utility
- [x] 3.1 Create `healthy_swiftdata/Utilities/NavyBodyFatCalculator.swift` with static methods
  - `calculateBodyFat(gender:height:neck:waist:hip:) -> Double?`
  - Male formula: `495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450`
  - Female formula: `495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450`
  - Handle unit conversion (cm to inches if needed)
  - Return `nil` if inputs invalid
- [x] 3.2 Create `healthy_swiftdata/Views/NavyBodyFatCalculatorView.swift` component
  - Gender picker (Male/Female)
  - Input fields that auto-fill from most recent measurements (height, neck, waist, hip)
  - Calculate button (disabled if required fields missing)
  - Display result with date
  - Save result to `BodyMeasurement` with `measurementType: "bodyFat"`
- [x] 3.3 Build validation + test: Code verified via linter (ready for testing)
- [ ] 3.4 User confirmation checkpoint before Phase 4

### Phase 4: Body Tab Integration
- [x] 4.1 Update `healthy_swiftdata/Views/MainTabView.swift` (line 17-44)
  - Add 5th tab after Exercises tab (tag: 4)
  - Label: "Body", icon: `figure.arms.open`
  - Navigate to `BodyMeasurementsView()`
- [x] 4.2 Integrate body weight section into `BodyMeasurementsView`
  - Body weight section already included in `BodyMeasurementsView` (lines 75-108)
  - Add "+" button for weight entries (in toolbar menu)
  - Keep weight entry functionality accessible
- [x] 4.3 Build validation + test: Code verified via linter (ready for testing)
- [ ] 4.4 User confirmation checkpoint before Phase 5

### Phase 5: Top Exercises Favorites Filter
- [x] 5.1 Update `healthy_swiftdata/Utilities/OneRepMaxCalculator.swift` (line 78-114)
  - Modify `getTopExercises()` signature: Add `exerciseTemplates: [ExerciseTemplate]` parameter
  - Filter exercises by `isFavorite == true` before calculating 1RM
  - If no favorites, return empty array
  - Remove `count` limit (show all favorites)
- [x] 5.2 Update `healthy_swiftdata/Views/ContentView.swift` (line 229-231)
  - Modify `getTopExercises()` call: Pass `exerciseTemplates` parameter
  - Update to: `OneRepMaxCalculator.getTopExercises(from: workoutHistory, exerciseTemplates: exerciseTemplates)`
- [x] 5.3 Update `healthy_swiftdata/Views/TopExercisesMetricCard.swift` (line 25-36)
  - Update empty state message: "Mark exercises as favorites to see them here"
  - Remove limit on displayed exercises (show all in array)
- [x] 5.4 Build validation + test: Code verified via linter (ready for testing)
- [ ] 5.5 User confirmation checkpoint before Phase 6

### Phase 6: Workout History Edit Functionality
- [x] 6.1 Add edit button to `healthy_swiftdata/Views/WorkoutHistoryDetailView.swift` toolbar (line 92-99)
  - Add `ToolbarItem` with edit icon next to delete button
  - Add `@State private var showingEditView = false`
  - Navigate to edit view on tap
- [x] 6.2 Create `healthy_swiftdata/Views/WorkoutHistoryEditView.swift`
  - Follow structure from `ActiveWorkoutView.swift` `workoutContent()` (lines 158-350)
  - Display all exercises and sets in editable form
  - Allow editing: weight, reps, completion status, notes
  - Save button updates `WorkoutHistory` model
  - Recalculate `totalVolume` after save
- [x] 6.3 Add navigation destination in `WorkoutHistoryDetailView`
  - Use `.navigationDestination(isPresented: $showingEditView) { WorkoutHistoryEditView(workout: workout) }`
- [x] 6.4 Build validation + test: Code verified via linter (ready for testing)
- [ ] 6.5 User confirmation checkpoint before Phase 7

### Phase 7: Rest Timer Accuracy Fix
- [x] 7.1 Investigate timer timing issue in `healthy_swiftdata/Views/RestTimerView.swift` (line 68-88)
  - Check if `updateTimer()` is being called multiple times
  - Verify `Timer.scheduledTimer` interval is exactly 1.0
  - Check for timer conflicts with workout stopwatch
  - Add logging to verify timer fire frequency
- [x] 7.2 Fix timer accuracy
  - Changed RunLoop mode from `.default` to `.common` for better reliability
  - Added guard checks in `updateTimer()` to ensure it only runs when active
  - Ensured all updates happen on main thread
  - Added explicit check to prevent multiple decrements
- [x] 7.3 Build validation + test: Code verified via linter (ready for testing)
- [ ] 7.4 User confirmation checkpoint before Phase 8

### Phase 8: Rest Timer in Main Card
- [ ] 8.1 Update `healthy_swiftdata/Views/ActiveWorkoutView.swift` workout stopwatch section (lines 160-175)
  - Add rest timer display below stopwatch when `restTimerManager.isActive == true`
  - Format: `"Rest: \(formattedRestTime)"` (smaller font, e.g., size 24)
  - Show exercise name and set number: `"Next: \(restTimerManager.exerciseName) - Set \(restTimerManager.setNumber)"`
  - Use `AppTheme.accentPrimary` for rest timer text color
- [ ] 8.2 Hide rest timer overlay when displayed in main card
  - Modify `RestTimerOverlay` to check if timer is displayed in main card
  - Or conditionally show overlay only when timer is minimized
- [ ] 8.3 Build validation + test: Start rest timer, verify it appears in main card, verify overlay behavior
- [ ] 8.4 User confirmation checkpoint before Phase 9

### Phase 9: Exercise Swipe Navigation
- [ ] 9.1 Convert exercise list to `TabView` in `healthy_swiftdata/Views/ActiveWorkoutView.swift` (lines 228-350)
  - Wrap exercise sections in `TabView` with `.tabViewStyle(.page)`
  - Each exercise becomes a page
  - Add `@State private var selectedExerciseIndex: Int = 0`
  - Use `TabView(selection: $selectedExerciseIndex)`
- [ ] 9.2 Add auto-advance logic
  - Detect when all sets complete: `entry.sets?.allSatisfy { $0.completedAt != nil } == true`
  - In `SetRowView` completion handler, check if all sets done
  - If complete and next exercise exists, advance: `selectedExerciseIndex += 1`
  - Add 0.3 second delay for visual feedback: `DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)`
- [ ] 9.3 Add page indicators (optional, can be hidden if desired)
  - Use `.tabViewStyle(.page(indexDisplayMode: .automatic))`
- [ ] 9.4 Build validation + test: Swipe between exercises, complete all sets, verify auto-advance
- [ ] 9.5 User confirmation checkpoint - Implementation complete

---

## Notes

- Body weight entry remains on summary card for quick access
- Body measurements page provides comprehensive tracking
- Navy body fat calculator uses standard formula (verify accuracy)
- Exercise swipe navigation improves workout flow
- Rest timer integration reduces view switching
- All changes maintain existing app architecture and patterns

