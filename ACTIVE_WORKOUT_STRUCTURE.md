# Active Workout View Structure

## Visual Container Hierarchy with Padding

```
NavigationView
└── Group
    └── workoutContent(workout: ActiveWorkout)
        └── List
            │
            ├── Section (Timer Card)
            │   └── VStack(spacing: 12)                    ← 12pt between elements
            │       │
            │       ├── if restTimerManager.isActive:
            │       │   └── VStack(spacing: 8)              ← 8pt between elements
            │       │       ├── Text (Rest Timer - 56pt font)
            │       │       │
            │       │       ├── GeometryReader (Progress Bar)
            │       │       │   └── ZStack(alignment: .leading)
            │       │       │       ├── Rectangle (Background track - 4pt height)
            │       │       │       └── Rectangle (Progress fill)
            │       │       │       └── .padding(.horizontal)        ← ~16pt default
            │       │       │
            │       │       ├── Text (Rest info - caption)
            │       │       │
            │       │       └── Text (Duration - 24pt font)
            │       │
            │       └── else:
            │           └── Text (Duration - 56pt font)
            │       │
            │       └── .frame(maxWidth: .infinity)
            │       └── .padding(.vertical, 16)            ← 16pt top + 16pt bottom
            │       └── .contentShape(Rectangle())
            │       └── .allowsHitTesting(false)
            │       └── .listRowInsets(EdgeInsets(          ← 0pt all sides
            │           top: 0, leading: 0, bottom: 0, trailing: 0))
            │
            ├── Section (Rest Timer Buttons) [if active]
            │   └── HStack(spacing: 12)                     ← 12pt between buttons
            │       ├── Button (-15)
            │       │   └── .frame(width: 50, height: 36)
            │       ├── Button (Skip Rest)
            │       │   └── .frame(maxWidth: .infinity, height: 36)
            │       └── Button (+15)
            │           └── .frame(width: 50, height: 36)
            │       └── .padding(.horizontal, 4)            ← 4pt left + 4pt right
            │       └── .padding(.vertical, 4)              ← 4pt top + 4pt bottom
            │       └── .listRowInsets(EdgeInsets(          ← 0pt top/bottom, 16pt sides
            │           top: 0, leading: 16, bottom: 0, trailing: 16))
            │
            ├── Section (Warmup) [if warmupEntries exist]
            │   └── ForEach(warmupEntries)
            │       └── Section(header: Text(entry.exerciseName))
            │           ├── ForEach(sets)
            │           │   └── SetRowView(showLabels: true)
            │           │       └── .padding(.vertical, 4)  ← 4pt top + 4pt bottom
            │           └── Button (Add Set)
            │
            └── Section (Main Exercises - TabView)
                └── TabView(selection: $selectedExerciseIndex)
                    └── ForEach(mainEntries.enumerated())
                        └── exerciseView(for: entry, workout: workout)
                            └── ScrollView
                                └── VStack(alignment: .leading, spacing: 12)  ← 12pt between elements
                                    │
                                    ├── Text (Exercise Name - title2)
                                    │   └── .padding(.horizontal)              ← ~16pt default
                                    │   └── .padding(.top)                     ← ~16pt default
                                    │
                                    ├── HStack (Column Headers) [if sets exist]
                                    │   ├── Color.clear (Set placeholder - 60pt width)
                                    │   ├── Text ("Reps" - 80pt width)
                                    │   ├── Text ("Weight" - 80pt width)
                                    │   └── Color.clear (Completion placeholder - 44pt width)
                                    │   └── .padding(.horizontal)              ← ~16pt default
                                    │   └── .padding(.top, 8)                  ← 8pt top
                                    │
                                    ├── ForEach(sets)
                                    │   └── SetRowView(showLabels: false)
                                    │       └── .padding(.horizontal)          ← ~16pt default
                                    │
                                    ├── Text ("No sets yet") [if no sets]
                                    │   └── .padding(.horizontal)              ← ~16pt default
                                    │
                                    └── Button (Add Set)
                                        └── .padding(.horizontal)              ← ~16pt default
                                        └── .padding(.bottom)                  ← ~16pt default
```

## SetRowView Structure with Padding

```
SetRowView
└── HStack (default spacing)
    │
    ├── ZStack (Set Number Circle)
    │   ├── Circle (32x32pt, fill: cardTertiary)
    │   └── Text (setNumber)
    │   └── .frame(width: 60pt, alignment: .leading)
    │
    ├── Spacer()
    │
    ├── if showLabels:
    │   └── VStack(alignment: .leading, spacing: 4)        ← 4pt between label and field
    │       ├── Text ("Reps" - caption)
    │       └── TextField (Reps input - 80pt width)
    │   else:
    │       └── TextField (Reps input - 80pt width)
    │
    ├── if showLabels:
    │   └── VStack(alignment: .leading, spacing: 4)        ← 4pt between label and field
    │       ├── Text ("Weight" - caption)
    │       └── TextField (Weight input - 80pt width)
    │   else:
    │       └── TextField (Weight input - 80pt width)
    │
    ├── Spacer()
    │
    └── Button (Completion toggle)
        └── Image (checkmark.circle.fill or circle - title2)
    │
    └── .padding(.vertical, 4)                              ← 4pt top + 4pt bottom
```

## Complete Padding Summary

### Timer Card Section
- **VStack**: `spacing: 12pt` (between timer elements)
- **Inner VStack** (when resting): `spacing: 8pt` (between rest timer elements)
- **Progress bar**: `.padding(.horizontal)` = **~16pt** (left + right)
- **Section content**: `.padding(.vertical, 16pt)` = **16pt top + 16pt bottom**
- **Section row insets**: `EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)` = **0pt all sides**

### Rest Timer Buttons Section
- **HStack**: `spacing: 12pt` (between buttons)
- **Buttons container**: 
  - `.padding(.horizontal, 4pt)` = **4pt left + 4pt right**
  - `.padding(.vertical, 4pt)` = **4pt top + 4pt bottom**
- **Section row insets**: `EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)` = **0pt top/bottom, 16pt left/right**

### Exercise View (TabView)
- **VStack**: `spacing: 12pt` (between all elements), `alignment: .leading`
- **Exercise name**: 
  - `.padding(.horizontal)` = **~16pt** (left + right)
  - `.padding(.top)` = **~16pt** (top)
- **Column headers**: 
  - `.padding(.horizontal)` = **~16pt** (left + right)
  - `.padding(.top, 8pt)` = **8pt** (top)
- **Set rows**: `.padding(.horizontal)` = **~16pt** (left + right)
- **Add Set button**: 
  - `.padding(.horizontal)` = **~16pt** (left + right)
  - `.padding(.bottom)` = **~16pt** (bottom)

### SetRowView
- **HStack**: Default spacing (system default, typically ~8pt)
- **Content**: `.padding(.vertical, 4pt)` = **4pt top + 4pt bottom**
- **Set circle**: 32x32pt circle, in 60pt width frame
- **Reps/Weight fields**: 80pt width each
- **VStack spacing** (when showLabels=true): `spacing: 4pt` (between label and field)

### Warmup Section
- **SetRowView**: `.padding(.vertical, 4pt)` = **4pt top + 4pt bottom**
- Uses default List section padding

