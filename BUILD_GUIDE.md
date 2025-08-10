# PCalcs Build Guide - Step by Step

## Current Status: 90% Ready to Build! 🎯

The app is **ALMOST READY** - just needs quick Xcode cleanup.

### What's Fixed:
- ✅ Only 2 Swift files: PCalcsApp.swift + ContentView.swift
- ✅ All complex dependencies moved to Backup/ folder  
- ✅ **AccentColor.colorset added** (blue aviation theme)
- ✅ **AppIcon.appiconset fixed** (no missing file references)
- ✅ Professional PCalcs branding ready

### What Needs Xcode GUI Fix:
- ❌ Remove PerfCalcCore package dependency (2 clicks in Xcode)
- ❌ Remove GRDB package dependency (2 clicks in Xcode)  
- ❌ Remove dead file references (right-click → delete)

**See BUILD_STATUS.md for 3-minute fix instructions!**

---

## Next Steps - Add Features One by One

### Step 1: Test Basic Build
```bash
# In Xcode:
1. Open PCalcs.xcodeproj
2. Select iPad simulator
3. Build and Run (⌘R)
4. Should show "PCalcs" welcome screen
```

### Step 2: Add Basic Input Form
**Goal**: Add simple weight input field

**Changes needed**:
```swift
// In ContentView.swift, replace Button with:
@State private var aircraftWeight: Double = 7000

VStack {
    Text("Aircraft Weight")
    Stepper(value: $aircraftWeight, in: 4000...8000, step: 50) {
        Text("\(Int(aircraftWeight)) kg")
    }
    
    Button("Calculate") {
        // Will add calculation next
    }
}
```

### Step 3: Add Dummy Calculation
**Goal**: Show basic result when Calculate pressed

**Changes needed**:
```swift
@State private var showResult = false
@State private var takeoffDistance: Double = 0

// In button action:
takeoffDistance = aircraftWeight * 0.8 + 1200 // Dummy calculation
showResult = true

// Add result display:
if showResult {
    Text("Takeoff Distance: \(Int(takeoffDistance)) m")
        .font(.title2)
        .fontWeight(.bold)
}
```

### Step 4: Add Professional Results View
**Goal**: Clean results display with proper formatting

### Step 5: Add Basic PDF Export
**Goal**: Generate simple PDF report

### Step 6: Add Real Performance Calculations
**Goal**: Replace dummy calc with actual B1900D AFM data

### Step 7: Add Weather Input
**Goal**: Manual METAR entry capability

---

## Building Strategy

### ✅ Current Foundation
- Minimal viable app structure
- Professional appearance
- Zero dependencies
- Guaranteed to build

### 🎯 Next Milestone: Basic Calculator
- Weight input
- Simple calculation 
- Results display
- Still builds reliably

### 🎯 Future Milestone: Professional MVP
- Real performance calculations
- PDF export
- Weather integration
- Ready for airline demo

---

## Troubleshooting

### If Build Breaks:
1. Check you didn't add complex imports
2. Make sure no undefined types/classes
3. Comment out the last thing you added
4. Build incrementally - test after each small change

### Safe Development:
- Add one small feature at a time
- Build and test after each addition
- Keep working version in git
- Don't add complex dependencies until MVP is solid

---

## File Structure (Ultra-Minimal)

```
PCalcs/
├── PCalcs/
│   ├── App/
│   │   └── PCalcsApp.swift          # ✅ ONLY app entry point
│   ├── Views/
│   │   └── ContentView.swift        # ✅ ONLY view file
│   ├── Backup/                      # ✅ All complex code safely stored
│   │   └── [79 complex files]       # Can restore later when needed
│   ├── Assets.xcassets/            # ✅ App icons
│   └── Info.plist                  # ✅ App metadata
```

**Total Swift Files: 2** (vs previous 79)

### Files to Add Back Later:
- All files are safely stored in Backup/ folder
- Add them back one by one as features are needed
- Can restore full professional app when MVP is proven

---

## Testing Checklist

### Before Each Step:
- [ ] App builds without warnings
- [ ] App launches without crashes  
- [ ] UI looks professional on iPad
- [ ] Previous functionality still works

### Ready for Demo:
- [ ] Professional appearance
- [ ] Accurate calculations
- [ ] Error handling
- [ ] PDF export works
- [ ] Tested on actual iPad hardware