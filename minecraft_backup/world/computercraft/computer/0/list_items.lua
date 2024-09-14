---
--- Script to list all available items in the system
--- Made for CCTweaked & Advanced Peripherals integration
--- Created by not really bharath
--- DateTime: 9/11
---

label = "Items in System"

me = peripheral.find("meBridge") -- MeBridge
mon = peripheral.find("monitor") -- Monitor

function listItems()
    local items = me.listItems()
    if not items or #items == 0 then
        row = row + 1
        CenterT("No items in the system", row, colors.black, colors.red, "left", false)
        return
    end
    row = row + 1
    CenterT("Available Items:", row, colors.black, colors.white, "left", false)
    for _, item in pairs(items) do
        row = row + 1
        CenterT(item.displayName .. " x" .. item.amount, row, colors.black, colors.green, "left", false)
    end
end

function prepareMonitor()
    mon.clear()
    CenterT(label, 1, colors.black, colors.white, "head", false)
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

-- Main loop
prepareMonitor()

while true do
    row = 2
    listItems()
    sleep(3) -- Update every 3 seconds
end
