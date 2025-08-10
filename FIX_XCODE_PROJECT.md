# Fix Xcode Project - Manual Steps Required

## The Problem
The Xcode project file still references:
- ❌ PerfCalcCore package dependency
- ❌ GRDB package dependency  
- ❌ All 77 files we moved to Backup/

## Quick Fix in Xcode (Recommended)

### Step 1: Remove Package Dependencies
1. Open `PCalcs.xcodeproj` in Xcode
2. Select project in Navigator (top level "PCalcs")
3. Go to **Package Dependencies** tab
4. **Remove** both packages:
   - `PerfCalcCore` (local)
   - `GRDB.swift` (remote)

### Step 2: Clean Up File References  
1. In Project Navigator, find any **red files** (missing references)
2. **Delete references** to all missing files (right-click → Delete → "Remove Reference")
3. Keep only these files:
   ```
   PCalcs/
   ├── App/
   │   └── PCalcsApp.swift          ✅ Keep
   ├── Views/
   │   └── ContentView.swift        ✅ Keep  
   ├── Assets.xcassets/             ✅ Keep
   └── Info.plist                   ✅ Keep
   ```

### Step 3: Fix Asset Issues
1. Select `Assets.xcassets`
2. **Add AccentColor**:
   - Right-click in assets → New Color Set
   - Name: `AccentColor`
   - Set to any blue color
3. **Fix AppIcon**:
   - Select AppIcon set
   - Add a simple 1024×1024 icon (or use SF Symbol airplane)

### Step 4: Clean Build
```bash
# In Xcode menu:
Product → Clean Build Folder
```

## Alternative: Nuclear Option (If Above Fails)

If the project is too broken, **create new project**:

1. **File → New → Project**
2. **iOS App**, name: `PCalcs`
3. **Copy our 2 Swift files** to new project
4. **Copy Assets.xcassets** 
5. **Copy Info.plist** settings

## Verification
After fixing, you should see:
- ✅ **Zero build errors**
- ✅ Only 2 Swift files compiling
- ✅ No package dependencies
- ✅ App launches with professional PCalcs screen

## Expected Result
```
Build succeeded (0 errors, 0 warnings)
App launches → Professional "PCalcs B1900D Performance Calculator" welcome screen
```