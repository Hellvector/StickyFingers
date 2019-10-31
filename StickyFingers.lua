-- Version 0.1      Prints all combat actions to chat.
-- Version 0.2      Only looks at successful casts made by the player.
-- Version 0.2.1    Also checks to see if the spell cast was Pick Pocket.
-- Version 0.3      Activate a switch when the player picks a pocket.
-- Version 0.3.1    Picked pocked switch is turned off when the player loots money
--                  or changes targets.
-- Version 0.4      Start tracking the money looted from pickpocketing.
-- Version 0.4.1    Session and lifetime totals are now calculated.
-- Version 0.4.2    Added formatting for the money amounts when they are printed.
-- Version 0.5      Added a check to see if the player is a Rogue, and unregister events if not.
-- Version 0.6      Added a slash command for interracting with the addon.
-- Version 0.6.1    Commented out the validation print commands throughout. All results moved to the slash command.
-- Version 0.7      Started character initialization to save the level and date on the first load.
-- Version 0.8      Ran into an issue with the latest Classic client not returning the Spell ID. Added a non-localized work around for now.
-- Version 0.8.1    Had some weird bugs causing the picked toggle to stay open indefinitely, resulting in massive computation errors.
-- Version 0.8.2    Last chance before making some MAJOR changes, additions, and a complete overhaul of the saved variables.
-- Version 0.9      Variables are now saved in a complex table system. Loot is tracked by level, and a record high is saved for each level as well.
--                  A process was also put in place to save player data from before v0.9 and implement it as best as possible into the new system.
-- Version 0.9.1    Implementing the tracking of looted items into the table.

local StickyFingers = CreateFrame("Frame")

-- Save the player GUID for spell checking.
local playerGUID = UnitGUID("player")
-- Save the player class for addon activation.
local playerClass, playerClassName = UnitClass("player")
-- Picked pocket check switch.
local picked = false
-- Player money used for reference.
local playerMoney = 0

function StickyFingers:updateMoney(pocketChange)
  -- If the table is currently empty, create a new entry.
  if StickyFingers:tableLength(StickyFingersLoot.money.level) == 0 then
    StickyFingers:newLevel()
  end
  -- Run the search loop.
  for i=1, StickyFingers:tableLength(StickyFingersLoot.money.level) do
    if StickyFingersLoot.money.level[i].playerLevel == UnitLevel("player") then
      StickyFingersLoot.money.level[i].total = StickyFingersLoot.money.level[i].total + pocketChange
      StickyFingersLoot.money.level[i].count = StickyFingersLoot.money.level[i].count + 1
      if pocketChange > StickyFingersLoot.money.level[i].max.amount then
        StickyFingersLoot.money.level[i].max.date = date("%m/%d/%y")
        --StickyFingersLoot.money.level.i.max.time =
        StickyFingersLoot.money.level[i].max.amount = pocketChange
        --StickyFingersLoot.money.level.i.max.unitName =
        --StickyFingersLoot.money.level.i.max.unitLevel =
        --StickyFingersLoot.money.level.i.max.zone =
        --StickyFingersLoot.money.level.i.max.x =
        --StickyFingersLoot.money.level.i.max.y =
      end
      print(GetCoinText(pocketChange).." recorded for lvl "..StickyFingersLoot.money.level[i].playerLevel..".")
      break
    -- If the end of the table is reached and no entry for the current level was found, create a new entry and reset the loop.
    elseif i == StickyFingers:tableLength(StickyFingersLoot.money.level) then
      StickyFingers:newLevel()
      i=1
    end
  end
end

-- Credit to GatherLite for this one! :D
function StickyFingers:tableLength(table)
  local count = 0
  if table then
    for _ in pairs(table) do
      count = count + 1
    end
  end
  return count
end

-- Create a new entry in the money.level table for the current level.
function StickyFingers:newLevel()
  table.insert(StickyFingersLoot.money.level, {
    playerLevel = UnitLevel("player"),
    total = 0,
    count = 0,
    max = {
      date = 0,
      time = 0,
      amount = 0,
      unitName = 0,
      unitLevel = 0,
      zone = 0,
      x = 0,
      y = 0,
    }
  })
end

-- Create a new entry in the items table for the looted item.
function StickyFingers:newItem(lootID, lootString, lootLink)
  table.insert(StickyFingersLoot.items, {
    itemID = lootID,
    itemString = lootString,
    itemLink = lootLink,
    count = 1
  })
  print("New entry: "..lootLink)
end

function StickyFingers:updateItems(lootID, lootString, lootLink)
  -- If the table is currently empty, create a new entry.
  if StickyFingers:tableLength(StickyFingersLoot.items) == 0 then
    StickyFingers:newItem(lootID, lootString, lootLink)
  else
  -- Run the search loop.
    for i=1, StickyFingers:tableLength(StickyFingersLoot.money.level) do
      if StickyFingersLoot.items[i].itemID == lootID then
        StickyFingersLoot.items[i].count = StickyFingersLoot.items[i].count + 1
        print("Updated entry: "..lootLink)
        break
        -- If the end of the table is reached and no entry for the current item was found, create a new entry.
      elseif i == StickyFingers:tableLength(StickyFingersLoot.items) then
        StickyFingers:newItem(lootID, lootString, lootLink)
      end
    end
  end
end

-- A local funtion will be used to sort out which even trigger has been fired.
local function eventHandler(self, event, ...)

  if event == "PLAYER_LOGIN" then
    -- Initialization message to verify the addon loaded.
    if playerClassName == "ROGUE" then
      DEFAULT_CHAT_FRAME:AddMessage("Sticky fingers leave empty pockets.")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Silly rabbit, StickyFingers is for Rogues!")
    end
  end

  if (event == "ADDON_LOADED" and playerClassName == "ROGUE") then
    local tempLoot = nil

    -- If saved variables from before v0.9 are found, save them temporarily in tempLoot{} so we can overhaul the saved variables.
    if StickyFingersLevelStarted ~= nil then
      tempLoot = {
        total = StickyFingersLoot,
        levelStarted = StickyFingersLevelStarted,
        dateStarted = StickyFingersDateStarted
      }
      StickyFingersLoot = nil
      StickyFingersLevelStarted = nil
      StickyFingersDateStarted = nil
    end

    -- If no information is found in the StickyFingersLoot table, create it.
    if StickyFingersLoot == nil then
      StickyFingersLoot = {
        dateStarted = date("%m/%d/%y"),
        levelStarted = UnitLevel("player"),
        money = {
          level = {}
        },
        items = {},
        config = {
          debug = false
        },
      };

      -- If information is found in tempLoot, insert it into the new table.
      if tempLoot ~= nil then
        StickyFingersLoot.oldLoot = tempLoot.total
        StickyFingersLoot.dateStarted = tempLoot.dateStarted
        StickyFingersLoot.levelStarted = tempLoot.levelStarted
        print("Old saved variables loaded into the new tables.")
      end
    end
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    -- Load in the standard COMBAT_LOG_EVENT_UNFILTERED parameters.
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    -- Check that the action was made by the player, and that it was a successful spell cast.
    if (sourceGUID == playerGUID and subevent == "SPELL_CAST_SUCCESS") then
      -- Load in the additional parameters for SPELL_CAST_SUCCESS.
      -- Retail:
      local spellId, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo())

      -- Classic:


      -- Verification message to confirm that a spell cast was registered.
      --print("You did "..spellName.." ID: "..spellId.." to "..destName.."!")

      -- Verify that the spell which was cast is Pick Pocket.
      if spellId == 921 or spellName == "Pick Pocket" then
        -- Check how much money the player has before looting.
        playerMoney = GetMoney()
        --print("Player has "..GetCoinText(playerMoney,", ")..".")
        --print("What has he got in HIS pocketses?")
        -- Set picked pocket switch to ON.
        picked = true
        --print("Picked is true because the player picked a pocket.")
        --print("Picked is actually "..(picked and 'true' or 'false')..".")
      end
    end
  end

  -- If the player loots money while the picked pocket switch is ON.
  --if (event == "PLAYER_MONEY") then
    --print("Player money has changed...")
  --end
  if event == "PLAYER_MONEY" then
    -- Find out how much money the player has after looting.
    --local newMoney = GetMoney()
    -- Subtract the old money amount to find the looted amount.
    --local pocketchange = (newMoney - playerMoney)
    -- Add the looted amount to the session total.
    --pickedMoney = (pickedMoney + pocketchange)
    -- Add the looted amount to the lifetime total.
    --StickyFingersLoot = (StickyFingersLoot + pocketchange)
    -- Increment the number of times picked.
    --StickyFingersTimesPicked = StickyFingersTimesPicked + 1
    -- Set picked pocket switch to OFF.
    --print("Money has changed hands...")
    --print("Player looted "..GetCoinTextureString(pocketchange).."!")
    --print("Player now has "..GetCoinText(newMoney,", ")..".")
    --print("Player has picked "..GetCoinText(pickedMoney,", ").." this session!")
    --print("Player has picked "..GetCoinText(StickyFingersLoot,", ").." in their life!")
    --print("Picked is false.")

    --Let's try this again, shall we. Version 0.8.1 trying to fix a weird bug.
    if picked == true then
      --picked = false
      --print("Picked is false because the player looted money.")
      local newMoney = GetMoney()
      --print("Player now has "..GetCoinText(newMoney,", ")..".")
      local pocketChange = (newMoney - playerMoney)
      --print("Player looted "..GetCoinText(pocketChange).."!")
      --local pickedMoney = (pickedMoney + pocketChange)
      --print("Player has picked "..GetCoinText(pickedMoney,", ").." this session!")
      StickyFingers:updateMoney(pocketChange)
      --print("Player has picked "..GetCoinText(StickyFingersLoot,", ").." in their life!")
    end
    --print("Picked is actually "..(picked and 'true' or 'false')..".")
  end

  -- If the player changes targets while the picked pocket switch is ON.
  if event == "PLAYER_TARGET_CHANGED" then
    --print("Player target has changed...")
    if picked == true then
      picked = false
      print("Picked is false because of a target change.")
    end
    --print("Picked is actually "..(picked and 'true' or 'false')..".")
  end
  --v0.8.1 Removing the enter combat fail clause. This will allow a late loot from the pick pocket to still be registered after entering combat.
  --Killing the mob will still cause the target to drop and close out the pick switch before the player can loot normal loot.
  --if event == "PLAYER_REGEN_DISABLED" then
    --print("Player regen disabled...")
    --if picked == true then
      --picked = false
      --print("Picked is false because the player entered combat.")
    --end
    --print("Picked is actually "..(picked and 'true' or 'false')..".")
  --end
  --if (event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED") then
    -- Thanks to Jinst!
    --if picked == true then
      -- Increment the number of failed attempts.
      --StickyFingersTimesFailed = StickyFingersTimesFailed + 1
      -- Set picked pocket switch to OFF.
      --picked = false
      --print("Picked is false.")
    --end
  --end

  -- Watch loot messages.
  if (event == "CHAT_MSG_LOOT" and picked == true) then
    --local lootMSGtext, lootMSGplayerName, lootMSGlanguageName, lootMSGchannelName, lootMSGplayerName2, lootMSGspecialFlags, lootMSGzoneChannelID, lootMSGchannelIndex, lootMSGchannelBaseName, lootMSGunused, lootMSGlineID, lootMSGguid, lootMSGbnSenderID, lootMSGisMobile, lootMSGisSubtitle, lootMSGhideSenderInLetterbox, lootMSGsupressRaidIcons = ...
    local lootstring, _, _, _, player = ...
    local itemLink = string.match(lootstring, "|%x+|Hitem:.-|h.-|h|r")
    local itemString = string.match(itemLink, "item[%-?%d:]+")
    local itemID = string.match(itemLink, "item:(%d+)")
    print("Looted something!")
    --print(lootMSGtext.." "..lootMSGplayerName.." "..lootMSGlanguageName.." "..lootMSGchannelName.." "..lootMSGplayerName2.." "..lootMSGspecialFlags.." "..lootMSGzoneChannelID.." "..lootMSGchannelIndex.." "..lootMSGchannelBaseName.." "..lootMSGunused.." "..lootMSGlineID.." "..lootMSGguid.." "..lootMSGbnSenderID.." "..lootMSGisMobile.." "..lootMSGisSubtitle.." "..lootMSGhideSenderInLetterbox.." "..lootMSGsupressRaidIcons)
    print(lootstring)
    print(itemLink)
    print(itemString)
    print(itemID)
    StickyFingers:updateItems(itemID, itemString, itemLink)
  end

end

-- Slash command handler for displaying the player's statistics.
function StickyFingersSlashCommand(msg)
  if msg == "" then
    if pickedMoney > 0 then
      print("You has picked "..GetCoinText(pickedMoney,", ").." this session!")
    end
    if StickyFingersLoot == 0 then
      print("You have not picked any pockets!")
    else
      print("You have picked "..GetCoinText(StickyFingersLoot,", ").." since lvl "..StickyFingersLevelStarted.." on "..StickyFingersDateStarted.."!")
      -- Below is an over complicated way to get similar results, and it may be necessary if GetCoinText doesn't work in Classic.
      --print(("Player has picket %d Gold, %d Silver, %d Copper in their life!"):format(StickyFingersLoot / 100 / 100, (StickyFingersLoot / 100) % 100, StickyFingersLoot % 100))
    end
  elseif msg == "items" then
    for i,v in ipairs(StickyFingersItemsLooted) do
      print("You have looted "..v[4].." "..v[2].."!")
    end
  elseif msg == "debug" then
    if stickyDebug == false then
      stickyDebug = true
      print("StickyFingers debug mode enabled.")
    elseif stickyDebug == true then
      stickyDebug = false
      print("StickyFingers debug mode disabled.")
    end
  else
    print("StickyFingers does not recognize ["..msg.."] as a valid command.")
  end
end




StickyFingers:RegisterEvent("PLAYER_LOGIN")
StickyFingers:RegisterEvent("ADDON_LOADED")
if playerClassName == "ROGUE" then
  StickyFingers:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  StickyFingers:RegisterEvent("PLAYER_MONEY")
  StickyFingers:RegisterEvent("PLAYER_TARGET_CHANGED")
  StickyFingers:RegisterEvent("PLAYER_REGEN_DISABLED")
  StickyFingers:RegisterEvent("CHAT_MSG_LOOT")
end
StickyFingers:SetScript("OnEvent", eventHandler)

-- Establish the accepted slash commands.
SLASH_STICKYFINGERS1, SLASH_STICKYFINGERS2, SLASH_STICKYFINGERS3 = "/stickyfingers", "/sticky", "/sf"
SlashCmdList["STICKYFINGERS"] = StickyFingersSlashCommand
