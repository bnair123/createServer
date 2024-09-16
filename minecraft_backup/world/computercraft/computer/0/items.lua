---
--- Script for rolling 15-minute item changes with 24-hour history and touch-enabled interface
--- Made for CCTweaked & Advanced Peripherals integration
---

label = "Changed Items in System"

me = peripheral.find("meBridge") -- MeBridge
mon = peripheral.find("monitor") -- Monitor
filename = "me_items.txt" -- File to store item data
historyFile = "item_history.txt" -- File to store 24-hour history

-- Variables to store previous and changed items
prevItems = {}
changedItems = {}
rollingChanges = {}
history = {}
selectedItem = nil
updateCycle = 1 -- 1 for list, 2 for graph

-- Store past 24-hour data in memory (initialize with 1440 minutes for 24 hours of history)
maxHistoryMinutes = 1440
for i = 1, maxHistoryMinutes do
    history[i] = {}
end

-- Store rolling changes for 15 minutes (15-minute window = 15 data points)
rollingWindowSize = 15
for i = 1, rollingWindowSize do
    rollingChanges[i] = {}
end

-- Function to read previous items from a file
function readPreviousItems()
    local file = fs.open(filename, "r")
    if file then
        local contents = file.readAll()
        prevItems = textutils.unserialize(contents) or {}
        file.close()
    else
        prevItems = {} -- No previous file exists
    end
end

-- Function to write current items to a file
function writeCurrentItems(currentItems)
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(currentItems))
        file.close()
    end
end

-- Function to read 24-hour history from a file
function readHistory()
    local file = fs.open(historyFile, "r")
    if file then
        local contents = file.readAll()
        history = textutils.unserialize(contents) or history
        file.close()
    end
end

-- Function to write 24-hour history to a file
function writeHistory()
    local file = fs.open(historyFile, "w")
    if file then
        file.write(textutils.serialize(history))
        file.close()
    end
end

-- Function to calculate item changes and update rolling window & history
function calculateChanges()
    local currentItems = me.listItems()
    local currentMap = aggregateItems(currentItems)
    changedItems = {}

    -- Calculate changes by comparing with previous state
    for itemName, prevAmount in pairs(prevItems) do
        if not currentMap[itemName] then
            changedItems[itemName] = -prevAmount
        elseif currentMap[itemName] ~= prevAmount then
            changedItems[itemName] = currentMap[itemName] - prevAmount
        end
    end

    -- Check for newly added items
    for itemName, currentAmount in pairs(currentMap) do
        if not prevItems[itemName] then
            changedItems[itemName] = currentAmount
        end
    end

    -- Update rolling 15-minute window
    table.remove(rollingChanges, 1)
    table.insert(rollingChanges, changedItems)

    -- Update 24-hour history
    table.remove(history, 1)
    table.insert(history, changedItems)

    -- Write the updated history and current items to files
    writeCurrentItems(currentMap)
    writeHistory()
end

-- Function to display rolling 15-minute changes
function displayRollingChanges()
    row = 2
    mon.clear()
    CenterT("Item Changes in Last 15 Minutes:", row, colors.black, colors.white, "left", false)

    -- Aggregate changes from the last 15 minutes
    local aggregatedChanges = {}
    for _, changes in ipairs(rollingChanges) do
        for itemName, change in pairs(changes) do
            if not aggregatedChanges[itemName] then
                aggregatedChanges[itemName] = change
            else
                aggregatedChanges[itemName] = aggregatedChanges[itemName] + change
            end
        end
    end

    -- Display the aggregated changes
    for itemName, change in pairs(aggregatedChanges) do
        row = row + 1
        if change > 0 then
            CenterT(itemName .. " +" .. change, row, colors.black, colors.green, "left", false)
        else
            CenterT(itemName .. " " .. change, row, colors.black, colors.red, "left", false)
        end
    end
end

-- Function to display a line graph for 24-hour item changes
function displayLineGraph(itemName)
    row = 2
    mon.clear()
    CenterT("24-Hour Change for: " .. itemName, row, colors.black, colors.white, "left", false)

    -- Draw a line graph for the selected item based on history
    local graphHeight = 10 -- Adjust for display size
    local maxChange = 0
    local dataPoints = {}

    -- Collect data for the selected item over 24 hours
    for _, changes in ipairs(history) do
        local change = changes[itemName] or 0
        table.insert(dataPoints, change)
        maxChange = math.max(maxChange, math.abs(change))
    end

    -- Scale and plot the graph
    for i, change in ipairs(dataPoints) do
        local x = i
        local y = math.floor(graphHeight * (change / maxChange))
        mon.setCursorPos(x, row + y)
        mon.write("-")
    end
end

-- Function to handle touch events
function handleTouch(x, y)
    -- Assuming the list is displayed, use the y-coordinate to detect item selection
    local itemName = detectItemFromTouch(y)
    if itemName then
        selectedItem = itemName
        updateCycle = 2 -- Switch to graph view
    end
end

-- Function to detect item based on touch
function detectItemFromTouch(y)
    -- Assuming row starts from 2, map y to item name
    -- This would need a mapping of rows to item names from the display
    local items = sortChangedItems() -- Sorted items from the latest display
    local index = y - 2 -- Adjust for header
    if index > 0 and index <= #items then
        return items[index].name
    end
    return nil
end

-- Utility methods (CenterT, clearBox, etc.) remain unchanged

-- Main loop to alternate between displaying rolling changes and graphs
function mainLoop()
    while true do
        calculateChanges() -- Update the list every minute

        if updateCycle == 1 then
            displayRollingChanges()
        elseif updateCycle == 2 and selectedItem then
            displayLineGraph(selectedItem)
        end

        sleep(10) -- Switch display every 10 seconds

        -- Check for touch events
        local event, side, x, y = os.pullEvent("monitor_touch")
        if event == "monitor_touch" then
            handleTouch(x, y)
        end
    end
end

-- Prepare monitor, read data, and start the main loop
prepareMonitor()
readPreviousItems()
readHistory()
mainLoop()
