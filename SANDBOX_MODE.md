# Sandbox Mode

Sandbox mode creates a special testing level at depth 1 with all monsters for experimentation and very high item density.

## How to Enable

### Method 1: Browser Console (Recommended)
1. Open the game in your browser
2. Open browser developer tools (F12)
3. In the console, type one of these commands:

```javascript
// Enable sandbox mode
enableSandbox()

// Disable sandbox mode  
disableSandbox()

// Check current status
checkSandbox()
```

### Method 2: JavaScript Variable
Set a global variable in the browser console:
```javascript
window.sandboxMode = true;  // Enable
window.sandboxMode = false; // Disable
```

## How to Use

1. Enable sandbox mode using one of the methods above
2. Start a new game
3. The first level (depth 1) will be a sandbox level with:
   - Large central area for item spawning (very high density)
   - All monster breeds in separate rooms around the edges
   - Connected areas for easy exploration
   - Clean layout without random decorations

## Features

- **Central Area**: Large open space where items spawn at 10x normal density
- **Monster Rooms**: Different monster breeds in separate rooms around the edges
- **Easy Navigation**: All areas connected by passages
- **No Random Decorations**: Clean layout for testing
- **Custom Monster Spawning**: One of each monster breed placed in separate rooms

## Notes

- Sandbox mode only affects depth 1 levels
- Normal gameplay continues at depth 2 and beyond
- The setting persists across browser sessions
- Does not affect existing save games, only new games
- Items are placed by the normal item system but at much higher density
- The high item density (10.0) ensures lots of items to test with