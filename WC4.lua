-- Function to draw a line for box formatting
function drawLine()
    return "=============================="
end

-- Function to format title with a box
function boxTitle(title)
    return drawLine() .. "\n" ..
           "         " .. title .. "\n" ..
           drawLine()
end

-- Main menu for WC4 Unit Modifier
function mainMenu()
    local menuText = boxTitle("⚔️  WC4 Unit Modifier Menu ⚔️")
    local menu = gg.choice({
        "🪖 Infantry",
        "🛡️ Tank",
        "🎯 Artillery",
        "♻️ Restore Value"
    }, nil, menuText)

    if menu == 1 then
        infantryMenu()
    elseif menu == 2 then
        tankMenu()
    elseif menu == 3 then
        artilleryMenu()
    elseif menu == 4 then
        restoreFromBackup()
    elseif menu == nil then
        gg.toast("Menu cancelled.")
        os.exit()
    end
end

-- Submenu for Infantry category
function infantryMenu()
    local menuText = boxTitle("🪖 Infantry Submenu")
    local menu = gg.choice({
        " Light Infantry",
        " Assault Infantry",
        " Motorized Infantry",
        " Mechanized Infantry"
    }, nil, menuText)

    if menu == 1 then
        modifyUnit("Light Infantry", "80D;0D;0D::9", {-14, 4, 8})
    elseif menu == 2 then
        modifyUnit("Assault Infantry", "320;80;8::9", {-14, 4, 8})
    elseif menu == 3 then
        modifyUnit("Motorized Infantry", "200;60;6::9", {-14, 4, 8})
    elseif menu == 4 then
        modifyUnit("Mechanized Infantry", "400;100;10::9", {-14, 4, 8})
    elseif menu == nil then
        mainMenu()
    end
end

-- Tank Category
function tankMenu()
    local menuText = boxTitle("🛡️ Tank Submenu")
    local menu = gg.choice({
        " Armored Car",
        " Light Tank",
        " Medium Tank",
        " Heavy Tank",
        " Super Tank"
    }, nil, menuText)

    if menu == 1 then
        modifyUnit("Armored Car", "150;30;5::9", {-14, 4, 8})
    elseif menu == 2 then
        modifyUnit("Light Tank", "300;60;6::9", {-14, 4, 8})
    elseif menu == 3 then
        modifyUnit("Medium Tank", "500;100;10::9", {-14, 4, 8})
    elseif menu == 4 then
        modifyUnit("Heavy Tank", "750;150;15::9", {-14, 4, 8})
    elseif menu == 5 then
        modifyUnit("Super Tank", "1000;200;20::9", {-14, 4, 8})
    elseif menu == nil then
        mainMenu()
    end
end

-- Submenu for Artillery category
function artilleryMenu()
    local menuText = boxTitle("🎯 Artillery Submenu")
    local menu = gg.choice({
        " Field Artillery",
        " Howitzer",
        " Rocket Artillery",
        " Super Artillery"
    }, nil, menuText)

    if menu == 1 then
        modifyUnit("Field Artillery", "180;40;5::9", {-14, 4, 8})
    elseif menu == 2 then
        modifyUnit("Howitzer", "300;70;7::9", {-14, 4, 8})
    elseif menu == 3 then
        modifyUnit("Rocket Artillery", "245;45;8::9", {-14, 4, 8})
    elseif menu == 4 then
        modifyUnit("Super Artillery", "600;120;12::9", {-14, 4, 8})
    elseif menu == nil then
        mainMenu()
    end
end

-- Verify memory offsets
function verifyOffsets(addr1, addr2, addr3, expectedOffsets)
    local offset1 = addr2 - addr1
    local offset2 = addr3 - addr1
    return (offset1 == expectedOffsets[2] and offset2 == expectedOffsets[3])
end

-- Test modification to verify it's the correct address
function testModification(group, expectedOffsets)
    -- Save original values
    local originalValues = {}
    for i, v in ipairs(group) do
        originalValues[i] = {address = v.address, value = v.value, flags = gg.TYPE_DWORD}
    end

    -- Apply test modification
    local testValue = 99999
    local modified = {
        {address = group[1].address, value = testValue, flags = gg.TYPE_DWORD},
        {address = group[2].address, value = testValue, flags = gg.TYPE_DWORD},
        {address = group[3].address, value = testValue, flags = gg.TYPE_DWORD}
    }
    gg.setValues(modified)

    -- Verify the modification
    gg.clearResults()
    gg.searchNumber(testValue, gg.TYPE_DWORD)
    local verifyResults = gg.getResults(3)
    local success = true

    if #verifyResults < 3 then
        success = false
    else
        -- Check if all three addresses were modified
        local foundAddresses = {}
        for _, v in ipairs(verifyResults) do
            foundAddresses[v.address] = true
        end
        
        if not (foundAddresses[group[1].address] and 
                foundAddresses[group[2].address] and 
                foundAddresses[group[3].address]) then
            success = false
        end
    end

    -- Restore original values
    gg.setValues(originalValues)
    gg.clearResults()

    return success
end

-- Function to modify unit values with auto-verification
function modifyUnit(name, searchPattern, expectedOffsets)
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber(searchPattern, gg.TYPE_DWORD)

    local results = gg.getResults(100)
    if #results < 3 then
        gg.alert(name .. ":\n❌ Not enough values found! Only " .. #results .. " match(es).")
        return
    end

    local validGroups = {}
    for i = 1, #results - 2 do
        local addr1 = results[i].address
        local addr2 = results[i + 1].address
        local addr3 = results[i + 2].address

        if verifyOffsets(addr1, addr2, addr3, expectedOffsets) then
            table.insert(validGroups, {
                { address = addr1, value = results[i].value },
                { address = addr2, value = results[i + 1].value },
                { address = addr3, value = results[i + 2].value }
            })
        end
    end

    if #validGroups == 0 then
        gg.alert(name .. ":\n❌ No valid memory groups found with correct offsets!")
        return
    end

    -- Auto-verification process for multiple matches
    local verifiedGroup = nil
    if #validGroups > 1 then
        gg.toast("🔍 Found "..#validGroups.." groups. Verifying...")
        
        for i, group in ipairs(validGroups) do
            if testModification(group, expectedOffsets) then
                verifiedGroup = group
                gg.toast("✅ Verified group "..i.." is correct")
                break
            else
                gg.toast("❌ Group "..i.." failed verification")
            end
        end
        
        if not verifiedGroup then
            gg.alert(name..":\n❌ Couldn't verify any group automatically!\nTry manual selection.")
            return manualGroupSelection(name, validGroups, expectedOffsets)
        end
    else
        verifiedGroup = validGroups[1]
    end

    -- Save to backup file
    local dir = "/storage/emulated/0/Documents/"
    local savePath = dir .. name:gsub(" ", "_") .. "_cost.txt"

    local file = io.open(savePath, "w")
    if file then
        file:write(string.format("Base Address: 0x%X\n", verifiedGroup[1].address))
        file:write(string.format("%d at +0 (0x%X)\n", verifiedGroup[1].value, verifiedGroup[1].address))
        file:write(string.format("%d at +4 (0x%X)\n", verifiedGroup[2].value, verifiedGroup[2].address))
        file:write(string.format("%d at +8 (0x%X)\n", verifiedGroup[3].value, verifiedGroup[3].address))
        file:close()
        gg.toast("✅ Backup saved: " .. savePath)
    else
        gg.alert("❌ Failed to save backup to:\n" .. savePath)
    end

    local modified = {
        { address = verifiedGroup[1].address, value = -9999, flags = gg.TYPE_DWORD },
        { address = verifiedGroup[2].address, value = -9999, flags = gg.TYPE_DWORD },
        { address = verifiedGroup[3].address, value = -9999, flags = gg.TYPE_DWORD }
    }
    gg.setValues(modified)

    gg.alert("✅ " .. name .. " values modified successfully!\nModified addresses:\n0x" ..
        string.format("%X", verifiedGroup[1].address) .. "\n0x" ..
        string.format("%X", verifiedGroup[2].address) .. "\n0x" ..
        string.format("%X", verifiedGroup[3].address))
end

function manualGroupSelection(name, groups, expectedOffsets)
    local choices = {}
    for i, group in ipairs(groups) do
        table.insert(choices, string.format("Group %d:\n0x%X\n0x%X\n0x%X",
            i, group[1].address, group[2].address, group[3].address))
    end

    local choice = gg.choice(choices, nil, name .. ":\nMultiple matches found. Select group to modify:")
    if not choice then
        gg.alert("❗ Operation cancelled.")
        return nil
    end
    
    return groups[choice]
end

function restoreFromBackup()
    gg.setVisible(false)
    gg.alert("♻️ Unit Value Restoration Tool")

    local backupFile = gg.prompt(
        {"Select backup file to restore"},
        {"/sdcard/Documents/"},
        {"file"}
    )

    if not backupFile or not backupFile[1] then
        gg.alert("❌ Restoration cancelled")
        return
    end

    local file, err = io.open(backupFile[1], "r")
    if not file then
        gg.alert("❌ Failed to open backup file:\n" .. (err or "Unknown error"))
        return
    end

    local restoreData = {}
    local baseAddress

    for line in file:lines() do
        if line:match("Base Address:") then
            baseAddress = tonumber(line:match("0x(%x+)"), 16)
        elseif line:match(" at ") then
            local valueStr = line:match("^(%-?%d+)")
            local addressStr = line:match("0x(%x+)")
            if valueStr and addressStr then
                table.insert(restoreData, {
                    address = tonumber(addressStr, 16),
                    value = tonumber(valueStr),
                    flags = gg.TYPE_DWORD
                })
            end
        end
    end
    file:close()

    if #restoreData ~= 3 or not baseAddress then
        gg.alert("❌ Invalid backup file format!\nExpected 3 values with base address")
        return
    end

    gg.toast("🔄 Restoring values...")
    local success, err = pcall(gg.setValues, restoreData)
    if not success then
        gg.alert("❌ Restoration failed:\n" .. (err or "Unknown error"))
        return
    end

    local verified = 0
    gg.clearResults()
    for _, data in ipairs(restoreData) do
        gg.searchNumber(data.value, gg.TYPE_DWORD, false, nil, data.address, data.address + 4)
        if gg.getResultsCount() > 0 then
            verified = verified + 1
        end
        gg.clearResults()
    end

    local resultMsg = string.format(
        "Restoration Results (%d/3):\n\n" ..
        "0x%X → %d\n" ..
        "0x%X → %d\n" ..
        "0x%X → %d",
        verified,
        restoreData[1].address, restoreData[1].value,
        restoreData[2].address, restoreData[2].value,
        restoreData[3].address, restoreData[3].value
    )

    if verified == 3 then
        gg.alert("✅ Restoration Complete!\n\n" .. resultMsg)
    else
        gg.alert("⚠ Partial Success\n\n" .. resultMsg)
    end

    gg.setVisible(true)
end

-- Run the script
mainMenu()
