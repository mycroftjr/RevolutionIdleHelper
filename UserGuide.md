# 🤖 Revolution Idle Helper v1.2 - Complete Automation Suite

Since my last post, I've added major features and QoL improvements to the script. This is a comprehensive technical guide covering all functionality.

## 🆕 What's New in v1.2

- **🎯 Visual Coordinate Picker**: Click-to-capture system eliminates manual coordinate editing
- **📋 Hierarchical GUI**: Collapsible sections with proper organization
- **⚡ New Macros**: Unity Helper, Zodiac Redistribution, Time Warp Burst

---

## 💾 Installation & Setup

### 📋 Requirements
- Windows 10+ 
- AutoHotkey v2.0+ ([Download](https://www.autohotkey.com/))
- Revolution Idle running in windowed mode
- Minimum 1920x1080 resolution recommended

### 🚀 Quick Start
1. Install AutoHotkey v2
2. Download `RevolutionIdleHelper_v1.2.ahk` → [Github Link](https://github.com/GullibleMonkey/RevolutionIdleHelper/blob/main/RevolutionIdleHelper_v1.2.ahk)
3. Launch script → GUI appears at (12, 51)
4. Configure coordinates: Other Tools > Coordinate Settings > Double-click coordinate > Click game element
5. Select macro and press F5

### 🎮 Basic Controls
| Hotkey | Function |
|--------|----------|
| **F5** | Start/stop current macro |
| **F10** | Minimize to eye icon |
| **Esc** | Exit application / Cancel coordinate picker |

---

## 🏗️ Core System Architecture

### 📍 Coordinate System
The script uses **screen coordinates only** - no game memory modification or value reading. It controls mouse/keyboard input exclusively.

**Setup Process (v1.2):**
- Navigate to Other Tools > Coordinate Settings
- List displays all required coordinates with descriptions
- Double-click any coordinate to enter picker mode
- Click corresponding game element
- Coordinate automatically saves to INI file

**Important**: Coordinates vary by screen/game resolution. Default coordinates likely won't work for your setup.

### ⚙️ Configuration Management
- **Auto-saves** every 10 seconds during operation
- **INI Structure**: `[Settings]`, `[FineSettings]`, `[Unlockables]`, `[UnityParameters]`, `[Coordinates]`, `[Sections]`
- **Validation**: Input validation with fallback to defaults
- **Persistence**: All GUI states and parameters saved on exit

---

## 💎 MINERALS & REFINING HELPER

### 🎯 Core Concept
Automates the mineral spawn → polish → merge → refine loop to optimize RfT (Refine Tree) point generation. Loop optimization depends heavily on progression stage.

### 🔄 Macro Types & Sequences

**Standard Macro**: `spawn → polish → long spawn → merge → refine`
- Balanced approach for general use
- Good default for most progression stages

**Quick Macro**: `spawn → polish → refine`
- Minimal delays, fastest cycles
- Often optimal based on testing across progression stages
- Best for active monitoring

**Long Macro**: `spawn → polish → spawn loop → merge → polish → spawn loop → merge → refine`
- Extended merge cycles for maximum mineral levels
- Higher RfT per cycle but longer duration

### 🎯 Game State Presets

Spawn/polish cycles are customizable based on progression. Rule of thumb: earlier progression needs more repetitions.

| State | Spawn Cycles | Polish Cycles | Description |
|-------|--------------|---------------|-------------|
| **Early** | 7 | 3 | Multiple spawns needed to reach affordable maximum |
| **Mid** | 5 | 2 | Moderate efficiency |
| **Late** | 4 | 1 | High efficiency, fewer cycles needed |
| **Custom** | User-defined | User-defined | Full customization |

**Spawn Cycle**: Number of highest mineral spawns before polishing. Early game requires multiple spawns to reach maximum affordable level.

**Polish Cycle**: Number of weapon polish rounds before final high-value loop and refining.

### ⚙️ Fine Settings Configuration

**Auto Refining** (On/Off):
- **On**: Macro completes full cycle including refining
- **Off**: Stops before refining (useful for VP pushing, Zodiac Value optimization)

**Auto RfT Upgrade** (On/Off):
- **On**: Automatically purchases currently selected RfT Node during long runs
- **Off**: No automatic purchasing
- **Limitation**: Cannot change which upgrade to buy - only purchases selected node

**Weapon Polish Mode**:
- **All Weapons**: Polishes all available weapons
- **Sword Only**: More efficient before auto-polish unlock or Node 23
- **Use Case**: Early game optimization when sword-only is faster

### 🔓 Automation Unlockables

Script adapts behavior based on your unlocked automations:

**Autospawn**:
- **Disabled**: Script manually clicks spawn buttons during merge loops
- **Enabled**: Script toggles autospawn on/off as needed

**Automerge**:
- **Disabled**: No mineral merging, merge cycles become extended spawn cycles
- **Enabled**: Uses automatic merging system

**Auto Max Level**:
- **Disabled**: Script manually buys "Max Level" upgrade
- **Enabled**: Script skips manual upgrade process
- **⚠️ Warning**: Once maxLevel coordinates are set, don't move VP upgrade window

**Auto Weapon Polish**:
- **Disabled**: Script clicks each weapon individually
- **Enabled**: Uses game's automatic polishing
- **⚠️ Warning**: All weapons must be visible when setting coordinates. May require window scrolling.

### 📊 Variables Configuration

**Highest Mineral Level**: 
- Default: 999 (highest unlocked)
- **Early Game**: Highest unlocked = highest affordable
- **Mid/Late Game**: Must manually set to highest *affordable* mineral

**Merge Wait Time**: 
- Millisecond delay during merge loops before merging and polishing
- Default: 5000ms
- **Optimization**: Adjust based on mineral merge speed

**Exploit Wait Time**: 
- Delay for Endgame Exploit timing (see Endgame Exploit section)

### 📊 Performance Monitoring

**Game Statistics Section**:
- **Screenshot Capture**: Real-time RfT points display (configurable area)
- **Cycle Count**: Number of completed macro loops
- **Average Cycle Time**: Duration per cycle for RfT/second calculations
- **Configuration**: Edit `captureRect := {x: 1017, y: 386, w: 470, h: 49}` for screenshot area

### ⚠️ Endgame Exploit

**⚠️ WARNING**: Exploits game bug, potentially game-breaking, use at own risk. May result in bans or save corruption. Developers may patch this.

**Mechanism**: 
Exploits brief timing window when switching mineral levels. When changing from affordable to unaffordable mineral, there's a microsecond window before price updates, allowing purchase of normally unaffordable minerals.

**Implementation**:
Rapidly alternates between highest affordable and highest unlocked mineral levels to repeatedly exploit the timing window.

**Configuration**:
- **Disable Auto Refining**: When farming high-level minerals only
- **Enable Auto Refining**: Integrates exploit into standard polish/refine cycles
- **Exploit Wait Time**: Adjust this based on mineral cost fall, the price of the highest affordable mineral needs to drop to an affordable value before the loops starts again.

---

## ✨ UNITY HELPER

### 🔄 Auto Unity with Time Warp Integration

Enhanced version of in-game auto-unity with additional Time Flux spending capability.

**Key Difference**: Allows configurable Time Flux spending before unity operations.

**Requirements**:
- Large Time Flux reserves
- Late-game in-game macro for planet loadout switching

**Configuration Options**:
- **Zodiac Element Selection**: Choose specific zodiac types to target
- **Time Flux Minutes**: Amount to spend before uniting
- **Repetition Count**: Number of macro cycles before stopping

### ♾️ Auto Zodiac Redistribution

Automates zodiac stat rerolling until desired stats are achieved.

**Functionality**:
- Continuously redistributes zodiac points
- Configurable wait time for user reaction
- Manual stop when desired stats are rolled

**Configuration**:
- **Redistribution Wait Time**: Reaction time window in milliseconds
- **Strategy**: Monitor stats, stop macro when satisfied with roll

**Use Cases**:
- Optimizing zodiac stat distributions
- Farming for specific stat combinations
- Eliminating manual redistribution tedium

---

## 🛠️ Additional Tools

### 🖤️ Autoclicker
- **Function**: Continuous clicking at current mouse position
- **Use Cases**: Secret achievements, SPM spawning, general clicking automation
- **Implementation**: Basic but reliable clicking loop

### ⏰ Time Warp Burst
**Purpose**: Efficient Time Flux spending with controlled bursts.

**Configuration**:
- **Minutes to Spend**: Total Time Flux minutes per session
- **Burst Interval**: Time between start/stop cycles (milliseconds)

**Example Configuration**:
- Minutes: 10, Interval: 1000ms (1 second)
- **Result**: Spends 1 minute of Time Flux, waits 1 second, repeats
- **Use Case**: Early-game magnet farming, controlled progression

**Implementation**:
1. Initial setup: Click Time Flux tab, set minutes to spend (once)
2. Loop: Start time warp → Wait interval → Stop time warp → Repeat

### 💰 Time Flux Buy
**⚠️ Disclaimer**: Intended for testing with cheat modes only.

**Function**: Rapidly purchases 24-hour Time Flux from shop
**Recommendation**: Only use with cheats that make shop purchases free
**Ethics**: Not recommended for normal gameplay

---

## 🔧 Technical Implementation Details

### 🏗️ Script Architecture
- **Language**: AutoHotkey v2
- **Memory Usage**: ~15-25 MB during operation
- **CPU Impact**: <5% on modern systems
- **Response Time**: UI <100ms, coordinate picker <50ms

### 🛡️ Error Handling
- **Game State Validation**: Checks for Revolution Idle window focus
- **Coordinate Validation**: Ensures coordinates are within screen bounds
- **Configuration Validation**: Input validation with fallback defaults
- **Graceful Degradation**: Continues operation despite minor errors

### 🚀 Performance Optimization
- **UI Update Interval**: 250ms (configurable)
- **Auto-save Frequency**: 10 seconds
- **Screenshot Management**: Configurable retention limits
- **Memory Management**: Automatic cleanup of temporary files

---

## 📚 Advanced Configuration

### 📍 Manual Coordinate Setup (If Needed)
Coordinates stored in INI format: `CoordinateName=x,y`

### ⏱️ Timing Optimization
- **MicroDelayMs**: Small delay between actions (default: 25ms)
- **Macro-specific intervals**: Each macro type has optimized timing
- **System Performance**: Adjust delays based on system responsiveness

### 🔍 Troubleshooting
- **Missed Clicks**: Recalibrate coordinates or adjust game window position
- **Performance Issues**: Increase MicroDelayMs value
- **Configuration Issues**: Check file permissions, verify INI file integrity

---

## ❓ Frequently Asked Questions (FAQ)

### 💾 Installation & Setup

**Q: The script won't start - what's wrong?**
A: Most common issues:
- Make sure you have AutoHotkey v2.0+ installed (not v1.1)
- Right-click the .ahk file → "Run Script" if double-clicking doesn't work
- Check Windows Defender/antivirus isn't blocking the script
- Ensure Revolution Idle is running before starting the script

**Q: None of the coordinates work / clicks are missing**
A: This is normal for first-time setup:
- Default coordinates are for specific resolution/setup and likely won't match yours
- Go to "Other Tools > Coordinate Settings" and recalibrate all coordinates
- Make sure Revolution Idle is in windowed mode, not fullscreen
- Try running the game at 1280x720 if possible for better accuracy

**Q: The coordinate picker isn't working**
A: 
- Press Esc first to make sure you're not already in picker mode
- Try closing and reopening the script
- Make sure Revolution Idle window is visible and focused
- Some antivirus software blocks coordinate capture - temporarily disable if needed

### ⚡ Macro Performance

**Q: Which macro should I use for optimal RfT farming?**
A: Based on testing across progression stages:
- **Quick macro** is often optimal for most situations
- **Standard macro** is good for balanced approach
- **Long macro** only if you need maximum mineral levels per cycle
- Test different macros and compare RfT/second using the statistics section

**Q: My cycles are really slow / the script seems laggy**
A: Increase timing delays:
- Raise "Delay between actions" (MicroDelayMs) to 50-100ms
- Close other resource-intensive programs
- Make sure Revolution Idle window stays focused and visible

**Q: The exploit macro isn't working**
A: The Endgame Exploit requires precise timing:
- Adjust "Exploit wait time" - start with 5000ms (5 seconds) and experiment
- Make sure you can actually afford your "highest mineral level" setting
- Works best when there's a big gap between affordable and max unlocked minerals

### ⚙️ Configuration Issues

**Q: My settings keep resetting**
A: Check file permissions:
- Make sure the script folder isn't read-only
- Try running as administrator once to create the INI file
- Check if antivirus is quarantining the configuration file
- Look for `RevolutionIdleHelper_v1.2.ini` in the script directory

**Q: What should I set "Highest mineral level" to?**
A: This depends on your progression:
- **Early game**: Keep at 999 (or your actual max unlocked)
- **Mid/Late game**: Set to the highest mineral you can actually afford to spawn
- **Not** the highest unlocked - the highest you can buy with your current resources
- If unsure, manually spawn minerals in-game to find your affordable maximum

**Q: When should I enable/disable the automation unlockables?**
A: Set based on what you've actually unlocked (and activated) in-game. When in doubt, leave disabled - the script will work manually

### 📚 Advanced Usage

**Q: Can I run multiple macros at once?**
A: No, only one macro runs at a time. This is intentional to prevent conflicts and ensure proper sequencing.

**Q: How do I optimize for overnight farming?**
A: Recommended settings:
- Use **Standard** or **Quick** macro
- Enable **Auto Refining**
- Enable **Auto RfT Upgrade** if you want to spend RfT points

**Q: The Time Warp Burst isn't working properly**
A: Check your configuration:
- Make sure you have enough Time Flux for the "Minutes to spend" setting
- "Burst Interval" should be in milliseconds (1000ms = 1 second)
- The script clicks Time Flux tab first - make sure that coordinate is set
- Time Flux spending happens gradually - don't expect instant results

**Q: How do I set up the screenshot capture for RfT tracking?**
A: You need to edit the code:
- Find the line: `static captureRect := {x: 1017, y: 386, w: 470, h: 49}`
- Change x,y to the top-left corner of your RfT display
- Change w,h to the width and height of the area to capture
- Use a screen ruler tool or screenshot to get exact pixel coordinates

### 🔍 Troubleshooting

**Q: The script suddenly stopped working after a game update**
A: Game updates can change UI layouts:
- Recalibrate all coordinates using the coordinate picker
- Check if any new automation features were added to the game
- Update your automation unlockable settings if needed
- Some coordinates may have shifted slightly

**Q: My antivirus keeps flagging the script**
A: This is common with automation scripts:
- AutoHotkey scripts often trigger false positives
- Add the script folder to your antivirus whitelist
- Download AutoHotkey from official sources only
- The script is open source - you can review the code for safety

**Q: Can this get me banned from Revolution Idle?**
A: The script only uses mouse/keyboard input:
- No memory modification or value injection
- No network communication or data manipulation
- Similar to using a macro keyboard or mouse
- **However**: The Endgame Exploit uses a game bug - use at your own discretion
- Always follow game terms of service and community guidelines
- Do not advertise your use of Tools on he official Discord

**Q: The GUI is too big/small for my screen**
A: The GUI is designed for 1920x1080 but adapts:
- Use **F10** to toggle compact mode for smaller footprint
- Drag the window by clicking and holding the background
- GUI sections can be collapsed to save space
- If severely misaligned, try changing your display scaling

### 🚀 Performance & Optimization

**Q: How can I calculate my optimal RfT per second?**
A: Use the built-in statistics:
- Look at "Average cycle time" in the statistics section
- Manually note your RfT before and after several cycles
- Formula: (RfT gained) / (average cycle time in seconds)
- Test different macros and settings to find your optimum

**Q: Should I use this script for early RfT progression?**
A: It's most beneficial for mid-to-late game:
- Early game benefits less from automation
- Manual play might be faster for initial progression
- Consider starting to use it once manual refining becomes

---

**🤔 Still have questions?** Feel free to ask in the comments - this is a community tool and I'm happy to help troubleshoot or add features based on feedback!

**💬 Feedback and contributions welcome** - this is a community tool meant to enhance the Revolution Idle experience while maintaining the core game enjoyment.






