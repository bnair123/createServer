---
--- Script to list added and removed items in the system with graphs
--- Made for CCTweaked & Advanced Peripherals integration
---

label = "Items in System"

me = peripheral.find("meBridge") -- MeBridge
mon = peripheral.find("monitor") -- Monitor

-- Variables to store item changes
prevItems = {}
addedItems = {}
removedItems = {}
updateCycle = 1 -- 1 for list, 2 for graphs

-- Function to compare and track item changes
function trackChanges()
    local currentItems = me.listItems()
    local newAdded = {}
    local newRemoved = {}

    -- Create a map of current item quantities
    local currentMap = {}
    for _, item in pairs(currentItems) do
        currentMap[item.name] = item.amount
    end

    -- Check for added or removed items
    for _, prevItem in pairs(prevItems) do
        if not currentMap[prevItem.name] then
            -- Item was removed
            newRemoved[prevItem.name] = prevItem.amount
        elseif currentMap[prevItem.name] < prevItem.amount then
            -- Item count decreased
            newRemoved[prevItem.name] = prevItem.amount - currentMap[prevItem.name]
        elseif currentMap[prevItem.name] > prevItem.amount then
            -- Item count increased
            newAdded[prevItem.name] = currentMap[prevItem.name] - prevItem.amount
        end
    end

    -- Check for newly added items
    for _, currentItem in pairs(currentItems) do
        if not prevItems[currentItem.name] then
            newAdded[currentItem.name] = currentItem.amount
        end
    end

    addedItems = newAdded
    removedItems = newRemoved
    prevItems = currentItems
end

-- Function to display lists of added and removed items
function displayLists()
    row = 2
    mon.clear()
    CenterT("Items Added:", row, colors.black, colors.white, "left", false)
    for item, count in pairs(addedItems) do
        row = row + 1
        CenterT(item .. " x" .. count, row, colors.black, colors.green, "left", false)
    end

    row = row + 2
    CenterT("Items Removed:", row, colors.black, colors.white, "left", false)
    for item, count in pairs(removedItems) do
        row = row + 1
        CenterT(item .. " x" .. count, row, colors.black, colors.red, "left", false)
    end
end

-- Function to display graphs for total item count, added, and removed items
function displayGraphs()
    local totalItems = 0
    local totalAdded = 0
    local totalRemoved = 0

    -- Calculate total item count
    local currentItems = me.listItems()
    for _, item in pairs(currentItems) do
        totalItems = totalItems + item.amount
    end

    -- Calculate total added and removed
    for _, count in pairs(addedItems) do
        totalAdded = totalAdded + count
    end
    for _, count in pairs(removedItems) do
        totalRemoved = totalRemoved + count
    end

    -- Draw the graphs
    row = 2
    mon.clear()
    CenterT("Total Item Count: " .. totalItems, row, colors.black, colors.white, "left", false)
    drawBarGraph(totalItems, 3)

    row = row + 6
    CenterT("Total Items Added: " .. totalAdded, row, colors.black, colors.green, "left", false)
    drawBarGraph(totalAdded, row + 1)

    row = row + 6
    CenterT("Total Items Removed: " .. totalRemoved, row, colors.black, colors.red, "left", false)
    drawBarGraph(totalRemoved, row + 1)
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

-- Main loop to alternate between displaying lists and graphs
function mainLoop()
    while true do
        trackChanges()

        if updateCycle == 1 then
            displayLists()
        else
            displayGraphs()
        end

        updateCycle = 3 - updateCycle -- Alternate between 1 and 2
        sleep(60) -- Update every 60 seconds
    end
end

-- Prepare monitor and start the main loop
prepareMonitor()
mainLoop()
