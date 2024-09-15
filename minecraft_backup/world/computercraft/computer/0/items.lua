---
--- Script to list item changes in the system with updates every minute and persistent storage
--- Made for CCTweaked & Advanced Peripherals integration
---

label = "Changed Items in System"

me = peripheral.find("meBridge") -- MeBridge
mon = peripheral.find("monitor") -- Monitor
filename = "me_items.txt" -- File to store item data

-- Variables to store previous and changed items
prevItems = {}
changedItems = {}
updateCycle = 1 -- 1 for list, 2 for graphs

-- Function to aggregate item quantities by name
function aggregateItems(items)
    local aggregated = {}
    for _, item in pairs(items) do
        if aggregated[item.name] then
            aggregated[item.name] = aggregated[item.name] + item.amount
        else
            aggregated[item.name] = item.amount
        end
    end
    return aggregated
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

-- Function to compare and calculate item changes
function calculateChanges()
    local currentItems = me.listItems()
    local currentMap = aggregateItems(currentItems) -- Aggregate by item name
    changedItems = {}

    -- Calculate changes by comparing with previous state
    for itemName, prevAmount in pairs(prevItems) do
        if not currentMap[itemName] then
            -- Item was removed entirely
            changedItems[itemName] = -prevAmount
        elseif currentMap[itemName] ~= prevAmount then
            -- Item count changed
            changedItems[itemName] = currentMap[itemName] - prevAmount
        end
    end

    -- Check for newly added items
    for itemName, currentAmount in pairs(currentMap) do
        if not prevItems[itemName] then
            changedItems[itemName] = currentAmount
        end
    end

    -- Write current items to the file for future comparisons
    writeCurrentItems(currentMap)
end

-- Function to sort items by the most changed
function sortChangedItems()
    local sortedList = {}

    -- Convert table into a sortable array
    for itemName, change in pairs(changedItems) do
        table.insert(sortedList, {name = itemName, amount = change})
    end

    -- Sort the array by the absolute value of the change
    table.sort(sortedList, function(a, b)
        return math.abs(a.amount) > math.abs(b.amount)
    end)

    return sortedList
end

-- Function to display the sorted list of changes
function displayChangedItems()
    row = 2
    mon.clear()
    CenterT("Item Changes (Sorted):", row, colors.black, colors.white, "left", false)

    -- Sort the items by the most changed
    local sortedItems = sortChangedItems()

    -- Display the sorted items
    for _, item in ipairs(sortedItems) do
        row = row + 1
        if item.amount > 0 then
            CenterT(item.name .. " +" .. item.amount, row, colors.black, colors.green, "left", false) -- Added items in green
        else
            CenterT(item.name .. " " .. item.amount, row, colors.black, colors.red, "left", false) -- Removed items in red
        end
    end
end

-- Function to display graphs for total changes
function displayGraphs()
    local totalAdded = 0
    local totalRemoved = 0

    -- Calculate totals
    for _, change in pairs(changedItems) do
        if change > 0 then
            totalAdded = totalAdded + change
        else
            totalRemoved = totalRemoved - change -- Invert negative values for total removed
        end
    end

    -- Draw the graphs
    row = 2
    mon.clear()
    CenterT("Total Items Added: " .. totalAdded, row, colors.black, colors.green, "left", false)
    drawBarGraph(totalAdded, row + 1)

    row = row + 6
    CenterT("Total Items Removed: " .. totalRemoved, row, colors.black, colors.red, "left", false)
    drawBarGraph(totalRemoved, row + 1)
end

-- Function to prepare the monitor
function prepareMonitor()
    mon.clear()
    mon.setTextScale(0.5) -- Adjust text scale if necessary
    CenterT(label, 1, colors.black, colors.white, "head", false)
end

-- Utility function to draw a simple bar graph
function drawBarGraph(value, startY)
    local maxX, _ = mon.getSize()
    local barLength = math.min(value / 100, maxX - 4) -- Scale value for graph display
    mon.setBackgroundColor(colors.blue)
    for x = 2, math.floor(barLength) do
        mon.setCursorPos(x, startY)
        mon.write(" ")
    end
    mon.setBackgroundColor(colors.black)
end

-- Utility method to center text on the monitor
function CenterT(text, line, txtback, txtcolor, pos, clear)
    monX, monY = mon.getSize()
    mon.setTextColor(txtcolor)
    length = string.len(text)
    dif = math.floor(monX - length)
    x = math.floor(dif / 2)

    if pos == "head" then
        mon.setCursorPos(x + 1, line)
        mon.write(text)
    elseif pos == "left" then
        if clear then
            clearBox(2, 2 + length, line, line)
        end
        mon.setCursorPos(2, line)
        mon.write(text)
    elseif pos == "right" then
        if clear then
            clearBox(monX - length - 8, monX, line, line)
        end
        mon.setCursorPos(monX - length, line)
        mon.write(text)
    end
end

-- Clear a specific area on the monitor to prevent flickering
function clearBox(xMin, xMax, yMin, yMax)
    mon.setBackgroundColor(colors.black)
    for xPos = xMin, xMax, 1 do
        for yPos = yMin, yMax do
            mon.setCursorPos(xPos, yPos)
            mon.write(" ")
        end
    end
end

-- Main loop to alternate between displaying changes and graphs
function mainLoop()
    while true do
        calculateChanges() -- Update the list every minute

        if updateCycle == 1 then
            displayChangedItems()
        else
            displayGraphs()
        end

        updateCycle = 3 - updateCycle -- Alternate between 1 and 2
        sleep(10) -- Switch display every 10 seconds
    end
end

-- Prepare monitor and start the main loop
prepareMonitor()
readPreviousItems() -- Load previous items from file at startup
mainLoop()
