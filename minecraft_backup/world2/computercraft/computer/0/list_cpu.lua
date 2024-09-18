-- list_cpus.lua
local peripheral = require("peripheral")

-- Get the AE2 interface (replace "ae2" with your actual peripheral name if needed)
local ae2 = peripheral.find("meBridge")

if not ae2 then
    print("ME system not found!")
    return
end

-- Get all crafting CPUs
local cpus = ae2.getCraftingCPUs()

print("Crafting CPUs:")
for _, cpu in pairs(cpus) do
    print(cpu.name .. " (Is Busy: " .. tostring(cpu.isBusy) .. ")")
end

-- Get current crafting jobs
local crafts = ae2.getCraftingJobs()

print("\nCurrent Crafts:")
for _, craft in pairs(crafts) do
    print("Item: " .. craft.item.displayName .. ", Remaining: " .. craft.remaining)
end
