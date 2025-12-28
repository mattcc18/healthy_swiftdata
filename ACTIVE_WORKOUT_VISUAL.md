# Active Workout View - Visual Phone Screen Layout

## Screen Layout (iPhone Portrait)

```
┌─────────────────────────────────────┐
│  Navigation Bar                     │
│  [Add]  Active Workout  [Finish]    │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │  TIMER CARD SECTION            │ │
│  │  ┌─────────────────────────┐  │ │
│  │  │                         │  │ │
│  │  │   VStack(spacing: 12)   │  │ │
│  │  │                         │  │ │
│  │  │   ┌─────────────────┐   │  │ │
│  │  │   │  IF RESTING:    │   │  │ │
│  │  │   │  VStack(8)       │   │  │ │
│  │  │   │                 │   │  │ │
│  │  │   │  00:45          │   │  │ │ ← 56pt font (Rest Timer)
│  │  │   │                 │   │  │ │
│  │  │   │  ┌───────────┐  │   │  │ │
│  │  │   │  │███████░░░░│  │   │  │ │ ← Progress bar (4pt height)
│  │  │   │  └───────────┘  │   │  │ │    padding: 16pt horizontal
│  │  │   │                 │   │  │ │
│  │  │   │  Rest: Squat... │   │  │ │ ← Caption
│  │  │   │                 │   │  │ │
│  │  │   │  12:34.56       │   │  │ │ ← 24pt font (Duration)
│  │  │   │                 │   │  │ │
│  │  │   └─────────────────┘   │  │ │
│  │  │                         │  │ │
│  │  │   OR IF NOT RESTING:    │  │ │
│  │  │                         │  │ │
│  │  │   12:34.56             │  │ │ ← 56pt font (Duration only)
│  │  │                         │  │ │
│  │  └─────────────────────────┘  │ │
│  │  padding: 16pt vertical        │ │
│  │  insets: 0pt all sides          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  REST TIMER BUTTONS            │ │ (if active)
│  │  ┌─────────────────────────┐  │ │
│  │  │  HStack(spacing: 12)    │  │ │
│  │  │                         │  │ │
│  │  │  ┌──┐  ┌──────────┐  ┌──┐│  │ │
│  │  │  │-15│  │Skip Rest│  │+15││  │ │
│  │  │  └──┘  └──────────┘  └──┘│  │ │
│  │  │  50x36  flex width  50x36│  │ │
│  │  │                         │  │ │
│  │  └─────────────────────────┘  │ │
│  │  padding: 4pt horizontal       │ │
│  │  padding: 4pt vertical         │ │
│  │  insets: 0/16/0/16             │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  WARMUP SECTION                 │ │ (if exists)
│  │  ┌─────────────────────────┐  │ │
│  │  │  Section(header: "Warmup")│  │ │
│  │  │                         │  │ │
│  │  │  ┌─────────────────────┐ │  │ │
│  │  │  │  Exercise Name     │ │  │ │
│  │  │  │  ┌───────────────┐ │  │ │
│  │  │  │  │ SetRowView    │ │  │ │
│  │  │  │  │ [1] Reps Weight│ │  │ │
│  │  │  │  └───────────────┘ │  │ │
│  │  │  │  [Add Set]         │ │  │ │
│  │  │  └─────────────────────┘ │  │ │
│  │  │                         │  │ │
│  │  └─────────────────────────┘  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  MAIN EXERCISES - TABVIEW       │ │
│  │  ┌─────────────────────────┐  │ │
│  │  │  TabView (swipeable)     │  │ │
│  │  │                         │  │ │
│  │  │  ┌─────────────────────┐ │  │ │
│  │  │  │  ScrollView         │ │  │ │
│  │  │  │  ┌───────────────┐  │ │  │ │
│  │  │  │  │ VStack(12)    │  │ │  │ │
│  │  │  │  │               │  │ │  │ │
│  │  │  │  │  Squat        │  │ │  │ │ ← title2, padding: 16pt H, 16pt T
│  │  │  │  │               │  │ │  │ │
│  │  │  │  │  ┌───────────┐ │  │ │  │ │
│  │  │  │  │  │Headers   │ │  │ │  │ │
│  │  │  │  │  │Set Reps W│ │  │ │  │ │ ← padding: 16pt H, 8pt T
│  │  │  │  │  └───────────┘ │  │ │  │ │
│  │  │  │  │               │  │ │  │ │
│  │  │  │  │  ┌───────────┐ │  │ │  │ │
│  │  │  │  │  │[1] 12 100│ │  │ │  │ │ ← SetRowView
│  │  │  │  │  └───────────┘ │  │ │  │ │    padding: 16pt H
│  │  │  │  │  ┌───────────┐ │  │ │  │ │
│  │  │  │  │  │[2] 10 100│ │  │ │  │ │
│  │  │  │  │  └───────────┘ │  │ │  │ │
│  │  │  │  │               │  │ │  │ │
│  │  │  │  │  [Add Set]    │  │ │  │ │ ← padding: 16pt H, 16pt B
│  │  │  │  │               │  │ │  │ │
│  │  │  │  └───────────────┘  │ │  │ │
│  │  │  └─────────────────────┘ │  │ │
│  │  │                         │  │ │
│  │  │  [Page Indicators]      │  │ │ ← Auto page dots
│  │  └─────────────────────────┘  │ │
│  │  height: calculated            │ │
│  │  background: black             │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## SetRowView Detailed Layout

```
┌─────────────────────────────────────────────┐
│  HStack (default spacing ~8pt)              │
│                                              │
│  ┌────┐                                      │
│  │ (1)│  ← ZStack: 32x32 circle, 60pt frame  │
│  └────┘                                      │
│       [Spacer ~8pt]                          │
│              ┌──────────┐                   │
│              │ VStack(4)│                   │
│              │ Reps     │  ← if showLabels  │
│              │ [____]    │                   │
│              └──────────┘                   │
│                      80pt width              │
│              [Spacer ~8pt]                   │
│                       ┌──────────┐          │
│                       │ VStack(4)│          │
│                       │ Weight   │  ← if showLabels
│                       │ [____]   │          │
│                       └──────────┘          │
│                               80pt width     │
│                       [Spacer ~8pt]          │
│                                ┌────┐        │
│                                │ ✓  │  ← Button (44pt)
│                                └────┘        │
│                                              │
│  padding: 4pt vertical                       │
└─────────────────────────────────────────────┘
```

## Spacing & Padding Reference

### Timer Card
```
┌─────────────────────────────┐
│  padding: 16pt top          │
│  ┌───────────────────────┐  │
│  │ VStack(spacing: 12)   │  │
│  │                       │  │
│  │ Timer Text            │  │
│  │                       │  │ ← 12pt gap
│  │ Progress Bar          │  │
│  │   padding: 16pt H     │  │
│  │                       │  │ ← 8pt gap (inner VStack)
│  │ Rest Info             │  │
│  │                       │  │ ← 8pt gap
│  │ Duration              │  │
│  └───────────────────────┘  │
│  padding: 16pt bottom       │
└─────────────────────────────┘
```

### Rest Timer Buttons
```
┌─────────────────────────────┐
│  padding: 4pt top           │
│  ┌───────────────────────┐  │
│  │ HStack(spacing: 12)   │  │
│  │                       │  │
│  │ [-15] [Skip Rest] [+15]│ │
│  │  50pt    flex     50pt │  │
│  │                       │  │
│  └───────────────────────┘  │
│  padding: 4pt bottom         │
│  insets: 16pt left/right     │
└─────────────────────────────┘
```

### Exercise View (TabView)
```
┌─────────────────────────────┐
│  ScrollView                 │
│  ┌───────────────────────┐  │
│  │ VStack(spacing: 12)   │  │
│  │                       │  │
│  │ "Squat"               │  │ ← padding: 16pt H, 16pt T
│  │                       │  │
│  │ ┌───────────────────┐│  │ ← 12pt gap
│  │ │ Headers            ││  │
│  │ │ Set Reps Weight    ││  │ ← padding: 16pt H, 8pt T
│  │ └───────────────────┘│  │
│  │                       │  │
│  │ ┌───────────────────┐│  │ ← 12pt gap
│  │ │ [1] 12 100  ✓     ││  │
│  │ └───────────────────┘│  │ ← padding: 16pt H
│  │ ┌───────────────────┐│  │
│  │ │ [2] 10 100  ✓     ││  │
│  │ └───────────────────┘│  │
│  │                       │  │
│  │ [Add Set]             │  │ ← 12pt gap, padding: 16pt H/B
│  │                       │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

## Dimensions Summary

| Element | Width | Height | Spacing/Padding |
|---------|-------|--------|----------------|
| Timer Card VStack | maxWidth | auto | spacing: 12pt |
| Timer Card padding | - | - | vertical: 16pt |
| Rest Timer VStack | maxWidth | auto | spacing: 8pt |
| Progress Bar | flex | 4pt | horizontal: 16pt |
| Rest Buttons HStack | flex | - | spacing: 12pt |
| Rest Button (-15/+15) | 50pt | 36pt | - |
| Rest Button (Skip) | flex | 36pt | - |
| Rest Buttons padding | - | - | 4pt all |
| Exercise VStack | flex | auto | spacing: 12pt |
| Exercise name padding | - | - | 16pt H, 16pt T |
| Column headers padding | - | - | 16pt H, 8pt T |
| SetRowView padding | - | - | 16pt H, 4pt V |
| Set Circle | 32pt | 32pt | in 60pt frame |
| Reps/Weight field | 80pt | auto | - |
| VStack label spacing | - | - | 4pt |


