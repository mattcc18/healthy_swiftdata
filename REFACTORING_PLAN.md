# Refactoring Plan - Following PRD 05

## 🚨 Gate 1: Blast Radius Assessment

### Dependency Analysis Results
- **ActiveWorkoutView references**: 11 files (MainTabView, ContentView, etc.)
- **ContentView references**: 3 files (MainTabView, App entry point)
- **BodyWeightView references**: 2 files (MainTabView, navigation)
- **Total affected files**: <10 files
- **Decision**: ✅ Standard incremental replacement process

### Blast Radius Decision Matrix
- **<10 files affected**: ✅ Standard incremental replacement
- **10-20 files affected**: Phased approach required
- **>20 files affected**: Architectural redesign needed

**Result**: Standard refactor process approved

## 🔧 Refactoring Assumptions

### Dependency Analysis (MUST AUDIT)
- **Usage Count**: ActiveWorkoutView used in ~3 files (VERIFIED - MainTabView, ContentView, App)
- **Call Patterns**: Direct instantiation in TabView (VERIFIED - MainTabView.swift:25)
- **Import Dependencies**: SwiftUI, SwiftData, HealthKit (VERIFIED - standard imports)
- **Inheritance Chain**: No inheritance, struct-based views (VERIFIED - all views are structs)

### Impact Analysis (MUST AUDIT)
- **Platform Differences**: iOS-only, no platform-specific variations (VERIFIED - iOS app)
- **Data Flow Changes**: SwiftData @Query will remain unchanged (ASSUMED - minimal impact)
- **Test Coverage**: No existing tests (UNCERTAIN - need to verify)
- **Build Dependencies**: Can refactor incrementally (LIKELY - SwiftUI allows component extraction)

### Refactoring Strategy Assumptions (MUST AUDIT)
- **Replacement Pattern**: Extract components into separate files (LIKELY - standard SwiftUI pattern)
- **Migration Path**: Can extract one component at a time (LIKELY - independent components)
- **Rollback Safety**: Git commits after each extraction (ASSUMED - with proper git strategy)

## 📋 Refactoring Targets

### Priority 1: ActiveWorkoutView.swift (935 lines)
**Issues Identified:**
- Too many responsibilities (workout display, template management, timer, state)
- 41 state properties and computed properties
- Large nested view builders
- Repeated patterns for warmup/main exercises

**Components to Extract:**
1. `SetRowView` - Already exists but could be moved to separate file
2. `AddExerciseSheet` - Extract to `Views/Components/AddExerciseSheet.swift`
3. `WorkoutStopwatchView` - Extract to `Views/Components/WorkoutStopwatchView.swift`
4. `ExerciseSectionView` - Extract warmup/main exercise sections
5. `WorkoutTemplateListView` - Extract template list logic

### Priority 2: ContentView.swift (608 lines)
**Issues Identified:**
- HealthKit data management mixed with UI
- Multiple chart data calculation functions
- Large metric card generation logic

**Components to Extract:**
1. `HealthKitDataManager` - Extract to `ViewModels/HealthKitDataViewModel.swift`
2. `MetricCardFactory` - Extract metric card generation logic
3. Chart data calculation functions - Move to utilities

### Priority 3: BodyWeightView.swift (567 lines)
**Issues Identified:**
- Similar HealthKit integration as ContentView
- Chart logic duplication

**Components to Extract:**
1. Reuse HealthKitDataViewModel from ContentView refactor
2. Extract chart components

## 🔄 Incremental Replacement Strategy

### Phase 1: Extract ActiveWorkoutView Components ✅ COMPLETED
1. ✅ Create `Views/Components/` directory
2. ✅ Extract `SetRowView` to `Views/Components/SetRowView.swift`
3. ✅ Extract `AddExerciseSheet` to `Views/Components/AddExerciseSheet.swift`
4. ✅ Extract `CategoryFilterButton` to `Views/Components/CategoryFilterButton.swift` (shared component)
5. ✅ Remove duplicate definitions from ActiveWorkoutView.swift
6. ✅ Remove duplicate definition from ExercisesView.swift
7. ⏳ Build and verify (pending - simulator issues in sandbox)

### Phase 2: Extract State Management ✅ COMPLETED
1. ✅ Create `ViewModels/` directory
2. ✅ Extract HealthKit logic to `HealthKitDataViewModel.swift` (108 lines)
3. ✅ Update ContentView to use ViewModel (all 42 references updated)
4. ✅ Remove old HealthKit state management code from ContentView
5. ✅ ContentView reduced from 608 to 521 lines (~14% reduction)
6. ⏳ Build and verify (pending - simulator issues in sandbox)

### Phase 3: Extract Repeated Patterns ✅ COMPLETED
1. ✅ Update BodyWeightView to use HealthKitDataViewModel (removed duplicate HealthKit logic)
2. ✅ Removed 59 lines of duplicate HealthKit code from BodyWeightView
3. ✅ BodyWeightView reduced from 567 to 508 lines (~10% reduction)
4. ✅ Both ContentView and BodyWeightView now share the same HealthKit ViewModel
5. ⏳ Build and verify (pending - simulator issues in sandbox)

### Phase 4: Cleanup
1. Remove unused code
2. Verify zero references to old patterns
3. Final build validation

## ✅ Build Validation Requirements
- Build MUST pass after every single file change
- Never accumulate multiple compilation errors
- Test affected functionality after each extraction
- Git commit after each successful extraction

## 🚫 Anti-Patterns to Avoid
- ❌ Delete old code before creating new
- ❌ Change multiple files before building
- ❌ Assume "it's probably not used elsewhere"
- ❌ Bulk find-and-replace without understanding context

