; ================================================================================
; REFINE TREE HELPER v1.0 - Revolution Idle Automation Script
; ================================================================================
; Description: Automates mineral spawning, polishing and refining in Revolution Idle
; Author: GullibleMonkey
; Optimized for AutoHotkey v2.0
; Usage: F5 to start/stop, F6/F7 to cycle, F8/F9 to toggle, F10 to compact, Esc to exit
; ================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn

; ================================================================================
; INITIALIZATION
; ================================================================================

SendMode "Input"
SetMouseDelay 0
SetKeyDelay 0, 0
CoordMode "Mouse", "Screen"

; Disable DPI awareness to prevent font scaling issues on high DPI displays
; This ensures consistent appearance across different DPI settings
try {
    DllCall("SetProcessDpiAwarenessContext", "ptr", -1)  ; DPI_AWARENESS_CONTEXT_UNAWARE
} catch {
    ; Fallback - no DPI awareness
}

; ================================================================================
; CONFIGURATION
; ================================================================================

class Config {
    ; Target game process name
    static TARGET_PROCESS := "Revolution Idle.exe"
    
    ; Configuration file path for saving user preferences
    static CONFIG_FILE := A_ScriptDir "\RefineTreeHelper_v1.ini"
    
    ; UI color scheme
    static COLOR_WHITE := 0xFFFFFF
    static COLOR_BLACK := 0x000000
    static COLOR_GRAY := 0x808080
    
    ; How often to update the UI display (in milliseconds)
    static UI_UPDATE_INTERVAL := 250
    
    ; Game click coordinates - these map to specific buttons in the game
    static coords := Map(
        ; Mineral spawning buttons
        "spawn", [809, 1454],
        "spawnLevel", [879, 1348],
        "maxLevel", [1100, 650],
        "autospawn", [960, 1251],
        
        ; Weapon polishing menu
        "polishOpen", [1223, 1452],
        "polishPrestige", [1231, 550],
        "polishPrestigeConfirm", [1514, 933],
        "polishLevelUp", [1694, 1386],
        "polishClose", [1919, 421],
        
        ; Weapon selection buttons
        "sword", [111, 1000],
        "axe", [400, 1000],
        "spear", [700, 1000],
        "bow", [1000, 1000],
        "knuckle", [1400, 1000],
        
        ; Refining menu
        "refineOpen", [1730, 1456],
        "refinePrestige", [1695, 591],
        "refinePrestigeConfirm", [1497, 967],
        "refineClose", [79, 383],
        
        ; Game tabs
        "timeFluxTab", [2100, 820],
        "attacksTab", [2100, 640],
        "shopTab", [2100, 1300],
        "automationTab", [2100, 730],
        "unityTab", [2100, 540],
        
        ; Automation controls
        "automerge", [1852, 249],
        
        ; Time warp controls
        "timewarpStart", [785, 1055],
        "timewarpStop", [1200, 895],
        
        ; Shop actions
        "buyTimeFlux", [1200, 1400],
        "purchaseConfirm", [1500, 850],
        
        ; Unity actions
        "unite", [1000, 1450],
        "uniteConfirm1", [1200, 750],
        "uniteConfirm2", [1500, 900],
        "zodiacWater", [1200, 1100],
        "zodiacWind", [1500, 750],
        "zodiacEarth", [1200, 400],
        "zodiacFire", [850, 750],
        
        ; Empty space for endgame exploit
        "emptySpace", [833, 1217]
    )
    
    ; Order in which to level up weapons
    static weaponOrder := ["sword", "axe", "spear", "bow", "knuckle"]
}

; ================================================================================
; GLOBAL STATE MANAGEMENT
; ================================================================================

class State {
    ; Macro execution state flags
    static isRunning := false        ; Is the macro currently running?
    static isStarting := false       ; Is the macro in the process of starting?
    static isStopping := false       ; Is the macro in the process of stopping?
    static isLocked := false         ; Is the macro locked (prevents multiple starts)?
    static queuedStart := false      ; Is there a queued start request?
    
    ; Performance statistics
    static cycleCount := 0           ; Number of completed refine cycles
    static startTime := 0            ; When the current macro run started
    static currentMacro := "standard"  ; Active macro type (default: standard)
    static gameState := "early"      ; Game progression state (default: early)
    static cycleTimes := []          ; Array of recent cycle completion times
    static lastCycleEnd := 0        ; Timestamp of last cycle completion
    
    ; User-configurable settings with defaults
    static mineralLevel := "999"     ; Highest mineral level to spawn
    static mergeWaitTime := "10000"  ; Milliseconds to wait for minerals to merge (default: 10000)
    static microDelayMs := 25        ; Small delay between actions (default: 25)
    static timewarpInterval := "10000" ; Time warp burst interval (default: 10000ms)
    static exploitWaitTime := "500"  ; Exploit wait time (default: 500ms)
    static bwThreshold := 128        ; Black/white threshold for screenshot processing
    
    ; Custom game state values
    static customSpawnReps := "4"    ; Custom spawn repetitions
    static customPolishReps := "1"   ; Custom polish repetitions
    
    ; Fine Settings toggles (true = enabled/auto, false = disabled/no auto)
    static autoRefining := true      ; Auto refining enabled (default: true)
    static autoRftUpgrade := true    ; Auto RfT upgrade enabled (default: true)
    static allWeaponsPolish := false ; Polish all weapons vs sword only (default: false)
    
    ; Automation Unlockables (false = locked/manual, true = unlocked/auto)
    static autospawnUnlocked := false     ; Autospawn feature unlocked (default: false)
    static automergeUnlocked := false     ; Automerge feature unlocked (default: false)
    static autoMaxLevelUnlocked := false  ; Auto max level upgrade unlocked (default: false)
    static autoWeaponPolishUnlocked := false ; Auto weapon polish unlocked (default: false)
    
    ; Unity Parameters (zodiac element selection)
    static zodiacEarth := false           ; Earth zodiac element selected (default: false)
    static zodiacFire := false            ; Fire zodiac element selected (default: false)
    static zodiacWind := false            ; Wind zodiac element selected (default: false)
    static zodiacWater := false           ; Water zodiac element selected (default: false)
    static currentZodiacIndex := 0        ; Current zodiac index for cycling
    
    ; UI section visibility states
    static sectionStates := Map(
        "macro", true,
        "gamestate", true,
        "finesettings", true,
        "unlockables", true,
        "variables", true,
        "unityparameters", true,
        "statistics", true,
        "info", true
    )
    
    ; Screenshot capture settings
    static lastScreenshotPath := ""
    static captureRect := {x: 1017, y: 386, w: 470, h: 49}
    static captureMode := "screen"
}

; ================================================================================
; UI COMPONENTS
; ================================================================================

class UI {
    ; Main UI windows
    static gui := 0              ; Main HUD window
    static compactGui := 0       ; Compact mode window (small eye icon)
    static isVisible := true     ; Is the main HUD visible?
    static isCompact := false    ; Is the HUD in compact mode?
    
    ; GDI+ token for screenshot functionality
    static gdiToken := 0
    
    ; UI state tracking
    static buttonStates := Map()      ; Track button active states
    static sectionContents := Map()   ; Store controls for each collapsible section
    
    ; Header controls
    static header := 0
    static titleText := 0
    static headerLeft := 0
    static headerRight := 0
    static btnEye := 0        ; Compact mode toggle
    static btnClose := 0      ; Exit button
    static btnStartStop := 0  ; Main start/stop button
    
    ; Section headers for collapsible sections
    static sectionHeaders := Map()
    
    ; Macro selection buttons
    static btnMacroStandard := 0
    static btnMacroQuick := 0
    static btnMacroLong := 0
    static btnMacroEndgame := 0
    static btnMacroTimeWarp := 0
    static btnMacroAutoClicker := 0
    static btnMacroTimeFluxBuy := 0
    static btnMacroAutoUnity := 0
    
    ; Game state selection buttons
    static btnStateEarly := 0
    static btnStateMid := 0
    static btnStateLate := 0
    static btnStateCustom := 0
    static inputCustomSpawn := 0
    static inputCustomPolish := 0
    
    ; Fine Settings buttons
    static btnToggleRefining := 0
    static btnToggleRftUpgrade := 0
    static btnTogglePolishMode := 0
    
    ; Automation Unlockables buttons
    static btnToggleAutospawn := 0
    static btnToggleAutomerge := 0
    static btnToggleAutoMaxLevel := 0
    static btnToggleAutoWeaponPolish := 0
    
    ; Variable input controls
    static lblMineralLevel := 0
    static inputMineralLevel := 0
    static lblMergeWait := 0
    static inputMergeWait := 0
    static lblMicroDelay := 0
    static inputMicroDelay := 0
    static lblTimewarp := 0
    static inputTimewarp := 0
    static lblExploitWait := 0
    static inputExploitWait := 0
    
    ; Unity Parameters buttons
    static btnZodiacEarth := 0
    static btnZodiacFire := 0
    static btnZodiacWind := 0
    static btnZodiacWater := 0
    
    ; Statistics display controls
    static imgPreview := 0
    static lblStatistics := 0
    static lblCycleTime := 0
    
    ; Info section control
    static lblInfo := 0
    
    ; Layout constants
    static hudW := 540     ; HUD window width (increased for full labels)
    static pad := 16       ; Padding around elements
    static gap := 10       ; Gap between buttons
    static btnH := 34      ; Standard button height
    static hdrH := 42      ; Header height
}

; ================================================================================
; UTILITY FUNCTIONS
; ================================================================================

class Util {
    ; Convert milliseconds to readable time format (HH:MM:SS:X)
    static FormatTime(ms) {
        sec := Floor(ms / 1000)
        h := Floor(sec / 3600)
        rem := sec - (h * 3600)
        m := Floor(rem / 60)
        s := rem - (m * 60)
        ds := Floor((ms - (sec * 1000)) / 100)
        return Format("{:02d}:{:02d}:{:02d}:{:01d}", h, m, s, ds)
    }
    
    ; Sleep function that can be interrupted if macro stops
    static Sleep(ms) {
        remain := ms
        step := (ms >= 2000) ? 50 : (ms >= 500 ? 25 : 10)
        while (remain > 0) {
            if !State.isRunning
                return
            s := (remain < step) ? remain : step
            Sleep s
            remain -= s
        }
    }
    
    ; Focus the game window, optionally forcing focus
    static FocusGame(force := true) {
        hwnd := WinExist("ahk_exe " Config.TARGET_PROCESS)
        if !hwnd
            return false
        if force || !WinActive("ahk_id " hwnd) {
            WinActivate "ahk_id " hwnd
            WinWaitActive "ahk_id " hwnd, , 0.8
        }
        return WinActive("ahk_id " hwnd)
    }
    
    ; Check if the game window is not active
    static IsGameBlocked() {
        return !WinActive("ahk_exe " Config.TARGET_PROCESS)
    }
}

; ================================================================================
; CONFIGURATION MANAGEMENT
; ================================================================================

class ConfigManager {
    ; Load settings from INI file
    static Load() {
        ini := Config.CONFIG_FILE
        
        ; Load macro and game state settings
        State.currentMacro := IniRead(ini, "Settings", "Macro", "standard")
        State.gameState := IniRead(ini, "Settings", "GameState", "early")
        State.mineralLevel := IniRead(ini, "Settings", "MineralLevel", "999")
        State.mergeWaitTime := IniRead(ini, "Settings", "MergeWaitTime", "10000")
        State.bwThreshold := IniRead(ini, "Settings", "BWThreshold", 128) + 0
        State.timewarpInterval := IniRead(ini, "Settings", "TimewarpInterval", "10000")
        State.exploitWaitTime := IniRead(ini, "Settings", "ExploitWaitTime", "500")
        
        ; Load custom game state values
        State.customSpawnReps := IniRead(ini, "Settings", "CustomSpawnReps", "4")
        State.customPolishReps := IniRead(ini, "Settings", "CustomPolishReps", "1")
        
        ; Load delay setting with backward compatibility
        State.microDelayMs := IniRead(ini, "Settings", "MicroDelayMs", 25) + 0
        oldDelay := IniRead(ini, "Settings", "MICRO_DELAY", "")
        if (oldDelay != "" && State.microDelayMs = 25) {
            State.microDelayMs := oldDelay + 0
        }
        
        ; Load Fine Settings toggles (all default to true)
        State.autoRefining := (IniRead(ini, "FineSettings", "AutoRefining", 1) + 0) ? true : false
        State.autoRftUpgrade := (IniRead(ini, "FineSettings", "AutoRftUpgrade", 1) + 0) ? true : false
        State.allWeaponsPolish := (IniRead(ini, "FineSettings", "AllWeaponsPolish", 0) + 0) ? true : false
        
        ; Load Automation Unlockables (all default to false)
        State.autospawnUnlocked := (IniRead(ini, "Unlockables", "AutospawnUnlocked", 0) + 0) ? true : false
        State.automergeUnlocked := (IniRead(ini, "Unlockables", "AutomergeUnlocked", 0) + 0) ? true : false
        State.autoMaxLevelUnlocked := (IniRead(ini, "Unlockables", "AutoMaxLevelUnlocked", 0) + 0) ? true : false
        State.autoWeaponPolishUnlocked := (IniRead(ini, "Unlockables", "AutoWeaponPolishUnlocked", 0) + 0) ? true : false
        
        ; Load Unity Parameters (all default to false)
        State.zodiacEarth := (IniRead(ini, "UnityParameters", "ZodiacEarth", 0) + 0) ? true : false
        State.zodiacFire := (IniRead(ini, "UnityParameters", "ZodiacFire", 0) + 0) ? true : false
        State.zodiacWind := (IniRead(ini, "UnityParameters", "ZodiacWind", 0) + 0) ? true : false
        State.zodiacWater := (IniRead(ini, "UnityParameters", "ZodiacWater", 0) + 0) ? true : false
        
        ; Load section visibility states
        for section in ["macro", "gamestate", "finesettings", "unlockables", "variables", "unityparameters", "statistics", "info"] {
            State.sectionStates[section] := (IniRead(ini, "Sections", section, 1) + 0) ? true : false
        }
        
        ; Load screenshot capture settings
        State.captureRect.x := IniRead(ini, "Capture", "X", State.captureRect.x) + 0
        State.captureRect.y := IniRead(ini, "Capture", "Y", State.captureRect.y) + 0
        State.captureRect.w := IniRead(ini, "Capture", "W", State.captureRect.w) + 0
        State.captureRect.h := IniRead(ini, "Capture", "H", State.captureRect.h) + 0
        State.captureMode := IniRead(ini, "Capture", "Mode", State.captureMode)
    }
    
    ; Save settings to INI file
    static Save() {
        ini := Config.CONFIG_FILE
        
        ; Save window position if GUI exists
        if UI.gui && IsObject(UI.gui) {
            try {
                x := 0, y := 0
                WinGetPos &x, &y, , , "ahk_id " UI.gui.Hwnd
                IniWrite x, ini, "UI", "X"
                IniWrite y, ini, "UI", "Y"
            }
        }
        
        ; Save all settings
        IniWrite State.currentMacro, ini, "Settings", "Macro"
        IniWrite State.gameState, ini, "Settings", "GameState"
        IniWrite State.mineralLevel, ini, "Settings", "MineralLevel"
        IniWrite State.mergeWaitTime, ini, "Settings", "MergeWaitTime"
        IniWrite State.microDelayMs, ini, "Settings", "MicroDelayMs"
        IniWrite State.bwThreshold, ini, "Settings", "BWThreshold"
        IniWrite State.timewarpInterval, ini, "Settings", "TimewarpInterval"
        IniWrite State.exploitWaitTime, ini, "Settings", "ExploitWaitTime"
        IniWrite State.customSpawnReps, ini, "Settings", "CustomSpawnReps"
        IniWrite State.customPolishReps, ini, "Settings", "CustomPolishReps"
        
        ; Save Fine Settings
        IniWrite (State.autoRefining ? 1 : 0), ini, "FineSettings", "AutoRefining"
        IniWrite (State.autoRftUpgrade ? 1 : 0), ini, "FineSettings", "AutoRftUpgrade"
        IniWrite (State.allWeaponsPolish ? 1 : 0), ini, "FineSettings", "AllWeaponsPolish"
        
        ; Save Automation Unlockables
        IniWrite (State.autospawnUnlocked ? 1 : 0), ini, "Unlockables", "AutospawnUnlocked"
        IniWrite (State.automergeUnlocked ? 1 : 0), ini, "Unlockables", "AutomergeUnlocked"
        IniWrite (State.autoMaxLevelUnlocked ? 1 : 0), ini, "Unlockables", "AutoMaxLevelUnlocked"
        IniWrite (State.autoWeaponPolishUnlocked ? 1 : 0), ini, "Unlockables", "AutoWeaponPolishUnlocked"
        
        ; Save Unity Parameters
        IniWrite (State.zodiacEarth ? 1 : 0), ini, "UnityParameters", "ZodiacEarth"
        IniWrite (State.zodiacFire ? 1 : 0), ini, "UnityParameters", "ZodiacFire"
        IniWrite (State.zodiacWind ? 1 : 0), ini, "UnityParameters", "ZodiacWind"
        IniWrite (State.zodiacWater ? 1 : 0), ini, "UnityParameters", "ZodiacWater"
        
        ; Save section states
        for section, isOpen in State.sectionStates {
            IniWrite (isOpen ? 1 : 0), ini, "Sections", section
        }
        
        ; Save capture settings
        IniWrite State.captureRect.x, ini, "Capture", "X"
        IniWrite State.captureRect.y, ini, "Capture", "Y"
        IniWrite State.captureRect.w, ini, "Capture", "W"
        IniWrite State.captureRect.h, ini, "Capture", "H"
        IniWrite State.captureMode, ini, "Capture", "Mode"
    }
}

; ================================================================================
; GAME ACTIONS
; ================================================================================

class Action {
    ; Click at a named coordinate from the Config.coords map
    static Click(name) {
        if !State.isRunning || !Config.coords.Has(name) || Util.IsGameBlocked()
            return false
        xy := Config.coords[name]
        Click xy[1], xy[2]
        Util.Sleep(State.microDelayMs)
        return true
    }
    
    ; Type text into the game (selects all first)
    static Type(text) {
        if !State.isRunning || Util.IsGameBlocked()
            return false
        Send "^a"  ; Select all
        Sleep 30
        SendText text
        Util.Sleep(State.microDelayMs)
        return true
    }
    
    ; Spawn a single mineral
    static SpawnMineral() {
        Action.Click("spawn")
    }
    
    ; Level up mineral based on unlockable toggle
    static LevelUpMineral() {
        if (!State.autoMaxLevelUnlocked) {
            ; LOCKED mode: click max level first, then set level
            Action.Click("maxLevel")
            Util.Sleep(10)
            Action.Click("spawnLevel")
            Action.Type(State.mineralLevel)
        } else {
            ; UNLOCKED mode: directly set level
            Action.Click("spawnLevel")
            Action.Type(State.mineralLevel)
        }
    }
    
    ; Set mineral level to a specific value
    static SetMineralLevel(level) {
        Action.Click("spawnLevel")
        Action.Type(level)
    }
    
    ; Extended spawn for a duration
    static ExtendedSpawn(duration) {
        if (State.autospawnUnlocked) {
            ; Auto mode: use autospawn toggle
            Action.Click("autospawn")
            Util.Sleep(duration)
            Action.Click("autospawn")
        } else {
            ; Manual mode: click repeatedly
            startTime := A_TickCount
            while ((A_TickCount - startTime) < duration && State.isRunning) {
                Action.Click("spawn")
                Util.Sleep(State.microDelayMs)
            }
        }
    }
    
    ; Polish weapons - either sword only or all weapons
    static PolishWeapons() {
        if !State.isRunning
            return
        
        ; Open polish menu and prestige
        Action.Click("polishOpen")
        Util.Sleep(State.microDelayMs)
        Action.Click("polishPrestige")
        Util.Sleep(State.microDelayMs)
        Action.Click("polishPrestigeConfirm")
        Util.Sleep(State.microDelayMs)
        
        ; Level weapons if NOT unlocked (manual mode)
        if (!State.autoWeaponPolishUnlocked) {
            if (!State.allWeaponsPolish) {
                ; Polish only sword
                Action.Click("sword")
                Util.Sleep(State.microDelayMs)
                Action.Click("polishLevelUp")
                Util.Sleep(State.microDelayMs)
            } else {
                ; Polish all weapons
                for weapon in Config.weaponOrder {
                    if !State.isRunning
                        return
                    Action.Click(weapon)
                    Util.Sleep(State.microDelayMs)
                    Action.Click("polishLevelUp")
                    Util.Sleep(State.microDelayMs)
                }
            }
        }
        
        ; Close polish menu
        Action.Click("polishClose")
        Util.Sleep(State.microDelayMs)
    }
    
    ; Toggle auto merge
    static AutoMerge() {
        if !State.automergeUnlocked
            return
        
        ; Open automation menu and toggle merge
        Action.Click("automationTab")
        Util.Sleep(State.microDelayMs)
        Action.Click("automerge")
        Util.Sleep(State.microDelayMs)
        Action.Click("automerge")
        Util.Sleep(State.microDelayMs)
        Action.Click("unityTab")
        Util.Sleep(State.microDelayMs)
    }
    
    ; Refine minerals and update statistics
    static Refine() {
        ; Skip if auto refining is disabled
        if !State.autoRefining
            return
        
        ; Open refine menu and prestige
        Action.Click("refineOpen")
        Util.Sleep(State.microDelayMs)
        Action.Click("refinePrestige")
        Util.Sleep(State.microDelayMs)
        Action.Click("refinePrestigeConfirm")
        Util.Sleep(State.microDelayMs)
        
        ; Buy RfT upgrade if enabled
        if (State.autoRftUpgrade) {
            Action.Click("refineOpen")
            Util.Sleep(State.microDelayMs)
        }
        
        ; Close refine menu
        Action.Click("refineClose")
        Util.Sleep(State.microDelayMs)
        
        ; Update cycle statistics
        if State.lastCycleEnd > 0 {
            cycleTime := A_TickCount - State.lastCycleEnd
            State.cycleTimes.Push(cycleTime)
            if State.cycleTimes.Length > 20
                State.cycleTimes.RemoveAt(1)
        }
        State.lastCycleEnd := A_TickCount
        
        State.cycleCount += 1
        UIManager.Update()
    }
}

; ================================================================================
; ACTION SEQUENCES
; ================================================================================

class Sequence {
    ; Get spawn and polish repetitions based on game state
    static GetRepetitions() {
        spawnReps := 4
        polishReps := 1
        
        switch State.gameState {
            case "early":
                spawnReps := 7
                polishReps := 3
            case "mid":
                spawnReps := 5
                polishReps := 2
            case "late":
                spawnReps := 4
                polishReps := 1
            case "custom":
                spawnReps := State.customSpawnReps + 0
                polishReps := State.customPolishReps + 0
        }
        
        return {spawn: spawnReps, polish: polishReps}
    }
    
    ; Basic spawn sequence: spawn and level up one mineral
    static BasicSpawn() {
        Action.SpawnMineral()
        Action.LevelUpMineral()
    }
    
    ; Spawn with polish - repetitions based on game state
    static SpawnWithPolish() {
        reps := Sequence.GetRepetitions()
        
        ; Execute spawn and polish cycles
        Loop reps.polish {
            Loop reps.spawn {
                if !State.isRunning
                    return
                Sequence.BasicSpawn()
            }
            if State.isRunning
                Action.PolishWeapons()
        }
    }
    
    ; Spawn only (no polish) - also affected by game state
    static SpawnOnly() {
        reps := Sequence.GetRepetitions()
        
        Loop reps.spawn {
            if !State.isRunning
                return
            Sequence.BasicSpawn()
        }
    }
    
    ; Extended spawn sequence
    static ExtendedSpawn(duration) {
        Action.ExtendedSpawn(duration)
        Action.LevelUpMineral()
    }
    
    ; Final merge sequence - also affected by game state
    static FinalMerge(duration) {
        reps := Sequence.GetRepetitions()
        
        Loop reps.spawn {
            if !State.isRunning
                return
            Sequence.BasicSpawn()
        }
        
        Sequence.ExtendedSpawn(duration)
        Action.AutoMerge()
    }
    
    ; Get merge wait time from user input
    static GetMergeWaitTime() {
        waitTime := State.mergeWaitTime = "" ? 10000 : (State.mergeWaitTime + 0)
        if waitTime <= 0
            waitTime := 5000
        return waitTime
    }
    
    ; Get time warp interval from user input
    static GetTimewarpInterval() {
        interval := State.timewarpInterval = "" ? 10000 : (State.timewarpInterval + 0)
        if interval <= 0
            interval := 75
        return interval
    }
    
    ; Get exploit wait time from user input
    static GetExploitWaitTime() {
        waitTime := State.exploitWaitTime = "" ? 500 : (State.exploitWaitTime + 0)
        if waitTime <= 0
            waitTime := 500
        return waitTime
    }
}

; ================================================================================
; MACRO DEFINITIONS
; ================================================================================

class Macro {
    ; Standard macro cycle - balanced approach
    static Standard() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            Screenshot.Capture()
        }
        
        if !State.isRunning
            return
        Sequence.SpawnWithPolish()
        
        if !State.isRunning
            return
        Sequence.FinalMerge(Sequence.GetMergeWaitTime())
        
        if !State.isRunning
            return
        Action.Refine()
    }
    
    ; Quick macro cycle - faster, less polishing
    static Quick() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            Screenshot.Capture()
        }
        
        if !State.isRunning
            return
        Sequence.SpawnWithPolish()
        
        if !State.isRunning
            return
        Sequence.SpawnOnly()
        
        if !State.isRunning
            return
        Action.Refine()
    }
    
    ; Long macro cycle - more thorough with extra polish
    static Long() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            Screenshot.Capture()
        }
        
        if !State.isRunning
            return
        Sequence.SpawnWithPolish()
        
        if !State.isRunning
            return
        Sequence.FinalMerge(Sequence.GetMergeWaitTime())
        
        if !State.isRunning
            return
        Action.PolishWeapons()
        
        if !State.isRunning
            return
        Sequence.FinalMerge(Sequence.GetMergeWaitTime())
        
        if !State.isRunning
            return
        Action.Refine()
    }
    
    ; Endgame exploit macro - special sequence for endgame
    static Endgame() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            Screenshot.Capture()
        }
        
        if !State.autoRefining {
            ; When Auto Refining is OFF - simple exploit loop
            if !State.isRunning
                return
            
            ; Spawn once
            Action.SpawnMineral()
            
            ; Inner loop: 10 level/spawn cycles
            Loop 10 {
                if !State.isRunning
                    return
                
                ; Level up, spawn, reset to level 1, spawn, wait
                Action.SetMineralLevel("999")
                Action.SpawnMineral()
                Action.SetMineralLevel("1")
                Action.Click("emptySpace")
                Util.Sleep(Sequence.GetExploitWaitTime())
            }
        } else {
            ; When Auto Refining is ON - complex sequence
            
            ; Start with Quick macro
            if !State.isRunning
                return
            Sequence.SpawnWithPolish()
            
            if !State.isRunning
                return
            Sequence.SpawnOnly()
            
            ; Set to max level and enable autospawn/automerge if unlocked
            if !State.isRunning
                return
            Action.SetMineralLevel("999")
            
            if State.autospawnUnlocked {
                Action.Click("autospawn")  ; Turn on autospawn
            }
            if State.automergeUnlocked {
                Action.Click("automerge")  ; Turn on automerge
            }
            
            ; Wait for merge
            Util.Sleep(Sequence.GetMergeWaitTime())
            
            ; Turn off autospawn/automerge
            if State.autospawnUnlocked {
                Action.Click("autospawn")  ; Turn off autospawn
            }
            if State.automergeUnlocked {
                Action.Click("automerge")  ; Turn off automerge
            }
            
            ; 3x (exploit loop x5 followed by Polish)
            Loop 3 {
                if !State.isRunning
                    return
                
                ; 5 exploit loops
                Loop 5 {
                    if !State.isRunning
                        return
                    
                    ; Spawn once
                    Action.SpawnMineral()
                    
                    ; Inner loop: 10 level/spawn cycles
                    Loop 10 {
                        if !State.isRunning
                            return
                        
                        Action.SetMineralLevel("999")
                        Action.SpawnMineral()
                        Action.SetMineralLevel("1")
                        Action.Click([833, 1217])
                        Util.Sleep(Sequence.GetExploitWaitTime())
                    }
                }
                
                ; Polish after 5 loops
                if State.isRunning
                    Action.PolishWeapons()
            }
            
            ; 1x (exploit loop x5 followed by Refining)
            if !State.isRunning
                return
            
            ; 5 exploit loops
            Loop 5 {
                if !State.isRunning
                    return
                
                ; Spawn once
                Action.SpawnMineral()
                
                ; Inner loop: 10 level/spawn cycles
                Loop 10 {
                    if !State.isRunning
                        return
                    
                    Action.SetMineralLevel("999")
                    Action.SpawnMineral()
                    Action.SetMineralLevel("1")
                    Action.Click([833, 1217])
                    Util.Sleep(Sequence.GetExploitWaitTime())
                }
            }
            
            ; Refine at the end
            if State.isRunning
                Action.Refine()
        }
    }
    
    ; Time Warp Burst macro - toggles time warp on and off
    static TimeWarp() {
        while State.isRunning {
            if !State.isRunning
                return
            
            ; Start time warp
            Action.Click("timewarpStart")
            
            ; Wait for interval
            Util.Sleep(Sequence.GetTimewarpInterval())
            
            if !State.isRunning
                return
            
            ; Stop time warp (no second wait)
            Action.Click("timewarpStop")
        }
    }
    
    ; Simple autoclicker - clicks at mouse position
    static AutoClicker() {
        ; Continuously click at current mouse position
        while State.isRunning {
            ; Only click if game is active
            if !Util.IsGameBlocked() {
                Click
            }
            ; Small delay between clicks
            Util.Sleep(State.microDelayMs)
        }
    }
    
    ; Time Flux Buy macro - loops between buyTimeFlux and purchaseConfirm
    static TimeFluxBuy() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            
            ; Go to Shop tab
            Action.Click("shopTab")
            Util.Sleep(State.microDelayMs)
            
            ; Buy Time Flux
            Action.Click("buyTimeFlux")
            Util.Sleep(State.microDelayMs)
            
            ; Confirm purchase
            Action.Click("purchaseConfirm")
            Util.Sleep(State.microDelayMs)
        }
    }
    
    ; Auto Unity macro - complex sequence with zodiac cycling
    static AutoUnity() {
        if State.isRunning {
            Util.Sleep(State.microDelayMs)
            
            ; Go to Time Flux Tab
            Action.Click("timeFluxTab")
            Util.Sleep(250)  ; Wait for Time Flux tab to load
            
            ; Click Time Warp Start
            Action.Click("timewarpStart")
            Util.Sleep(State.timewarpInterval)
            
            ; Click Time Warp Stop
            Action.Click("timewarpStop")
            Util.Sleep(250)  ; Wait after stopping time warp
            
            ; Go to Attacks tab
            Action.Click("attacksTab")
            Util.Sleep(State.microDelayMs)
            
            ; Click Unite
            Action.Click("unite")
            Util.Sleep(800)  ; Wait for Unite dialog to appear
            
            ; Click selected zodiac (cycle through selected ones)
            zodiacType := Macro.GetNextZodiac()
            if (zodiacType != "") {
                Action.Click(zodiacType)
                Util.Sleep(State.microDelayMs)
                
                ; Click Unite Confirmation 1
                Action.Click("uniteConfirm1")
                Util.Sleep(State.microDelayMs)
                
                ; Click Unite Confirmation 2
                Action.Click("uniteConfirm2")
                Util.Sleep(State.microDelayMs)
            }
            
            ; Wait in Attacks tab before next macro cycle
            Util.Sleep(7000)
        }
    }
    
    ; Helper function to get next zodiac in cycle
    static GetNextZodiac() {
        ; Build array of selected zodiacs in order: Fire -> Earth -> Wind -> Water
        selectedZodiacs := []
        if State.zodiacFire
            selectedZodiacs.Push("zodiacFire")
        if State.zodiacEarth
            selectedZodiacs.Push("zodiacEarth")
        if State.zodiacWind
            selectedZodiacs.Push("zodiacWind")
        if State.zodiacWater
            selectedZodiacs.Push("zodiacWater")
        
        if selectedZodiacs.Length = 0
            return ""
        
        ; Get current zodiac and advance to next
        State.currentZodiacIndex++
        if State.currentZodiacIndex > selectedZodiacs.Length
            State.currentZodiacIndex := 1
            
        return selectedZodiacs[State.currentZodiacIndex]
    }
}

; ================================================================================
; SCREENSHOT MANAGEMENT
; ================================================================================

class Screenshot {
    ; Initialize GDI+ for screenshot functionality
    static InitGDI() {
        if UI.gdiToken
            return
        
        ; Load GDI+ library
        h := DllCall("LoadLibrary", "str", "gdiplus.dll", "ptr")
        if !h
            throw Error("Failed to load gdiplus.dll")
        
        ; Start GDI+
        si := Buffer(16, 0)
        NumPut("UInt", 1, si, 0)
        token := 0
        DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", si, "ptr", 0)
        UI.gdiToken := token
    }
    
    ; Capture screenshot of game statistics
    static Capture() {
        Screenshot.InitGDI()
        
        ; Find game window
        hwnd := WinExist("ahk_exe " Config.TARGET_PROCESS)
        if !hwnd
            return
        
        ; Generate unique filename with timestamp
        timestamp := A_Now
        filename := A_Temp "\refine_shot_" timestamp ".png"
        
        ; Delete old file if exists
        if FileExist(filename)
            FileDelete(filename)
        
        ; Capture based on mode (screen or window)
        rect := State.captureRect
        if (State.captureMode = "screen") {
            Screenshot.CaptureRect(rect.x, rect.y, rect.w, rect.h, filename)
        } else {
            Screenshot.CaptureWindow(hwnd, rect.x, rect.y, rect.w, rect.h, filename)
        }
        
        ; Wait for file to be written
        Sleep 50
        
        ; Update UI with screenshot
        if FileExist(filename) {
            State.lastScreenshotPath := filename
            if UI.imgPreview && IsObject(UI.imgPreview) {
                try {
                    UI.imgPreview.Value := filename
                }
            }
        }
        
        ; Clean up old screenshots
        Screenshot.CleanOldFiles(12)
    }
    
    ; Capture a rectangular area of the screen
    static CaptureRect(x, y, w, h, outPath) {
        ; Create device context and bitmap
        hdcScreen := DllCall("GetDC", "ptr", 0, "ptr")
        hdcMem := DllCall("CreateCompatibleDC", "ptr", hdcScreen, "ptr")
        hbm := DllCall("CreateCompatibleBitmap", "ptr", hdcScreen, "int", w, "int", h, "ptr")
        DllCall("SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
        DllCall("BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h, 
                "ptr", hdcScreen, "int", x, "int", y, "uint", 0x00CC0020)
        
        ; Convert to GDI+ bitmap and apply threshold
        pBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &pBitmap)
        Screenshot.ApplyThreshold(pBitmap, State.bwThreshold)
        
        ; Save as PNG
        clsid := Screenshot.GetPngCLSID()
        DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", outPath, "ptr", clsid, "ptr", 0)
        
        ; Cleanup
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        DllCall("DeleteObject", "ptr", hbm)
        DllCall("DeleteDC", "ptr", hdcMem)
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScreen)
    }
    
    ; Capture a rectangular area of a specific window
    static CaptureWindow(hwnd, rx, ry, rw, rh, outPath) {
        rc := Buffer(16, 0)
        DllCall("GetClientRect", "ptr", hwnd, "ptr", rc)
        pt := Buffer(8, 0)
        DllCall("ClientToScreen", "ptr", hwnd, "ptr", pt)
        wx := NumGet(pt, 0, "int")
        wy := NumGet(pt, 4, "int")
        Screenshot.CaptureRect(wx + rx, wy + ry, rw, rh, outPath)
    }
    
    ; Apply black/white threshold to image for better OCR
    static ApplyThreshold(pBitmap, threshold := 128) {
        w := 0, h := 0
        DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &w)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &h)
        
        rect := Buffer(16, 0)
        NumPut("Int", 0, rect, 0)
        NumPut("Int", 0, rect, 4)
        NumPut("Int", w, rect, 8)
        NumPut("Int", h, rect, 12)
        
        bd := Buffer((A_PtrSize = 8) ? 32 : 24, 0)
        DllCall("gdiplus\GdipBitmapLockBits", "ptr", pBitmap, "ptr", rect, 
                "uint", 3, "int", 0x26200A, "ptr", bd)
        
        stride := NumGet(bd, 8, "Int")
        scan0 := NumGet(bd, 16, "Ptr")
        
        ; Process each pixel
        Loop h {
            y := A_Index - 1
            row := scan0 + y * stride
            Loop w {
                x := A_Index - 1
                p := row + x * 4
                b := NumGet(p, 0, "UChar")
                g := NumGet(p, 1, "UChar")
                r := NumGet(p, 2, "UChar")
                ; Calculate luminance
                lum := (r * 299 + g * 587 + b * 114) // 1000
                ; Apply threshold
                v := (lum >= threshold) ? 255 : 0
                NumPut("UChar", v, p, 0)
                NumPut("UChar", v, p, 1)
                NumPut("UChar", v, p, 2)
                NumPut("UChar", 255, p, 3)
            }
        }
        
        DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", pBitmap, "ptr", bd)
    }
    
    ; Get PNG codec CLSID for saving
    static GetPngCLSID() {
        guid := Buffer(16, 0)
        NumPut("UInt", 0x557CF406, guid, 0)
        NumPut("UShort", 0x1A04, guid, 4)
        NumPut("UShort", 0x11D3, guid, 6)
        NumPut("UChar", 0x9A, guid, 8)
        NumPut("UChar", 0x73, guid, 9)
        NumPut("UChar", 0x00, guid, 10)
        NumPut("UChar", 0x00, guid, 11)
        NumPut("UChar", 0xF8, guid, 12)
        NumPut("UChar", 0x1E, guid, 13)
        NumPut("UChar", 0xF3, guid, 14)
        NumPut("UChar", 0x2E, guid, 15)
        return guid
    }
    
    ; Clean up old screenshot files
    static CleanOldFiles(hours) {
        dir := A_Temp
        Loop Files dir "\refine_shot_*.png" {
            if (DateDiff(A_Now, A_LoopFileTimeModified, "Seconds") > hours * 3600) {
                try FileDelete A_LoopFileFullPath
            }
        }
    }
}

; ================================================================================
; USER INTERFACE MANAGER
; ================================================================================

class UIManager {
    static messagesSetup := false
    
    ; Initialize the UI system
    static Initialize() {
        if UI.gui && IsObject(UI.gui)
            return
        
        ConfigManager.Load()
        UIManager.CreateGUI()
        UIManager.SetupEventHandlers()
        UIManager.UpdateVisuals()
        SetTimer(() => UIManager.Update(), Config.UI_UPDATE_INTERVAL)
    }
    
    ; Create the main GUI window
    static CreateGUI() {
        ; Create main window with white border
        UI.gui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +Border")
        UI.gui.MarginX := 0
        UI.gui.MarginY := 0
        UI.gui.BackColor := "000000"  ; Black background
        UI.gui.SetFont("s10 cFFFFFF", "Cascadia Mono")  ; White text by default
        
        ; Layout configuration
        pad := UI.pad
        gap := UI.gap
        btnH := UI.btnH
        hdrH := UI.hdrH
        
        ; Initialize section contents map
        UI.sectionContents["macro"] := []
        UI.sectionContents["gamestate"] := []
        UI.sectionContents["finesettings"] := []
        UI.sectionContents["unlockables"] := []
        UI.sectionContents["variables"] := []
        UI.sectionContents["unityparameters"] := []
        UI.sectionContents["statistics"] := []
        UI.sectionContents["info"] := []
        
        ; Window width configuration
        UI.hudW := 540  ; Optimal width for all sections
        
        y := 0
        
        ; HEADER - white background
        UI.header := UI.gui.AddText(Format("x0 y0 w{} h{} +BackgroundFFFFFF", UI.hudW, hdrH), "")
        
        ; Title (center) - BLACK text on white background
        titleW := UI.hudW - 110  ; Adjusted for wider HUD
        titleX := 55
        titleY := (hdrH - 26) // 2
        UI.titleText := UI.gui.AddText(Format("x{} y{} w{} h26 Center +BackgroundFFFFFF", 
                                       titleX, titleY, titleW), "Refine Tree Helper v1.0")
        UI.titleText.SetFont("Bold s11 c000000", "Cascadia Mono")
        
        ; Eye icon (left) - BLACK on white background
        iconY := (hdrH - 24) // 2
        UI.btnEye := UI.gui.AddText(Format("x12 y{} w26 h24 Center +BackgroundFFFFFF", iconY), "👁")
        UI.btnEye.SetFont("s9 c000000", "Segoe UI Emoji")
        
        ; Close icon (right) - BLACK on white background (raised slightly)
        UI.btnClose := UI.gui.AddText(Format("x{} y{} w30 h24 Center +BackgroundFFFFFF", 
                                      UI.hudW - 42, iconY - 1), "✖")
        UI.btnClose.SetFont("Bold s11 c000000", "Segoe UI Symbol")
        
        ; Animated texts for when macro is running (hidden by default)
        UI.headerLeft := UI.gui.AddText(Format("x16 y{} w220 h26 Left +BackgroundFFFFFF +Hidden", 
                                        (hdrH - 26) // 2), "")
        UI.headerRight := UI.gui.AddText(Format("x{} y{} w160 h26 Right +BackgroundFFFFFF +Hidden", 
                                         UI.hudW - 176, (hdrH - 26) // 2), "")
        UI.headerLeft.SetFont("s10 c000000", "Cascadia Mono")
        UI.headerRight.SetFont("s10 c000000", "Cascadia Mono")
        
        ; Start/Stop button
        y := hdrH + pad
        btnStartW := 220  ; Increased for wider HUD
        btnX := (UI.hudW - btnStartW) // 2
        btn := UIManager.CreateStyledButton(btnX, y, btnStartW, btnH, "F5: Start macro", false)
        UI.btnStartStop := btn
        
        y += btnH + pad
        
        ; MACRO SECTION
        UIManager.CreateSectionHeader("macro", y, UI.hudW, "Select Macro")
        y += 32
        
        if State.sectionStates["macro"] {
            ; Row 1: Standard, Quick, Long
            btnW := 120  ; Increased width for wider HUD
            totalW := (btnW * 3) + (gap * 2)
            x := (UI.hudW - totalW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Standard", false)
            UI.btnMacroStandard := btn
            UI.sectionContents["macro"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Quick", false)
            UI.btnMacroQuick := btn
            UI.sectionContents["macro"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Long", false)
            UI.btnMacroLong := btn
            UI.sectionContents["macro"].Push(btn)
            
            y += btnH + gap
            
            ; Row 2: Time Warp Burst, Autoclicker
            btnW := 200  ; Increased width for Time Warp Burst
            totalW := (btnW * 2) + gap
            x := (UI.hudW - totalW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Time Warp Burst", false)
            UI.btnMacroTimeWarp := btn
            UI.sectionContents["macro"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Autoclicker", false)
            UI.btnMacroAutoClicker := btn
            UI.sectionContents["macro"].Push(btn)
            
            y += btnH + gap
            
            ; Row 3: Endgame Exploit
            btnW := 210  ; Increased for wider HUD
            x := (UI.hudW - btnW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Endgame Exploit", false)
            UI.btnMacroEndgame := btn
            UI.sectionContents["macro"].Push(btn)
            
            y += btnH + gap
            
            ; Row 4: Time Flux Buy, Auto Unity
            btnW := 170  ; Wider for longer text
            totalW := (btnW * 2) + gap
            x := (UI.hudW - totalW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Time Flux Buy", false)
            UI.btnMacroTimeFluxBuy := btn
            UI.sectionContents["macro"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Auto Unity", false)
            UI.btnMacroAutoUnity := btn
            UI.sectionContents["macro"].Push(btn)
            
            y += btnH + pad
        }
        
        ; GAME STATE SECTION
        UIManager.CreateSectionHeader("gamestate", y, UI.hudW, "Game State")
        y += 32
        
        if State.sectionStates["gamestate"] {
            ; Row 1: Early, Mid, Late, Custom
            btnW := 95  ; Increased width for wider HUD
            totalW := (btnW * 4) + (gap * 3)
            x := (UI.hudW - totalW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Early", false)
            UI.btnStateEarly := btn
            UI.sectionContents["gamestate"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Mid", false)
            UI.btnStateMid := btn
            UI.sectionContents["gamestate"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Late", false)
            UI.btnStateLate := btn
            UI.sectionContents["gamestate"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, "Custom", false)
            UI.btnStateCustom := btn
            UI.sectionContents["gamestate"].Push(btn)
            
            y += btnH + gap
            
            ; Custom spawn input (centered with more space for label)
            lblW := 170  ; Increased for full label
            edtW := 50   ; Width for 2-3 characters
            totalW := lblW + edtW + 15
            x := (UI.hudW - totalW) // 2
            
            lbl := UI.gui.AddText(Format("x{} y{} w{} h32", x, y+3, lblW), "Spawn reps:")
            UI.sectionContents["gamestate"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h32 Center +Border", x + lblW + 15, y, edtW), State.customSpawnReps)
            edt.SetFont("s10 c000000", "Cascadia Mono")
            UI.inputCustomSpawn := edt
            UI.sectionContents["gamestate"].Push(edt)
            
            y += 36
            
            ; Custom polish input (centered with more space for label)
            x := (UI.hudW - totalW) // 2
            lbl := UI.gui.AddText(Format("x{} y{} w{} h32", x, y+3, lblW), "Polish reps:")
            UI.sectionContents["gamestate"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h32 Center +Border", x + lblW + 15, y, edtW), State.customPolishReps)
            edt.SetFont("s10 c000000", "Cascadia Mono")
            UI.inputCustomPolish := edt
            UI.sectionContents["gamestate"].Push(edt)
            
            y += 36 + pad
        }
        
        ; FINE SETTINGS SECTION
        UIManager.CreateSectionHeader("finesettings", y, UI.hudW, "Fine Settings")
        y += 32
        
        if State.sectionStates["finesettings"] {
            ; All Fine Settings buttons
            btnW := 200  ; Increased for wider HUD
            totalW := (btnW * 2) + gap
            x := (UI.hudW - totalW) // 2
            
            ; Row 1: Auto Refining, Auto RfT Upgrade
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.autoRefining ? "Auto Refining" : "No Refining", State.autoRefining)
            UI.btnToggleRefining := btn
            UI.sectionContents["finesettings"].Push(btn)
            
            x += btnW + gap
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.autoRftUpgrade ? "Auto RfT Upg" : "No RfT Upg", State.autoRftUpgrade)
            UI.btnToggleRftUpgrade := btn
            UI.sectionContents["finesettings"].Push(btn)
            
            y += btnH + gap
            
            ; Row 2: Weapon Polish Mode
            btnW := 300  ; Adjusted for wider HUD
            x := (UI.hudW - btnW) // 2
            
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.allWeaponsPolish ? "All Weapons Polish" : "Sword Polish Only", State.allWeaponsPolish)
            UI.btnTogglePolishMode := btn
            UI.sectionContents["finesettings"].Push(btn)
            
            y += btnH + pad
        }
        
        ; AUTOMATION UNLOCKABLES SECTION
        UIManager.CreateSectionHeader("unlockables", y, UI.hudW, "Automation Unlockables")
        y += 32
        
        if State.sectionStates["unlockables"] {
            ; Each button on its own line for full width
            btnW := 320  ; Increased for wider HUD
            x := (UI.hudW - btnW) // 2
            
            ; Row 1: Autospawn
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.autospawnUnlocked ? "Autospawn UNLOCKED" : "Autospawn LOCKED", State.autospawnUnlocked)
            UI.btnToggleAutospawn := btn
            UI.sectionContents["unlockables"].Push(btn)
            
            y += btnH + gap
            
            ; Row 2: Automerge
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.automergeUnlocked ? "Automerge UNLOCKED" : "Automerge LOCKED", State.automergeUnlocked)
            UI.btnToggleAutomerge := btn
            UI.sectionContents["unlockables"].Push(btn)
            
            y += btnH + gap
            
            ; Row 3: Auto Max Level
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.autoMaxLevelUnlocked ? "Auto Max Lvl UNLOCKED" : "Auto Max Lvl LOCKED", State.autoMaxLevelUnlocked)
            UI.btnToggleAutoMaxLevel := btn
            UI.sectionContents["unlockables"].Push(btn)
            
            y += btnH + gap
            
            ; Row 4: Auto Weapon Polish
            btn := UIManager.CreateStyledButton(x, y, btnW, btnH, 
                State.autoWeaponPolishUnlocked ? "Auto Wpn Polish UNLOCKED" : "Auto Wpn Polish LOCKED", State.autoWeaponPolishUnlocked)
            UI.btnToggleAutoWeaponPolish := btn
            UI.sectionContents["unlockables"].Push(btn)
            
            y += btnH + pad
        }
        
        ; VARIABLES SECTION
        UIManager.CreateSectionHeader("variables", y, UI.hudW, "Variables")
        y += 32
        
        if State.sectionStates["variables"] {
            ; Centered variable inputs with full labels
            lblW := 340  ; Reduced by 40px for tighter spacing
            edtW := 80   ; Width for 5 characters
            totalW := lblW + edtW + 15
            x := (UI.hudW - totalW) // 2
            
            ; Highest mineral level input
            lbl := UI.gui.AddText(Format("x{} y{} w{} h30", x, y+4, lblW), "Highest mineral level:")
            UI.lblMineralLevel := lbl
            UI.sectionContents["variables"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h30 Center +Border", x + lblW + 15, y, edtW), State.mineralLevel)
            edt.SetFont("s11 c000000", "Cascadia Mono")
            UI.inputMineralLevel := edt
            UI.sectionContents["variables"].Push(edt)
            
            y += 38
            
            ; Merge wait time input
            lbl := UI.gui.AddText(Format("x{} y{} w{} h30", x, y+4, lblW), "Merge wait time (ms):")
            UI.lblMergeWait := lbl
            UI.sectionContents["variables"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h30 Center +Border", x + lblW + 15, y, edtW), State.mergeWaitTime)
            edt.SetFont("s11 c000000", "Cascadia Mono")
            UI.inputMergeWait := edt
            UI.sectionContents["variables"].Push(edt)
            
            y += 38
            
            ; Time warp interval input
            lbl := UI.gui.AddText(Format("x{} y{} w{} h30", x, y+4, lblW), "Time warp interval (ms):")
            UI.lblTimewarp := lbl
            UI.sectionContents["variables"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h30 Center +Border", x + lblW + 15, y, edtW), State.timewarpInterval)
            edt.SetFont("s11 c000000", "Cascadia Mono")
            UI.inputTimewarp := edt
            UI.sectionContents["variables"].Push(edt)
            
            y += 38
            
            ; Exploit wait time input
            lbl := UI.gui.AddText(Format("x{} y{} w{} h30", x, y+4, lblW), "Exploit wait time (ms):")
            UI.lblExploitWait := lbl
            UI.sectionContents["variables"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h30 Center +Border", x + lblW + 15, y, edtW), State.exploitWaitTime)
            edt.SetFont("s11 c000000", "Cascadia Mono")
            UI.inputExploitWait := edt
            UI.sectionContents["variables"].Push(edt)
            
            y += 38
            
            ; Delay between actions input
            lbl := UI.gui.AddText(Format("x{} y{} w{} h30", x, y+4, lblW), "Delay between actions (ms):")
            UI.lblMicroDelay := lbl
            UI.sectionContents["variables"].Push(lbl)
            
            edt := UI.gui.AddEdit(Format("x{} y{} w{} h30 Center +Border", x + lblW + 15, y, edtW), State.microDelayMs)
            edt.SetFont("s11 c000000", "Cascadia Mono")
            UI.inputMicroDelay := edt
            UI.sectionContents["variables"].Push(edt)
            
            y += 38 + pad
        }
        
        ; UNITY PARAMETERS SECTION
        UIManager.CreateSectionHeader("unityparameters", y, UI.hudW, "Unity Parameters")
        y += 32
        
        if State.sectionStates["unityparameters"] {
            ; Section label - centered
            lbl := UI.gui.AddText(Format("x{} y{} w{} h25 Center", pad, y, UI.hudW - 2*pad), "Select Zodiac Element:")
            lbl.SetFont("s11 cFFFFFF", "Cascadia Mono")
            UI.sectionContents["unityparameters"].Push(lbl)
            
            y += 30
            
            ; Zodiac buttons in a 2x2 grid
            btnW := 180  ; Button width for zodiac elements
            btnH := 34   ; Standard button height
            gap := 15
            startX := (UI.hudW - (2 * btnW + gap)) // 2
            
            ; Earth Zodiac
            btn := UIManager.CreateStyledButton(startX, y, btnW, btnH, "Earth Zodiac", State.zodiacEarth)
            UI.btnZodiacEarth := btn
            UI.sectionContents["unityparameters"].Push(btn)
            
            ; Fire Zodiac  
            btn := UIManager.CreateStyledButton(startX + btnW + gap, y, btnW, btnH, "Fire Zodiac", State.zodiacFire)
            UI.btnZodiacFire := btn
            UI.sectionContents["unityparameters"].Push(btn)
            
            y += btnH + 15
            
            ; Wind Zodiac
            btn := UIManager.CreateStyledButton(startX, y, btnW, btnH, "Wind Zodiac", State.zodiacWind)
            UI.btnZodiacWind := btn
            UI.sectionContents["unityparameters"].Push(btn)
            
            ; Water Zodiac
            btn := UIManager.CreateStyledButton(startX + btnW + gap, y, btnW, btnH, "Water Zodiac", State.zodiacWater)
            UI.btnZodiacWater := btn
            UI.sectionContents["unityparameters"].Push(btn)
            
            y += btnH + pad
        }
        
        ; STATISTICS SECTION
        UIManager.CreateSectionHeader("statistics", y, UI.hudW, "Game Statistics")
        y += 32
        
        if State.sectionStates["statistics"] {
            ; Preview image for screenshots
            previewW := UI.hudW - 2*pad
            rect := State.captureRect
            previewH := Max(20, Round(previewW * rect.h / Max(rect.w, 1)))
            pic := UI.gui.AddPicture(Format("x{} y{} w{} h{} +Border", pad, y, previewW, previewH), "")
            UI.imgPreview := pic
            UI.sectionContents["statistics"].Push(pic)
            
            y += previewH + gap
            
            ; Cycle count display
            lbl := UI.gui.AddText(Format("x{} y{} w{} h25", pad, y, UI.hudW - 2*pad), "Cycles: 0")
            lbl.SetFont("s10", "Cascadia Mono")
            UI.lblStatistics := lbl
            UI.sectionContents["statistics"].Push(lbl)
            
            y += 25
            
            ; Average cycle time display
            lbl := UI.gui.AddText(Format("x{} y{} w{} h25", pad, y, UI.hudW - 2*pad), 
                                         "Avg cycle: --:--:--:-")
            lbl.SetFont("s10", "Cascadia Mono")
            UI.lblCycleTime := lbl
            UI.sectionContents["statistics"].Push(lbl)
            
            y += 25 + pad
        }
        
        ; INFO SECTION
        UIManager.CreateSectionHeader("info", y, UI.hudW, "Info")
        y += 32
        
        if State.sectionStates["info"] {
            ; Hotkey information text
            infoText := "F5: Start/Stop`n"
                      . "F6: Cycle Macros`n"
                      . "F7: Cycle Game States`n"
                      . "F8: Toggle All Fine Settings`n"
                      . "F9: Toggle All Unlockables`n"
                      . "F10: Compact Mode`n"
                      . "Esc: Exit"
            
            lbl := UI.gui.AddText(Format("x{} y{} w{} h200", pad, y, UI.hudW - 2*pad), infoText)
            lbl.SetFont("s10", "Cascadia Mono")
            UI.lblInfo := lbl
            UI.sectionContents["info"].Push(lbl)
            
            y += 200 + 10
            
            ; Credit line - right aligned
            creditLbl := UI.gui.AddText(Format("x{} y{} w{} h25 Right", pad, y, UI.hudW - 2*pad), "Script by GullibleMonkey")
            creditLbl.SetFont("s10", "Cascadia Mono")
            UI.sectionContents["info"].Push(creditLbl)
            
            y += 25 + pad
        }
        
        ; Show window at saved position with extra margin
        totalH := y + 10  ; Minimal bottom margin
        ini := Config.CONFIG_FILE
        hx := IniRead(ini, "UI", "X", 100)
        hy := IniRead(ini, "UI", "Y", 100)
        UI.gui.Show(Format("x{} y{} w{} h{} NoActivate", hx, hy, UI.hudW, totalH))
    }
    
    ; Create a styled button
    static CreateStyledButton(x, y, w, h, text, isActive) {
        ; Create text control styled as button
        btn := UI.gui.AddText(Format("x{} y{} w{} h{} Center +Border", x, y, w, h), text)
        
        ; Store button state
        UI.buttonStates[btn.Hwnd] := isActive
        
        ; Apply appropriate colors
        UIManager.UpdateButtonStyle(btn, isActive)
        
        return btn
    }
    
    ; Create a collapsible section header with decorative lines
    static CreateSectionHeader(section, y, hudW, title) {
        ; Add arrow indicator based on state
        arrow := State.sectionStates[section] ? "▼" : "►"
        fullTitle := "--- " arrow " " title " ---"
        
        ; Create clickable header
        header := UI.gui.AddText(Format("x16 y{} w{} h30 Center", y, hudW - 32), fullTitle)
        header.SetFont("s10 cFFFFFF", "Cascadia Mono")
        UI.sectionHeaders[section] := header
    }
    
    ; Create compact mode GUI (small window with eye icon)
    static CreateCompactGUI() {
        ; Create small window with white background (square matching header height)
        UI.compactGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +Border")
        UI.compactGui.BackColor := "FFFFFF"  ; White background
        UI.compactGui.MarginX := 0
        UI.compactGui.MarginY := 0
        
        ; Add eye icon (black on white) - centered in square
        iconSize := UI.hdrH
        eyeY := (iconSize - 24) // 2  ; Center the icon vertically
        eye := UI.compactGui.AddText(Format("x0 y{} w{} h24 Center +BackgroundFFFFFF", eyeY, iconSize), "👁")
        eye.SetFont("s9 c000000", "Segoe UI Emoji")  ; Same size as header icon
        eye.OnEvent("Click", (*) => UIManager.ToggleCompact())
        
        ; Position near original window with fallback
        x := 100
        y := 100
        if UI.gui && IsObject(UI.gui) {
            try {
                WinGetPos &x, &y, , , "ahk_id " UI.gui.Hwnd
            } catch {
                x := 100
                y := 100
            }
        }
        UI.compactGui.Show(Format("x{} y{} w{} h{} NoActivate", x, y, iconSize, iconSize))
    }
    
    ; Toggle between normal and compact mode
    static ToggleCompact() {
        if UI.isCompact {
            ; Restore from compact mode
            x := 100
            y := 100
            if UI.compactGui && IsObject(UI.compactGui) {
                try {
                    WinGetPos &x, &y, , , "ahk_id " UI.compactGui.Hwnd
                } catch {
                    x := 100
                    y := 100
                }
                UI.compactGui.Destroy()
                UI.compactGui := 0
            }
            
            UI.isCompact := false
            UI.isVisible := true
            
            ; Show main GUI
            if UI.gui && IsObject(UI.gui) {
                UI.gui.Show("NoActivate")
                WinMove x, y, , , "ahk_id " UI.gui.Hwnd
            } else {
                UIManager.Initialize()
                if UI.gui && IsObject(UI.gui) {
                    WinMove x, y, , , "ahk_id " UI.gui.Hwnd
                }
            }
        } else {
            ; Enter compact mode
            x := 100
            y := 100
            if UI.gui && IsObject(UI.gui) {
                try {
                    WinGetPos &x, &y, , , "ahk_id " UI.gui.Hwnd
                } catch {
                    x := 100
                    y := 100
                }
                UI.gui.Hide()
            }
            
            UI.isCompact := true
            UI.isVisible := false
            UIManager.CreateCompactGUI()
            
            if UI.compactGui
                WinMove x, y, , , "ahk_id " UI.compactGui.Hwnd
        }
        
        Util.FocusGame()
    }
    
    ; Setup event handlers for all controls
    static SetupEventHandlers() {
        ; Setup drag handler once
        if !UIManager.messagesSetup {
            OnMessage(0x201, ObjBindMethod(UIManager, "OnDrag"))
            UIManager.messagesSetup := true
        }
        
        ; Header controls - always check if exists
        if UI.btnEye && IsObject(UI.btnEye)
            UI.btnEye.OnEvent("Click", (*) => UIManager.ToggleCompact())
        if UI.btnClose && IsObject(UI.btnClose)
            UI.btnClose.OnEvent("Click", (*) => ExitApp())
        
        ; Section headers (collapsible)
        for key, header in UI.sectionHeaders {
            localSection := key
            if header && IsObject(header) {
                header.OnEvent("Click", UIManager.ToggleSection.Bind(, localSection))
            }
        }
        
        ; Main button
        if UI.btnStartStop && IsObject(UI.btnStartStop)
            UI.btnStartStop.OnEvent("Click", (*) => Controller.ToggleStart())
        
        ; Macro selection buttons - check existence before adding handler
        if UI.btnMacroStandard && IsObject(UI.btnMacroStandard) {
            try UI.btnMacroStandard.OnEvent("Click", (*) => Controller.SelectMacro("standard"))
        }
        if UI.btnMacroQuick && IsObject(UI.btnMacroQuick) {
            try UI.btnMacroQuick.OnEvent("Click", (*) => Controller.SelectMacro("quick"))
        }
        if UI.btnMacroLong && IsObject(UI.btnMacroLong) {
            try UI.btnMacroLong.OnEvent("Click", (*) => Controller.SelectMacro("long"))
        }
        if UI.btnMacroEndgame && IsObject(UI.btnMacroEndgame) {
            try UI.btnMacroEndgame.OnEvent("Click", (*) => Controller.SelectMacro("endgame"))
        }
        if UI.btnMacroTimeWarp && IsObject(UI.btnMacroTimeWarp) {
            try UI.btnMacroTimeWarp.OnEvent("Click", (*) => Controller.SelectMacro("timewarp"))
        }
        if UI.btnMacroAutoClicker && IsObject(UI.btnMacroAutoClicker) {
            try UI.btnMacroAutoClicker.OnEvent("Click", (*) => Controller.SelectMacro("autoclicker"))
        }
        if UI.btnMacroTimeFluxBuy && IsObject(UI.btnMacroTimeFluxBuy) {
            try UI.btnMacroTimeFluxBuy.OnEvent("Click", (*) => Controller.SelectMacro("timefluxbuy"))
        }
        if UI.btnMacroAutoUnity && IsObject(UI.btnMacroAutoUnity) {
            try UI.btnMacroAutoUnity.OnEvent("Click", (*) => Controller.SelectMacro("autounity"))
        }
        
        ; Game state buttons
        if UI.btnStateEarly && IsObject(UI.btnStateEarly) {
            try UI.btnStateEarly.OnEvent("Click", (*) => Controller.SelectGameState("early"))
        }
        if UI.btnStateMid && IsObject(UI.btnStateMid) {
            try UI.btnStateMid.OnEvent("Click", (*) => Controller.SelectGameState("mid"))
        }
        if UI.btnStateLate && IsObject(UI.btnStateLate) {
            try UI.btnStateLate.OnEvent("Click", (*) => Controller.SelectGameState("late"))
        }
        if UI.btnStateCustom && IsObject(UI.btnStateCustom) {
            try UI.btnStateCustom.OnEvent("Click", (*) => Controller.SelectGameState("custom"))
        }
        
        ; Fine Settings buttons
        if UI.btnToggleRefining && IsObject(UI.btnToggleRefining) {
            try UI.btnToggleRefining.OnEvent("Click", (*) => Controller.ToggleRefining())
        }
        if UI.btnToggleRftUpgrade && IsObject(UI.btnToggleRftUpgrade) {
            try UI.btnToggleRftUpgrade.OnEvent("Click", (*) => Controller.ToggleRftUpgrade())
        }
        if UI.btnTogglePolishMode && IsObject(UI.btnTogglePolishMode) {
            try UI.btnTogglePolishMode.OnEvent("Click", (*) => Controller.TogglePolishMode())
        }
        
        ; Automation Unlockables buttons
        if UI.btnToggleAutospawn && IsObject(UI.btnToggleAutospawn) {
            try UI.btnToggleAutospawn.OnEvent("Click", (*) => Controller.ToggleAutospawn())
        }
        if UI.btnToggleAutomerge && IsObject(UI.btnToggleAutomerge) {
            try UI.btnToggleAutomerge.OnEvent("Click", (*) => Controller.ToggleAutomerge())
        }
        if UI.btnToggleAutoMaxLevel && IsObject(UI.btnToggleAutoMaxLevel) {
            try UI.btnToggleAutoMaxLevel.OnEvent("Click", (*) => Controller.ToggleAutoMaxLevel())
        }
        if UI.btnToggleAutoWeaponPolish && IsObject(UI.btnToggleAutoWeaponPolish) {
            try UI.btnToggleAutoWeaponPolish.OnEvent("Click", (*) => Controller.ToggleAutoWeaponPolish())
        }
        
        ; Unity Parameters buttons
        if UI.btnZodiacEarth && IsObject(UI.btnZodiacEarth) {
            try UI.btnZodiacEarth.OnEvent("Click", (*) => Controller.ToggleZodiacEarth())
        }
        if UI.btnZodiacFire && IsObject(UI.btnZodiacFire) {
            try UI.btnZodiacFire.OnEvent("Click", (*) => Controller.ToggleZodiacFire())
        }
        if UI.btnZodiacWind && IsObject(UI.btnZodiacWind) {
            try UI.btnZodiacWind.OnEvent("Click", (*) => Controller.ToggleZodiacWind())
        }
        if UI.btnZodiacWater && IsObject(UI.btnZodiacWater) {
            try UI.btnZodiacWater.OnEvent("Click", (*) => Controller.ToggleZodiacWater())
        }
        
        ; Input field change handlers
        if UI.inputMineralLevel && IsObject(UI.inputMineralLevel) {
            try UI.inputMineralLevel.OnEvent("Change", (*) => Controller.UpdateMineralLevel())
            try UI.inputMineralLevel.OnEvent("LoseFocus", (*) => Controller.ValidateMineralLevel())
        }
        if UI.inputMergeWait && IsObject(UI.inputMergeWait) {
            try UI.inputMergeWait.OnEvent("Change", (*) => Controller.UpdateMergeWait())
            try UI.inputMergeWait.OnEvent("LoseFocus", (*) => Controller.ValidateMergeWait())
        }
        if UI.inputMicroDelay && IsObject(UI.inputMicroDelay) {
            try UI.inputMicroDelay.OnEvent("Change", (*) => Controller.UpdateMicroDelay())
            try UI.inputMicroDelay.OnEvent("LoseFocus", (*) => Controller.ValidateMicroDelay())
        }
        if UI.inputTimewarp && IsObject(UI.inputTimewarp) {
            try UI.inputTimewarp.OnEvent("Change", (*) => Controller.UpdateTimewarp())
            try UI.inputTimewarp.OnEvent("LoseFocus", (*) => Controller.ValidateTimewarp())
        }
        if UI.inputExploitWait && IsObject(UI.inputExploitWait) {
            try UI.inputExploitWait.OnEvent("Change", (*) => Controller.UpdateExploitWait())
            try UI.inputExploitWait.OnEvent("LoseFocus", (*) => Controller.ValidateExploitWait())
        }
        if UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn) {
            try UI.inputCustomSpawn.OnEvent("Change", (*) => Controller.UpdateCustomSpawn())
            try UI.inputCustomSpawn.OnEvent("LoseFocus", (*) => Controller.ValidateCustomSpawn())
        }
        if UI.inputCustomPolish && IsObject(UI.inputCustomPolish) {
            try UI.inputCustomPolish.OnEvent("Change", (*) => Controller.UpdateCustomPolish())
            try UI.inputCustomPolish.OnEvent("LoseFocus", (*) => Controller.ValidateCustomPolish())
        }
    }
    
    ; Toggle a collapsible section
    static ToggleSection(section, *) {
        ; Update section state
        State.sectionStates[section] := !State.sectionStates[section]
        ConfigManager.Save()
        
        ; Save current position
        x := 100
        y := 100
        if UI.gui && IsObject(UI.gui) {
            try {
                WinGetPos &x, &y, , , "ahk_id " UI.gui.Hwnd
            } catch {
                x := 100
                y := 100
            }
        }
        
        ; Destroy and recreate GUI
        if UI.gui && IsObject(UI.gui) {
            UI.gui.Destroy()
            UI.gui := 0
        }
        
        ; Reset all control references
        UI.sectionContents.Clear()
        UI.sectionHeaders.Clear()
        UI.buttonStates.Clear()
        
        ; Recreate GUI with updated layout
        UIManager.CreateGUI()
        UIManager.SetupEventHandlers()
        UIManager.UpdateVisuals()
        
        ; Restore position
        if UI.gui && IsObject(UI.gui) {
            WinMove x, y, , , "ahk_id " UI.gui.Hwnd
        }
    }
    
    ; Update UI elements periodically
    static Update() {
        if !UI.gui || !IsObject(UI.gui)
            return
        
        ; Update start/stop button text and style
        on := State.isRunning || State.isStarting
        newText := on ? "F5: Stop macro" : "F5: Start macro"
        if UI.btnStartStop && IsObject(UI.btnStartStop) {
            try {
                if UI.btnStartStop.Text != newText {
                    UI.btnStartStop.Text := newText
                    UIManager.UpdateButtonStyle(UI.btnStartStop, on)
                }
            }
        }
        
        ; Update screenshot preview
        if UI.imgPreview && IsObject(UI.imgPreview) && State.lastScreenshotPath && FileExist(State.lastScreenshotPath) {
            try UI.imgPreview.Value := State.lastScreenshotPath
        }
        
        ; Update cycle statistics
        if UI.lblStatistics && IsObject(UI.lblStatistics) {
            try UI.lblStatistics.Text := Format("Cycles: {}", State.cycleCount)
        }
        
        ; Update average cycle time
        if UI.lblCycleTime && IsObject(UI.lblCycleTime) {
            try {
                if State.cycleTimes.Length > 0 {
                    totalTime := 0
                    for time in State.cycleTimes
                        totalTime += time
                    avgTime := totalTime / State.cycleTimes.Length
                    UI.lblCycleTime.Text := Format("Avg cycle: {}", Util.FormatTime(Round(avgTime)))
                } else {
                    UI.lblCycleTime.Text := "Avg cycle: --:--:--:-"
                }
            }
        }
        
        ; Update header animation when macro is running
        if State.isRunning {
            try {
                ; Hide normal header elements
                if UI.titleText
                    UI.titleText.Opt("+Hidden")
                if UI.btnEye
                    UI.btnEye.Opt("+Hidden")
                if UI.btnClose
                    UI.btnClose.Opt("+Hidden")
                    
                ; Show animated elements
                if UI.headerLeft
                    UI.headerLeft.Opt("-Hidden")
                if UI.headerRight
                    UI.headerRight.Opt("-Hidden")
                
                ; Update timer display
                elapsed := A_TickCount - State.startTime
                if UI.headerRight
                    UI.headerRight.Text := Util.FormatTime(elapsed)
                
                ; Animate "Running..." text
                phase := Mod((A_TickCount // 400), 5)
                dots := ""
                Loop phase
                    dots .= "."
                if UI.headerLeft
                    UI.headerLeft.Text := "Running" dots
            }
        } else {
            try {
                ; Hide animated elements
                if UI.headerLeft
                    UI.headerLeft.Opt("+Hidden")
                if UI.headerRight
                    UI.headerRight.Opt("+Hidden")
                    
                ; Show normal header elements
                if UI.titleText
                    UI.titleText.Opt("-Hidden")
                if UI.btnEye
                    UI.btnEye.Opt("-Hidden")
                if UI.btnClose
                    UI.btnClose.Opt("-Hidden")
            }
        }
    }
    
    ; Update button visual style
    static UpdateButtonStyle(btn, isActive) {
        if !btn || !IsObject(btn)
            return
        
        try {
            UI.buttonStates[btn.Hwnd] := isActive
            
            if isActive {
                ; Active button: white background, black text
                btn.Opt("+BackgroundFFFFFF")
                btn.SetFont("s10 c000000", "Cascadia Mono")
            } else {
                ; Inactive button: black background, white text
                btn.Opt("+Background000000")
                btn.SetFont("s10 cFFFFFF", "Cascadia Mono")
            }
        }
    }
    
    ; Update all button visuals based on current state
    static UpdateVisuals() {
        ; Update macro buttons
        if UI.btnMacroStandard && IsObject(UI.btnMacroStandard)
            UIManager.UpdateButtonStyle(UI.btnMacroStandard, State.currentMacro = "standard")
        if UI.btnMacroQuick && IsObject(UI.btnMacroQuick)
            UIManager.UpdateButtonStyle(UI.btnMacroQuick, State.currentMacro = "quick")
        if UI.btnMacroLong && IsObject(UI.btnMacroLong)
            UIManager.UpdateButtonStyle(UI.btnMacroLong, State.currentMacro = "long")
        if UI.btnMacroEndgame && IsObject(UI.btnMacroEndgame)
            UIManager.UpdateButtonStyle(UI.btnMacroEndgame, State.currentMacro = "endgame")
        if UI.btnMacroTimeWarp && IsObject(UI.btnMacroTimeWarp)
            UIManager.UpdateButtonStyle(UI.btnMacroTimeWarp, State.currentMacro = "timewarp")
        if UI.btnMacroAutoClicker && IsObject(UI.btnMacroAutoClicker)
            UIManager.UpdateButtonStyle(UI.btnMacroAutoClicker, State.currentMacro = "autoclicker")
        if UI.btnMacroTimeFluxBuy && IsObject(UI.btnMacroTimeFluxBuy)
            UIManager.UpdateButtonStyle(UI.btnMacroTimeFluxBuy, State.currentMacro = "timefluxbuy")
        if UI.btnMacroAutoUnity && IsObject(UI.btnMacroAutoUnity)
            UIManager.UpdateButtonStyle(UI.btnMacroAutoUnity, State.currentMacro = "autounity")
        
        ; Update game state buttons and inputs
        if UI.btnStateEarly && IsObject(UI.btnStateEarly)
            UIManager.UpdateButtonStyle(UI.btnStateEarly, State.gameState = "early")
        if UI.btnStateMid && IsObject(UI.btnStateMid)
            UIManager.UpdateButtonStyle(UI.btnStateMid, State.gameState = "mid")
        if UI.btnStateLate && IsObject(UI.btnStateLate)
            UIManager.UpdateButtonStyle(UI.btnStateLate, State.gameState = "late")
        if UI.btnStateCustom && IsObject(UI.btnStateCustom)
            UIManager.UpdateButtonStyle(UI.btnStateCustom, State.gameState = "custom")
        
        ; Update custom spawn/polish inputs based on game state
        if UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn) {
            switch State.gameState {
                case "early":
                    try UI.inputCustomSpawn.Text := "7"
                case "mid":
                    try UI.inputCustomSpawn.Text := "5"
                case "late":
                    try UI.inputCustomSpawn.Text := "4"
            }
        }
        if UI.inputCustomPolish && IsObject(UI.inputCustomPolish) {
            switch State.gameState {
                case "early":
                    try UI.inputCustomPolish.Text := "3"
                case "mid":
                    try UI.inputCustomPolish.Text := "2"
                case "late":
                    try UI.inputCustomPolish.Text := "1"
            }
        }
        
        ; Update Fine Settings buttons
        if UI.btnToggleRefining && IsObject(UI.btnToggleRefining)
            UIManager.UpdateButtonStyle(UI.btnToggleRefining, State.autoRefining)
        if UI.btnToggleRftUpgrade && IsObject(UI.btnToggleRftUpgrade)
            UIManager.UpdateButtonStyle(UI.btnToggleRftUpgrade, State.autoRftUpgrade)
        if UI.btnTogglePolishMode && IsObject(UI.btnTogglePolishMode)
            UIManager.UpdateButtonStyle(UI.btnTogglePolishMode, State.allWeaponsPolish)
        
        ; Update Automation Unlockables buttons
        if UI.btnToggleAutospawn && IsObject(UI.btnToggleAutospawn)
            UIManager.UpdateButtonStyle(UI.btnToggleAutospawn, State.autospawnUnlocked)
        if UI.btnToggleAutomerge && IsObject(UI.btnToggleAutomerge)
            UIManager.UpdateButtonStyle(UI.btnToggleAutomerge, State.automergeUnlocked)
        if UI.btnToggleAutoMaxLevel && IsObject(UI.btnToggleAutoMaxLevel)
            UIManager.UpdateButtonStyle(UI.btnToggleAutoMaxLevel, State.autoMaxLevelUnlocked)
        if UI.btnToggleAutoWeaponPolish && IsObject(UI.btnToggleAutoWeaponPolish)
            UIManager.UpdateButtonStyle(UI.btnToggleAutoWeaponPolish, State.autoWeaponPolishUnlocked)
            
        ; Update Unity Parameters buttons
        if UI.btnZodiacEarth && IsObject(UI.btnZodiacEarth)
            UIManager.UpdateButtonStyle(UI.btnZodiacEarth, State.zodiacEarth)
        if UI.btnZodiacFire && IsObject(UI.btnZodiacFire)
            UIManager.UpdateButtonStyle(UI.btnZodiacFire, State.zodiacFire)
        if UI.btnZodiacWind && IsObject(UI.btnZodiacWind)
            UIManager.UpdateButtonStyle(UI.btnZodiacWind, State.zodiacWind)
        if UI.btnZodiacWater && IsObject(UI.btnZodiacWater)
            UIManager.UpdateButtonStyle(UI.btnZodiacWater, State.zodiacWater)
    }
    
    ; Handle window dragging
    static OnDrag(wParam, lParam, msg, hwnd) {
        if !UI.gui || !IsObject(UI.gui) || State.isRunning
            return
        
        ; Check if clicking on compact window
        if UI.isCompact && UI.compactGui && IsObject(UI.compactGui) {
            if hwnd = UI.compactGui.Hwnd {
                PostMessage 0xA1, 2, 0,, "ahk_id " UI.compactGui.Hwnd
                return
            }
        }
        
        ; Check if clicking on main window
        try {
            root := DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
            if root != UI.gui.Hwnd
                return
        } catch {
            return
        }
        
        ; Don't drag if clicking on interactive controls
        for section, header in UI.sectionHeaders {
            if header && IsObject(header) && hwnd = header.Hwnd
                return
        }
        
        ; Check all buttons - only check if they exist
        buttons := []
        
        ; Add buttons only if they exist
        if UI.btnEye && IsObject(UI.btnEye)
            buttons.Push(UI.btnEye)
        if UI.btnClose && IsObject(UI.btnClose)
            buttons.Push(UI.btnClose)
        if UI.btnStartStop && IsObject(UI.btnStartStop)
            buttons.Push(UI.btnStartStop)
            
        ; Check controls from all sections
        for section, controls in UI.sectionContents {
            for ctrl in controls {
                try {
                    if IsObject(ctrl) && ctrl.Hwnd && hwnd = ctrl.Hwnd
                        return
                } catch {
                    ; Control might be destroyed, continue
                }
            }
        }
        
        for btn in buttons {
            try {
                if IsObject(btn) && btn.Hwnd && hwnd = btn.Hwnd
                    return
            } catch {
                ; Control might be destroyed, continue
            }
        }
        
        ; Check input fields
        inputs := []
        if UI.inputMineralLevel && IsObject(UI.inputMineralLevel)
            inputs.Push(UI.inputMineralLevel)
        if UI.inputMergeWait && IsObject(UI.inputMergeWait)
            inputs.Push(UI.inputMergeWait)
        if UI.inputMicroDelay && IsObject(UI.inputMicroDelay)
            inputs.Push(UI.inputMicroDelay)
        if UI.inputTimewarp && IsObject(UI.inputTimewarp)
            inputs.Push(UI.inputTimewarp)
        if UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn)
            inputs.Push(UI.inputCustomSpawn)
        if UI.inputCustomPolish && IsObject(UI.inputCustomPolish)
            inputs.Push(UI.inputCustomPolish)
            
        for input in inputs {
            try {
                if IsObject(input) && input.Hwnd && hwnd = input.Hwnd
                    return
            } catch {
                ; Control might be destroyed, continue
            }
        }
        
        ; Allow dragging the window
        try {
            PostMessage 0xA1, 2, 0,, "ahk_id " UI.gui.Hwnd
        }
    }
}

; ================================================================================
; MAIN CONTROLLER
; ================================================================================

class Controller {
    ; Toggle macro start/stop
    static ToggleStart() {
        if State.isRunning {
            Controller.Stop()
        } else if !State.isStopping && !State.isLocked {
            Controller.Start()
        }
    }
    
    ; Start the macro
    static Start() {
        UIManager.Initialize()
        Screenshot.InitGDI()
        
        if State.isRunning || State.isLocked
            return
        
        ; Check if game is running
        if !WinExist("ahk_exe " Config.TARGET_PROCESS) {
            ToolTip "Target process not found: " Config.TARGET_PROCESS, 10, 10
            SetTimer(() => ToolTip(), -1500)
            return
        }
        
        ; Reset statistics
        State.cycleTimes := []
        State.lastCycleEnd := A_TickCount
        
        ; Focus game and start macro
        Util.FocusGame(true)
        Controller.RunMacro()
    }
    
    ; Stop the macro
    static Stop() {
        if State.isStopping
            return
        
        State.isStopping := true
        State.isRunning := false
        State.isStarting := false
        UIManager.Update()
        SetTimer(() => Controller.WaitStop(), -10)
    }
    
    ; Wait for macro to fully stop (reduced wait time)
    static WaitStop() {
        t0 := A_TickCount
        while State.isLocked && (A_TickCount - t0 < 300)  ; Reduced from 5000 to 300ms
            Sleep 10
        State.isLocked := false
        State.isStopping := false
        State.isStarting := false
        
        ; Restore window properties
        try {
            if UI.gui && IsObject(UI.gui) {
                WinSetExStyle("-0x80020", "ahk_id " UI.gui.Hwnd)
                WinSetTransparent("Off", "ahk_id " UI.gui.Hwnd)
            }
        }
        
        UIManager.Update()
    }
    
    ; Main macro execution loop
    static RunMacro() {
        State.isRunning := true
        State.isLocked := true
        State.cycleCount := 0
        State.startTime := A_TickCount
        
        UIManager.Update()
        
        ; Make window click-through during macro
        try {
            if UI.gui && IsObject(UI.gui) {
                WinSetExStyle("+0x80020", "ahk_id " UI.gui.Hwnd)
                WinSetTransparent(180, "ahk_id " UI.gui.Hwnd)
            }
        }
        
        try {
            ; Main macro loop
            while State.isRunning {
                if Util.IsGameBlocked() {
                    Util.Sleep(80)
                    continue
                }
                
                ; Execute selected macro
                switch State.currentMacro {
                    case "quick":
                        Macro.Quick()
                    case "long":
                        Macro.Long()
                    case "endgame":
                        Macro.Endgame()
                    case "timewarp":
                        Macro.TimeWarp()
                    case "autoclicker":
                        Macro.AutoClicker()
                    case "timefluxbuy":
                        Macro.TimeFluxBuy()
                    case "autounity":
                        Macro.AutoUnity()
                    default:
                        Macro.Standard()
                }
            }
        } finally {
            ; Restore window properties
            try {
                if UI.gui && IsObject(UI.gui) {
                    WinSetExStyle("-0x80020", "ahk_id " UI.gui.Hwnd)
                    WinSetTransparent("Off", "ahk_id " UI.gui.Hwnd)
                }
            }
            State.isLocked := false
            UIManager.Update()
        }
    }
    
    ; Select a macro type
    static SelectMacro(macro) {
        State.currentMacro := macro
        ConfigManager.Save()
        UIManager.UpdateVisuals()
        UIManager.Update()
        Util.FocusGame()
    }
    
    ; Cycle through macro types
    static CycleMacro() {
        macros := ["standard", "quick", "long", "timewarp", "autoclicker", "endgame", "timefluxbuy", "autounity"]
        currentIndex := 1
        for i, m in macros {
            if m = State.currentMacro {
                currentIndex := i
                break
            }
        }
        nextIndex := currentIndex = 6 ? 1 : currentIndex + 1
        Controller.SelectMacro(macros[nextIndex])
    }
    
    ; Select game state
    static SelectGameState(gameState) {
        State.gameState := gameState
        ConfigManager.Save()
        UIManager.UpdateVisuals()
        UIManager.Update()
        Util.FocusGame()
    }
    
    ; Cycle through game states
    static CycleGameState() {
        states := ["early", "mid", "late", "custom"]
        currentIndex := 1
        for i, s in states {
            if s = State.gameState {
                currentIndex := i
                break
            }
        }
        nextIndex := currentIndex = 4 ? 1 : currentIndex + 1
        Controller.SelectGameState(states[nextIndex])
    }
    
    ; Toggle all Fine Settings at once
    static ToggleAllFineSettings() {
        ; If any are disabled, enable all; otherwise disable all
        anyDisabled := !State.autoRefining || !State.autoRftUpgrade || !State.allWeaponsPolish
        
        State.autoRefining := anyDisabled
        State.autoRftUpgrade := anyDisabled
        State.allWeaponsPolish := anyDisabled
        
        ; Update UI
        if UI.btnToggleRefining && IsObject(UI.btnToggleRefining) {
            UI.btnToggleRefining.Text := State.autoRefining ? "Auto Refining" : "No Refining"
            UIManager.UpdateButtonStyle(UI.btnToggleRefining, State.autoRefining)
        }
        if UI.btnToggleRftUpgrade && IsObject(UI.btnToggleRftUpgrade) {
            UI.btnToggleRftUpgrade.Text := State.autoRftUpgrade ? "Auto RfT Upg" : "No RfT Upg"
            UIManager.UpdateButtonStyle(UI.btnToggleRftUpgrade, State.autoRftUpgrade)
        }
        if UI.btnTogglePolishMode && IsObject(UI.btnTogglePolishMode) {
            UI.btnTogglePolishMode.Text := State.allWeaponsPolish ? "All Weapons Polish" : "Sword Polish Only"
            UIManager.UpdateButtonStyle(UI.btnTogglePolishMode, State.allWeaponsPolish)
        }
        
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    ; Toggle all Automation Unlockables at once
    static ToggleAllUnlockables() {
        ; If any are locked, unlock all; otherwise lock all
        anyLocked := !State.autospawnUnlocked || !State.automergeUnlocked || 
                    !State.autoMaxLevelUnlocked || !State.autoWeaponPolishUnlocked
        
        State.autospawnUnlocked := anyLocked
        State.automergeUnlocked := anyLocked
        State.autoMaxLevelUnlocked := anyLocked
        State.autoWeaponPolishUnlocked := anyLocked
        
        ; Update UI
        if UI.btnToggleAutospawn && IsObject(UI.btnToggleAutospawn) {
            UI.btnToggleAutospawn.Text := State.autospawnUnlocked ? "Autospawn UNLOCKED" : "Autospawn LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutospawn, State.autospawnUnlocked)
        }
        if UI.btnToggleAutomerge && IsObject(UI.btnToggleAutomerge) {
            UI.btnToggleAutomerge.Text := State.automergeUnlocked ? "Automerge UNLOCKED" : "Automerge LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutomerge, State.automergeUnlocked)
        }
        if UI.btnToggleAutoMaxLevel && IsObject(UI.btnToggleAutoMaxLevel) {
            UI.btnToggleAutoMaxLevel.Text := State.autoMaxLevelUnlocked ? "Auto Max Lvl UNLOCKED" : "Auto Max Lvl LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutoMaxLevel, State.autoMaxLevelUnlocked)
        }
        if UI.btnToggleAutoWeaponPolish && IsObject(UI.btnToggleAutoWeaponPolish) {
            UI.btnToggleAutoWeaponPolish.Text := State.autoWeaponPolishUnlocked ? "Auto Wpn Polish UNLOCKED" : "Auto Wpn Polish LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutoWeaponPolish, State.autoWeaponPolishUnlocked)
        }
        
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    ; Update functions for input fields
    static UpdateMineralLevel() {
        if UI.inputMineralLevel && IsObject(UI.inputMineralLevel) {
            newVal := UI.inputMineralLevel.Text
            if newVal != State.mineralLevel {
                State.mineralLevel := newVal
                ConfigManager.Save()
            }
        }
    }
    
    static UpdateMergeWait() {
        if UI.inputMergeWait && IsObject(UI.inputMergeWait) {
            newVal := UI.inputMergeWait.Text
            if newVal != State.mergeWaitTime {
                State.mergeWaitTime := newVal
                ConfigManager.Save()
            }
        }
    }
    
    static UpdateMicroDelay() {
        if UI.inputMicroDelay && IsObject(UI.inputMicroDelay) {
            newVal := UI.inputMicroDelay.Text
            if RegExMatch(newVal, "^\d+$") {
                numVal := newVal + 0
                if numVal > 0 && numVal != State.microDelayMs {
                    State.microDelayMs := numVal
                    ConfigManager.Save()
                }
            }
        }
    }
    
    static UpdateTimewarp() {
        if UI.inputTimewarp && IsObject(UI.inputTimewarp) {
            newVal := UI.inputTimewarp.Text
            if newVal != State.timewarpInterval {
                State.timewarpInterval := newVal
                ConfigManager.Save()
            }
        }
    }
    
    static UpdateExploitWait() {
        if UI.inputExploitWait && IsObject(UI.inputExploitWait) {
            newVal := UI.inputExploitWait.Text
            if newVal != State.exploitWaitTime {
                State.exploitWaitTime := newVal
                ConfigManager.Save()
            }
        }
    }
    
    static UpdateCustomSpawn() {
        if UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn) {
            newVal := UI.inputCustomSpawn.Text
            if newVal != State.customSpawnReps && newVal != "" {
                State.customSpawnReps := newVal
                
                ; Auto-select custom state if values don't match preset states
                ; Only process if values are numeric
                if (RegExMatch(newVal, "^\d+$") && UI.inputCustomPolish && IsObject(UI.inputCustomPolish) && RegExMatch(UI.inputCustomPolish.Text, "^\d+$")) {
                    spawn := newVal + 0
                    polish := UI.inputCustomPolish.Text + 0
                    
                    if !((spawn = 7 && polish = 3) || (spawn = 5 && polish = 2) || (spawn = 4 && polish = 1)) {
                        State.gameState := "custom"
                        UIManager.UpdateVisuals()
                    }
                }
                
                ConfigManager.Save()
            }
        }
    }
    
    static UpdateCustomPolish() {
        if UI.inputCustomPolish && IsObject(UI.inputCustomPolish) {
            newVal := UI.inputCustomPolish.Text
            if newVal != State.customPolishReps && newVal != "" {
                State.customPolishReps := newVal
                
                ; Auto-select custom state if values don't match preset states
                ; Only process if values are numeric
                if (RegExMatch(newVal, "^\d+$") && UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn) && RegExMatch(UI.inputCustomSpawn.Text, "^\d+$")) {
                    spawn := UI.inputCustomSpawn.Text + 0
                    polish := newVal + 0
                    
                    if !((spawn = 7 && polish = 3) || (spawn = 5 && polish = 2) || (spawn = 4 && polish = 1)) {
                        State.gameState := "custom"
                        UIManager.UpdateVisuals()
                    }
                }
                
                ConfigManager.Save()
            }
        }
    }
    
    ; Validation functions to restore defaults if empty
    static ValidateMineralLevel() {
        if UI.inputMineralLevel && IsObject(UI.inputMineralLevel) {
            if UI.inputMineralLevel.Text = "" || !RegExMatch(UI.inputMineralLevel.Text, "^\d+$") {
                UI.inputMineralLevel.Text := "999"
                State.mineralLevel := "999"
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateMergeWait() {
        if UI.inputMergeWait && IsObject(UI.inputMergeWait) {
            if UI.inputMergeWait.Text = "" || !RegExMatch(UI.inputMergeWait.Text, "^\d+$") {
                UI.inputMergeWait.Text := "10000"
                State.mergeWaitTime := "10000"
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateMicroDelay() {
        if UI.inputMicroDelay && IsObject(UI.inputMicroDelay) {
            if UI.inputMicroDelay.Text = "" || !RegExMatch(UI.inputMicroDelay.Text, "^\d+$") {
                UI.inputMicroDelay.Text := "25"
                State.microDelayMs := 25
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateTimewarp() {
        if UI.inputTimewarp && IsObject(UI.inputTimewarp) {
            if UI.inputTimewarp.Text = "" || !RegExMatch(UI.inputTimewarp.Text, "^\d+$") {
                UI.inputTimewarp.Text := "10000"
                State.timewarpInterval := "10000"
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateExploitWait() {
        if UI.inputExploitWait && IsObject(UI.inputExploitWait) {
            if UI.inputExploitWait.Text = "" || !RegExMatch(UI.inputExploitWait.Text, "^\d+$") {
                UI.inputExploitWait.Text := "500"
                State.exploitWaitTime := "500"
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateCustomSpawn() {
        if UI.inputCustomSpawn && IsObject(UI.inputCustomSpawn) {
            if UI.inputCustomSpawn.Text = "" || !RegExMatch(UI.inputCustomSpawn.Text, "^\d+$") {
                UI.inputCustomSpawn.Text := "4"
                State.customSpawnReps := "4"
                ConfigManager.Save()
            }
        }
    }
    
    static ValidateCustomPolish() {
        if UI.inputCustomPolish && IsObject(UI.inputCustomPolish) {
            if UI.inputCustomPolish.Text = "" || !RegExMatch(UI.inputCustomPolish.Text, "^\d+$") {
                UI.inputCustomPolish.Text := "1"
                State.customPolishReps := "1"
                ConfigManager.Save()
            }
        }
    }
    
    ; Individual toggle functions for Fine Settings
    static ToggleRefining() {
        State.autoRefining := !State.autoRefining
        if UI.btnToggleRefining && IsObject(UI.btnToggleRefining) {
            UI.btnToggleRefining.Text := State.autoRefining ? "Auto Refining" : "No Refining"
            UIManager.UpdateButtonStyle(UI.btnToggleRefining, State.autoRefining)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleRftUpgrade() {
        State.autoRftUpgrade := !State.autoRftUpgrade
        if UI.btnToggleRftUpgrade && IsObject(UI.btnToggleRftUpgrade) {
            UI.btnToggleRftUpgrade.Text := State.autoRftUpgrade ? "Auto RfT Upg" : "No RfT Upg"
            UIManager.UpdateButtonStyle(UI.btnToggleRftUpgrade, State.autoRftUpgrade)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static TogglePolishMode() {
        State.allWeaponsPolish := !State.allWeaponsPolish
        if UI.btnTogglePolishMode && IsObject(UI.btnTogglePolishMode) {
            UI.btnTogglePolishMode.Text := State.allWeaponsPolish ? "All Weapons Polish" : "Sword Polish Only"
            UIManager.UpdateButtonStyle(UI.btnTogglePolishMode, State.allWeaponsPolish)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    ; Individual toggle functions for Automation Unlockables
    static ToggleAutospawn() {
        State.autospawnUnlocked := !State.autospawnUnlocked
        if UI.btnToggleAutospawn && IsObject(UI.btnToggleAutospawn) {
            UI.btnToggleAutospawn.Text := State.autospawnUnlocked ? "Autospawn UNLOCKED" : "Autospawn LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutospawn, State.autospawnUnlocked)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleAutomerge() {
        State.automergeUnlocked := !State.automergeUnlocked
        if UI.btnToggleAutomerge && IsObject(UI.btnToggleAutomerge) {
            UI.btnToggleAutomerge.Text := State.automergeUnlocked ? "Automerge UNLOCKED" : "Automerge LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutomerge, State.automergeUnlocked)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleAutoMaxLevel() {
        State.autoMaxLevelUnlocked := !State.autoMaxLevelUnlocked
        if UI.btnToggleAutoMaxLevel && IsObject(UI.btnToggleAutoMaxLevel) {
            UI.btnToggleAutoMaxLevel.Text := State.autoMaxLevelUnlocked ? "Auto Max Lvl UNLOCKED" : "Auto Max Lvl LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutoMaxLevel, State.autoMaxLevelUnlocked)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleAutoWeaponPolish() {
        State.autoWeaponPolishUnlocked := !State.autoWeaponPolishUnlocked
        if UI.btnToggleAutoWeaponPolish && IsObject(UI.btnToggleAutoWeaponPolish) {
            UI.btnToggleAutoWeaponPolish.Text := State.autoWeaponPolishUnlocked ? "Auto Wpn Polish UNLOCKED" : "Auto Wpn Polish LOCKED"
            UIManager.UpdateButtonStyle(UI.btnToggleAutoWeaponPolish, State.autoWeaponPolishUnlocked)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    ; Unity Parameters toggle functions
    static ToggleZodiacEarth() {
        State.zodiacEarth := !State.zodiacEarth
        if UI.btnZodiacEarth && IsObject(UI.btnZodiacEarth) {
            UIManager.UpdateButtonStyle(UI.btnZodiacEarth, State.zodiacEarth)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleZodiacFire() {
        State.zodiacFire := !State.zodiacFire
        if UI.btnZodiacFire && IsObject(UI.btnZodiacFire) {
            UIManager.UpdateButtonStyle(UI.btnZodiacFire, State.zodiacFire)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleZodiacWind() {
        State.zodiacWind := !State.zodiacWind
        if UI.btnZodiacWind && IsObject(UI.btnZodiacWind) {
            UIManager.UpdateButtonStyle(UI.btnZodiacWind, State.zodiacWind)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
    
    static ToggleZodiacWater() {
        State.zodiacWater := !State.zodiacWater
        if UI.btnZodiacWater && IsObject(UI.btnZodiacWater) {
            UIManager.UpdateButtonStyle(UI.btnZodiacWater, State.zodiacWater)
        }
        ConfigManager.Save()
        Util.FocusGame()
    }
}

; ================================================================================
; CLEANUP HANDLER
; ================================================================================

OnExit(CleanupAndExit)

CleanupAndExit(ExitReason, ExitCode) {
    try {
        State.isLocked := false
        ConfigManager.Save()
        
        ; Destroy compact GUI if exists
        if UI.compactGui && IsObject(UI.compactGui) {
            UI.compactGui.Destroy()
        }
        
        ; Shutdown GDI+ if initialized
        if UI.gdiToken {
            DllCall("gdiplus\GdiplusShutdown", "ptr", UI.gdiToken)
            UI.gdiToken := 0
        }
    }
}

; ================================================================================
; HOTKEYS
; ================================================================================

$F5::Controller.ToggleStart()           ; Start/stop macro
$F6::Controller.CycleMacro()            ; Cycle through macro types
$F7::Controller.CycleGameState()        ; Cycle through game states
$F8::Controller.ToggleAllFineSettings() ; Toggle all Fine Settings
$F9::Controller.ToggleAllUnlockables()  ; Toggle all Automation Unlockables
F10::UIManager.ToggleCompact()          ; Toggle compact mode
$Esc::ExitApp                           ; Exit the script

; ================================================================================
; INITIALIZATION
; ================================================================================

UIManager.Initialize()
Screenshot.InitGDI()

; ================================================================================
; END OF SCRIPT
; ================================================================================
