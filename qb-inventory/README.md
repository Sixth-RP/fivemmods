# QB-Inventory - NoPixel 4.0 Inspired 3D UI

A modern, sleek inventory system for FiveM QBCore servers, inspired by the NoPixel 4.0 UI design.

## Features

### Visual Design
- **3D Background Effects** - Animated grid floor with perspective transformation
- **Glassmorphism UI** - Modern blur effects and transparency
- **Neon Glow Effects** - Cyan/magenta accent colors with glowing elements
- **Smooth Animations** - Panel slides, fade-ins, and hover transitions
- **Item Rarity System** - Color-coded item borders (Common, Uncommon, Rare, Epic, Legendary)

### Functionality
- **Drag & Drop** - Intuitive item movement between inventories
- **Hotbar System** - Quick access slots (1-5 keys)
- **Context Menu** - Right-click for Use, Give, Drop, Split actions
- **Amount Modal** - Slider/input for selecting item quantities
- **Search Filtering** - Real-time inventory search
- **Weight System** - Visual weight bar with percentage fill
- **Tooltips** - Detailed item information on hover

### Inventory Types
- Personal Inventory
- Vehicle Trunks (by vehicle class)
- Gloveboxes
- Stashes (job-restricted)
- Shops
- Ground Drops

## Installation

1. **Download & Extract**
   - Place the `qb-inventory` folder in your server's `resources` directory

2. **Database Setup**
   - Run the SQL file located at `sql/inventory.sql` in your database

3. **Configure**
   - Edit `config.lua` to customize settings:
     - Inventory slots and weight limits
     - Shops and their items
     - Stash locations
     - Vehicle trunk sizes
     - Keybinds

4. **Start Resource**
   - Add to your `server.cfg`:
   ```
   ensure qb-inventory
   ```

## Dependencies
- qb-core
- oxmysql

## Keybinds
| Key | Action |
|-----|--------|
| TAB | Open/Close Inventory |
| 1-5 | Use Hotbar Item |
| E | Pickup Ground Items |
| ESC | Close Inventory/Modal |

## Configuration

### Inventory Settings
```lua
Config.MaxInventoryWeight = 120000 -- in grams
Config.MaxInventorySlots = 41
```

### Shop Example
```lua
Config.Shops = {
    ["247supermarket"] = {
        name = "24/7 Supermarket",
        items = {
            { name = "sandwich", price = 2, amount = 50 },
            { name = "water_bottle", price = 1, amount = 50 },
        }
    }
}
```

### Stash Example
```lua
Config.Stashes = {
    ["police_evidence"] = {
        name = "Police Evidence",
        slots = 100,
        weight = 500000,
        coords = vector3(473.53, -992.77, 26.27),
        job = "police",
        jobGrade = 0
    }
}
```

## Exports

### Client Exports
```lua
-- Check if player has item
exports['qb-inventory']:HasItem(itemName, amount)

-- Get item count
exports['qb-inventory']:GetItemCount(itemName)

-- Get all player items
exports['qb-inventory']:GetPlayerItems()
```

### Server Exports
```lua
-- Add item to player
exports['qb-inventory']:AddItem(source, item, amount, info, slot)

-- Remove item from player
exports['qb-inventory']:RemoveItem(source, item, amount, slot)

-- Check if player has item
exports['qb-inventory']:HasItem(source, item, amount)

-- Get item count
exports['qb-inventory']:GetItemCount(source, item)
```

## Events

### Open Shop
```lua
TriggerEvent('qb-inventory:client:openShop', 'shopId')
```

### Open Stash
```lua
TriggerEvent('qb-inventory:client:openStash', 'stashId')
```

### Open Trunk
```lua
TriggerEvent('qb-inventory:client:openTrunk')
```

### Open Glovebox
```lua
TriggerEvent('qb-inventory:client:openGlovebox')
```

## UI Theme Colors

The UI uses CSS custom properties for easy theming:

```css
:root {
    --primary: #00d4ff;       /* Main accent color */
    --secondary: #ff006e;     /* Secondary accent */
    --accent: #8338ec;        /* Purple accent */
    --bg-dark: #0a0e17;       /* Darkest background */
    --success: #00ff88;       /* Success/money color */
    --warning: #ffcc00;       /* Warning/drop color */
    --danger: #ff3366;        /* Error/close color */
}
```

## Credits

- Design inspired by NoPixel 4.0
- Built for QBCore Framework
- Created by Sixth-RP

## License

This resource is provided as-is for use on FiveM servers. Please credit if redistributed.
