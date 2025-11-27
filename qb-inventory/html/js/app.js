/* ==========================================
   QB-INVENTORY - NoPixel 4.0 Inspired UI
   JavaScript Application
   ========================================== */

// Global Variables
let playerInventory = { items: {}, maxWeight: 120000, maxSlots: 41, weight: 0 };
let otherInventory = null;
let currentOtherType = null;
let currentOtherId = null;
let selectedSlot = null;
let selectedItem = null;
let pendingAction = null;
let isDragging = false;
let draggedItem = null;
let draggedSlot = null;
let draggedInventory = null;

// DOM Elements
const inventoryContainer = document.getElementById('inventory-container');
const playerInventoryGrid = document.getElementById('player-inventory-grid');
const otherInventoryGrid = document.getElementById('other-inventory-grid');
const otherInventoryPanel = document.getElementById('other-inventory-panel');
const hotbarSlots = document.getElementById('hotbar-slots');
const contextMenu = document.getElementById('context-menu');
const amountModal = document.getElementById('amount-modal');
const itemTooltip = document.getElementById('item-tooltip');
const groundDropArea = document.getElementById('ground-drop-area');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
    createInventorySlots();
    createHotbarSlots();
});

// NUI Message Handler
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'openInventory':
            openInventory(data);
            break;
        case 'closeInventory':
            closeInventory();
            break;
        case 'updateInventory':
            updatePlayerInventory(data.playerInventory);
            break;
        case 'updateOtherInventory':
            updateOtherInventory(data.items, data.weight);
            break;
        case 'updateHotbar':
            updateHotbar(data.hotbar);
            break;
    }
});

// Keyboard Handler
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (!amountModal.classList.contains('hidden')) {
            closeModal();
        } else if (!contextMenu.classList.contains('hidden')) {
            hideContextMenu();
        } else {
            closeInventory();
        }
    }
});

// Setup Event Listeners
function setupEventListeners() {
    // Click outside to close context menu
    document.addEventListener('click', (e) => {
        if (!contextMenu.contains(e.target)) {
            hideContextMenu();
        }
    });

    // Context menu actions
    document.querySelectorAll('.context-item').forEach(item => {
        item.addEventListener('click', () => {
            const action = item.dataset.action;
            handleContextAction(action);
        });
    });

    // Amount input sync
    const amountInput = document.getElementById('amount-input');
    const amountSlider = document.getElementById('amount-slider');

    amountInput.addEventListener('input', () => {
        const max = parseInt(amountSlider.max);
        let value = parseInt(amountInput.value) || 1;
        value = Math.max(1, Math.min(value, max));
        amountInput.value = value;
        amountSlider.value = value;
    });

    amountSlider.addEventListener('input', () => {
        amountInput.value = amountSlider.value;
    });

    // Search functionality
    document.getElementById('player-search').addEventListener('input', (e) => {
        filterInventory(e.target.value, 'player');
    });

    document.getElementById('other-search').addEventListener('input', (e) => {
        filterInventory(e.target.value, 'other');
    });

    // Ground drop area
    groundDropArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        groundDropArea.classList.add('drag-over');
    });

    groundDropArea.addEventListener('dragleave', () => {
        groundDropArea.classList.remove('drag-over');
    });

    groundDropArea.addEventListener('drop', (e) => {
        e.preventDefault();
        groundDropArea.classList.remove('drag-over');
        
        if (draggedItem && draggedInventory === 'player') {
            showAmountModal(draggedItem, 'drop');
        }
    });
}

// Create Inventory Slots
function createInventorySlots() {
    playerInventoryGrid.innerHTML = '';
    
    for (let i = 1; i <= playerInventory.maxSlots; i++) {
        const slot = createSlot(i, 'player');
        playerInventoryGrid.appendChild(slot);
    }
}

// Create Hotbar Slots
function createHotbarSlots() {
    hotbarSlots.innerHTML = '';
    
    for (let i = 1; i <= 5; i++) {
        const slot = document.createElement('div');
        slot.className = 'hotbar-slot';
        slot.dataset.slot = i;
        slot.dataset.inventory = 'hotbar';
        
        const hotkey = document.createElement('span');
        hotkey.className = 'slot-hotkey';
        hotkey.textContent = i;
        slot.appendChild(hotkey);
        
        setupSlotEvents(slot, i, 'hotbar');
        hotbarSlots.appendChild(slot);
    }
}

// Create Single Slot
function createSlot(slotNumber, inventoryType) {
    const slot = document.createElement('div');
    slot.className = 'inventory-slot empty';
    slot.dataset.slot = slotNumber;
    slot.dataset.inventory = inventoryType;
    slot.draggable = true;
    
    setupSlotEvents(slot, slotNumber, inventoryType);
    
    return slot;
}

// Setup Slot Events
function setupSlotEvents(slot, slotNumber, inventoryType) {
    // Double click to use
    slot.addEventListener('dblclick', () => {
        const item = getItemFromSlot(slotNumber, inventoryType);
        if (item) {
            useItem(slotNumber);
        }
    });

    // Right click for context menu
    slot.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        const item = getItemFromSlot(slotNumber, inventoryType);
        if (item) {
            selectedSlot = slotNumber;
            selectedItem = item;
            showContextMenu(e.clientX, e.clientY, inventoryType);
        }
    });

    // Drag start
    slot.addEventListener('dragstart', (e) => {
        const item = getItemFromSlot(slotNumber, inventoryType);
        if (!item) {
            e.preventDefault();
            return;
        }
        
        isDragging = true;
        draggedItem = item;
        draggedSlot = slotNumber;
        draggedInventory = inventoryType;
        
        slot.classList.add('dragging');
        
        // Create drag image
        const dragImage = slot.cloneNode(true);
        dragImage.style.position = 'absolute';
        dragImage.style.top = '-1000px';
        document.body.appendChild(dragImage);
        e.dataTransfer.setDragImage(dragImage, 35, 35);
        
        setTimeout(() => document.body.removeChild(dragImage), 0);
    });

    // Drag end
    slot.addEventListener('dragend', () => {
        isDragging = false;
        slot.classList.remove('dragging');
        document.querySelectorAll('.drag-over').forEach(el => el.classList.remove('drag-over'));
    });

    // Drag over
    slot.addEventListener('dragover', (e) => {
        e.preventDefault();
        if (isDragging) {
            slot.classList.add('drag-over');
        }
    });

    // Drag leave
    slot.addEventListener('dragleave', () => {
        slot.classList.remove('drag-over');
    });

    // Drop
    slot.addEventListener('drop', (e) => {
        e.preventDefault();
        slot.classList.remove('drag-over');
        
        if (!draggedItem) return;
        
        const toSlot = slotNumber;
        const toInventory = inventoryType;
        
        // Don't drop on same slot
        if (draggedSlot === toSlot && draggedInventory === toInventory) {
            return;
        }
        
        // Check if moving to other inventory or swapping
        if (draggedInventory !== toInventory || isShiftPressed()) {
            // Show amount modal for transfers
            showAmountModal(draggedItem, 'move', toSlot, toInventory);
        } else {
            // Direct move/swap within same inventory
            moveItem(draggedSlot, toSlot, draggedInventory, toInventory, draggedItem.amount);
        }
    });

    // Mouse enter for tooltip
    slot.addEventListener('mouseenter', (e) => {
        const item = getItemFromSlot(slotNumber, inventoryType);
        if (item && !isDragging) {
            showTooltip(item, e.clientX, e.clientY);
        }
    });

    // Mouse leave to hide tooltip
    slot.addEventListener('mouseleave', () => {
        hideTooltip();
    });

    // Mouse move for tooltip position
    slot.addEventListener('mousemove', (e) => {
        if (!itemTooltip.classList.contains('hidden')) {
            positionTooltip(e.clientX, e.clientY);
        }
    });
}

// Get Item From Slot
function getItemFromSlot(slot, inventoryType) {
    if (inventoryType === 'player' || inventoryType === 'hotbar') {
        return playerInventory.items[slot];
    } else if (inventoryType === 'other' && otherInventory) {
        return otherInventory.items[slot];
    }
    return null;
}

// Open Inventory
function openInventory(data) {
    playerInventory = data.playerInventory;
    
    // Update player info
    if (data.playerData) {
        document.getElementById('player-name').textContent = data.playerData.name;
        document.getElementById('player-cash').textContent = formatMoney(data.playerData.cash);
        document.getElementById('player-bank').textContent = formatMoney(data.playerData.bank);
    }
    
    // Update player inventory
    updatePlayerInventory(playerInventory);
    
    // Handle other inventory
    if (data.otherInventory) {
        otherInventory = data.otherInventory;
        currentOtherType = data.otherInventory.type;
        currentOtherId = data.otherInventory.id;
        
        showOtherInventory(data.otherInventory);
    } else {
        otherInventory = null;
        currentOtherType = null;
        currentOtherId = null;
        otherInventoryPanel.classList.add('hidden');
    }
    
    inventoryContainer.classList.remove('hidden');
    playSound('open');
}

// Close Inventory
function closeInventory() {
    inventoryContainer.classList.add('hidden');
    hideContextMenu();
    hideTooltip();
    closeModal();
    
    playSound('close');
    
    fetch(`https://${GetParentResourceName()}/closeInventory`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}

// Update Player Inventory
function updatePlayerInventory(inventory) {
    playerInventory = inventory;
    
    // Update weight bar
    const weightPercent = (inventory.weight / inventory.maxWeight) * 100;
    document.getElementById('player-weight-fill').style.width = `${weightPercent}%`;
    document.getElementById('player-weight').textContent = (inventory.weight / 1000).toFixed(1);
    document.getElementById('player-max-weight').textContent = (inventory.maxWeight / 1000).toFixed(0);
    
    // Update slots
    for (let i = 1; i <= playerInventory.maxSlots; i++) {
        const slot = playerInventoryGrid.querySelector(`[data-slot="${i}"]`);
        if (slot) {
            updateSlotDisplay(slot, playerInventory.items[i], i, i <= 5);
        }
    }
    
    // Update hotbar
    for (let i = 1; i <= 5; i++) {
        const slot = hotbarSlots.querySelector(`[data-slot="${i}"]`);
        if (slot) {
            updateSlotDisplay(slot, playerInventory.items[i], i, true);
        }
    }
}

// Update Other Inventory
function updateOtherInventory(items, weight) {
    if (!otherInventory) return;
    
    otherInventory.items = items;
    otherInventory.weight = weight;
    
    // Update weight bar
    const weightPercent = (weight / otherInventory.maxWeight) * 100;
    document.getElementById('other-weight-fill').style.width = `${weightPercent}%`;
    document.getElementById('other-weight').textContent = (weight / 1000).toFixed(1);
    
    // Update slots
    for (let i = 1; i <= otherInventory.maxSlots; i++) {
        const slot = otherInventoryGrid.querySelector(`[data-slot="${i}"]`);
        if (slot) {
            updateSlotDisplay(slot, items[i], i, false);
        }
    }
}

// Show Other Inventory
function showOtherInventory(inventory) {
    otherInventoryPanel.classList.remove('hidden');
    
    // Update header
    document.getElementById('other-title').textContent = inventory.label || 'STORAGE';
    
    // Set icon based on type
    const icon = document.getElementById('other-icon');
    switch (inventory.type) {
        case 'trunk':
            icon.className = 'fas fa-car';
            break;
        case 'glovebox':
            icon.className = 'fas fa-box';
            break;
        case 'stash':
            icon.className = 'fas fa-warehouse';
            break;
        case 'shop':
            icon.className = 'fas fa-shopping-cart';
            break;
        case 'drop':
            icon.className = 'fas fa-arrow-down';
            break;
        default:
            icon.className = 'fas fa-box';
    }
    
    // Update weight info
    document.getElementById('other-max-weight').textContent = (inventory.maxWeight / 1000).toFixed(0);
    
    // Create slots
    otherInventoryGrid.innerHTML = '';
    for (let i = 1; i <= inventory.maxSlots; i++) {
        const slot = createSlot(i, 'other');
        otherInventoryGrid.appendChild(slot);
    }
    
    // Update displays
    updateOtherInventory(inventory.items, inventory.weight);
}

// Update Slot Display
function updateSlotDisplay(slot, item, slotNumber, isHotbar) {
    slot.innerHTML = '';
    
    if (item) {
        slot.classList.remove('empty');
        slot.classList.add('has-item');
        slot.draggable = true;
        
        // Add rarity class
        const rarity = item.rarity || 'common';
        slot.className = slot.className.replace(/rarity-\w+/g, '');
        slot.classList.add(`rarity-${rarity}`);
        
        const content = document.createElement('div');
        content.className = 'slot-content';
        
        const img = document.createElement('img');
        img.className = 'slot-image';
        img.src = getItemImage(item.image || item.name);
        img.alt = item.label || item.name;
        img.onerror = () => img.src = 'img/default.png';
        content.appendChild(img);
        
        slot.appendChild(content);
        
        // Amount badge
        if (item.amount > 1) {
            const amount = document.createElement('span');
            amount.className = 'slot-amount';
            amount.textContent = `x${item.amount}`;
            slot.appendChild(amount);
        }
        
        // Shop price
        if (currentOtherType === 'shop' && item.price) {
            const price = document.createElement('span');
            price.className = 'shop-price';
            price.textContent = `$${formatMoney(item.price)}`;
            slot.appendChild(price);
            slot.classList.add('shop-item');
        }
    } else {
        slot.classList.add('empty');
        slot.classList.remove('has-item');
        slot.draggable = false;
        slot.className = slot.className.replace(/rarity-\w+/g, '');
    }
    
    // Hotkey badge
    if (isHotbar && slotNumber <= 5) {
        const hotkey = document.createElement('span');
        hotkey.className = 'slot-hotkey';
        hotkey.textContent = slotNumber;
        slot.appendChild(hotkey);
    }
}

// Update Hotbar
function updateHotbar(hotbar) {
    for (let i = 1; i <= 5; i++) {
        const slot = hotbarSlots.querySelector(`[data-slot="${i}"]`);
        if (slot) {
            updateSlotDisplay(slot, hotbar[i], i, true);
        }
    }
}

// Show Context Menu
function showContextMenu(x, y, inventoryType) {
    contextMenu.style.left = `${x}px`;
    contextMenu.style.top = `${y}px`;
    contextMenu.classList.remove('hidden');
    
    // Adjust menu items based on inventory type
    const useItem = contextMenu.querySelector('[data-action="use"]');
    const giveItem = contextMenu.querySelector('[data-action="give"]');
    const dropItem = contextMenu.querySelector('[data-action="drop"]');
    const splitItem = contextMenu.querySelector('[data-action="split"]');
    
    if (inventoryType === 'other') {
        useItem.style.display = currentOtherType === 'shop' ? 'none' : 'flex';
        giveItem.style.display = 'none';
        dropItem.style.display = 'none';
        splitItem.style.display = 'none';
    } else {
        useItem.style.display = 'flex';
        giveItem.style.display = 'flex';
        dropItem.style.display = 'flex';
        splitItem.style.display = selectedItem && selectedItem.amount > 1 ? 'flex' : 'none';
    }
    
    // Adjust position if menu goes off screen
    const rect = contextMenu.getBoundingClientRect();
    if (rect.right > window.innerWidth) {
        contextMenu.style.left = `${x - rect.width}px`;
    }
    if (rect.bottom > window.innerHeight) {
        contextMenu.style.top = `${y - rect.height}px`;
    }
}

// Hide Context Menu
function hideContextMenu() {
    contextMenu.classList.add('hidden');
}

// Handle Context Action
function handleContextAction(action) {
    hideContextMenu();
    
    if (!selectedItem || !selectedSlot) return;
    
    switch (action) {
        case 'use':
            useItem(selectedSlot);
            break;
        case 'give':
            showAmountModal(selectedItem, 'give');
            break;
        case 'drop':
            showAmountModal(selectedItem, 'drop');
            break;
        case 'split':
            showAmountModal(selectedItem, 'split');
            break;
    }
}

// Use Item
function useItem(slot) {
    fetch(`https://${GetParentResourceName()}/useItem`, {
        method: 'POST',
        body: JSON.stringify({ slot: slot })
    });
    playSound('use');
}

// Show Amount Modal
function showAmountModal(item, action, toSlot = null, toInventory = null) {
    pendingAction = { action, item, toSlot, toInventory };
    
    const modal = document.getElementById('amount-modal');
    const slider = document.getElementById('amount-slider');
    const input = document.getElementById('amount-input');
    const image = document.getElementById('modal-item-image');
    const name = document.getElementById('modal-item-name');
    
    slider.max = item.amount;
    slider.value = action === 'split' ? Math.floor(item.amount / 2) : item.amount;
    input.value = slider.value;
    input.max = item.amount;
    
    image.src = getItemImage(item.image || item.name);
    name.textContent = item.label || item.name;
    
    modal.classList.remove('hidden');
}

// Close Modal
function closeModal() {
    amountModal.classList.add('hidden');
    pendingAction = null;
}

// Adjust Amount
function adjustAmount(delta) {
    const input = document.getElementById('amount-input');
    const slider = document.getElementById('amount-slider');
    const max = parseInt(slider.max);
    
    let value = parseInt(input.value) + delta;
    value = Math.max(1, Math.min(value, max));
    
    input.value = value;
    slider.value = value;
}

// Confirm Action
function confirmAction() {
    if (!pendingAction) return;
    
    const amount = parseInt(document.getElementById('amount-input').value);
    
    switch (pendingAction.action) {
        case 'give':
            fetch(`https://${GetParentResourceName()}/giveItem`, {
                method: 'POST',
                body: JSON.stringify({
                    slot: selectedSlot,
                    amount: amount
                })
            });
            break;
        case 'drop':
            fetch(`https://${GetParentResourceName()}/dropItem`, {
                method: 'POST',
                body: JSON.stringify({
                    slot: draggedSlot || selectedSlot,
                    amount: amount
                })
            });
            break;
        case 'split':
            fetch(`https://${GetParentResourceName()}/splitItem`, {
                method: 'POST',
                body: JSON.stringify({
                    slot: selectedSlot,
                    amount: amount
                })
            });
            break;
        case 'move':
            moveItem(draggedSlot, pendingAction.toSlot, draggedInventory, pendingAction.toInventory, amount);
            break;
    }
    
    closeModal();
    playSound('move');
}

// Move Item
function moveItem(fromSlot, toSlot, fromInventory, toInventory, amount) {
    fetch(`https://${GetParentResourceName()}/moveItem`, {
        method: 'POST',
        body: JSON.stringify({
            fromSlot: fromSlot,
            toSlot: toSlot,
            fromInventory: fromInventory,
            toInventory: toInventory,
            amount: amount,
            otherId: currentOtherId,
            otherType: currentOtherType
        })
    });
}

// Show Tooltip
function showTooltip(item, x, y) {
    const tooltip = document.getElementById('item-tooltip');
    
    tooltip.querySelector('.tooltip-name').textContent = item.label || item.name;
    tooltip.querySelector('.tooltip-description').textContent = item.description || 'No description available.';
    
    const rarity = item.rarity || 'common';
    const rarityEl = tooltip.querySelector('.tooltip-rarity');
    rarityEl.textContent = rarity.charAt(0).toUpperCase() + rarity.slice(1);
    rarityEl.className = `tooltip-rarity ${rarity}`;
    
    const weight = item.weight ? (item.weight / 1000).toFixed(2) : '0.00';
    tooltip.querySelector('.tooltip-stats').innerHTML = `
        <div class="stat"><i class="fas fa-weight-hanging"></i> <span class="stat-value">${weight} kg</span></div>
        <div class="stat"><i class="fas fa-layer-group"></i> <span class="stat-value">x${item.amount || 1}</span></div>
    `;
    
    tooltip.classList.remove('hidden');
    positionTooltip(x, y);
}

// Position Tooltip
function positionTooltip(x, y) {
    const tooltip = document.getElementById('item-tooltip');
    const offset = 15;
    
    let left = x + offset;
    let top = y + offset;
    
    const rect = tooltip.getBoundingClientRect();
    
    if (left + rect.width > window.innerWidth) {
        left = x - rect.width - offset;
    }
    
    if (top + rect.height > window.innerHeight) {
        top = y - rect.height - offset;
    }
    
    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${top}px`;
}

// Hide Tooltip
function hideTooltip() {
    itemTooltip.classList.add('hidden');
}

// Filter Inventory
function filterInventory(search, inventoryType) {
    const grid = inventoryType === 'player' ? playerInventoryGrid : otherInventoryGrid;
    const inventory = inventoryType === 'player' ? playerInventory : otherInventory;
    
    if (!inventory) return;
    
    search = search.toLowerCase();
    
    grid.querySelectorAll('.inventory-slot').forEach(slot => {
        const slotNum = parseInt(slot.dataset.slot);
        const item = inventory.items[slotNum];
        
        if (!search || !item) {
            slot.style.opacity = '1';
        } else {
            const match = (item.label || item.name).toLowerCase().includes(search);
            slot.style.opacity = match ? '1' : '0.3';
        }
    });
}

// Get Item Image
function getItemImage(name) {
    if (!name) return 'img/default.png';
    
    // Check if it's already a full URL or path
    if (name.startsWith('http') || name.startsWith('img/')) {
        return name;
    }
    
    // Try nui://qb-core/shared/items/ first, then local
    return `nui://qb-core/shared/items/${name}.png`;
}

// Format Money
function formatMoney(amount) {
    return new Intl.NumberFormat('en-US').format(amount);
}

// Check Shift Key
function isShiftPressed() {
    return window.event && window.event.shiftKey;
}

// Play Sound
function playSound(type) {
    // Sound would be handled by the game client
}

// Get Parent Resource Name (for FiveM NUI)
function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'qb-inventory';
}

// Debug: Open inventory for testing
function debugOpen() {
    const testData = {
        action: 'openInventory',
        playerInventory: {
            items: {
                1: { name: 'sandwich', label: 'Sandwich', amount: 5, weight: 200, description: 'A delicious sandwich', rarity: 'common' },
                2: { name: 'water_bottle', label: 'Water Bottle', amount: 3, weight: 500, description: 'Fresh water', rarity: 'common' },
                3: { name: 'lockpick', label: 'Lockpick', amount: 1, weight: 100, description: 'Used to pick locks', rarity: 'uncommon' },
                5: { name: 'phone', label: 'Phone', amount: 1, weight: 300, description: 'Your mobile device', rarity: 'rare' }
            },
            maxWeight: 120000,
            maxSlots: 41,
            weight: 15000
        },
        playerData: {
            name: 'John Doe',
            cash: 5000,
            bank: 25000
        }
    };
    
    openInventory(testData);
}

// Export debug function
window.debugInventory = debugOpen;
