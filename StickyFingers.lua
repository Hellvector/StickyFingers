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


-- Debugging text toggle.
local stickyDebug = false
-- Save the player GUID for spell checking.
local playerGUID = UnitGUID("player")
-- Save the player class for addon activation.
local playerClass, playerClassName = UnitClass("player")
-- Picked pocket check switch.
local picked = false
-- Player money used for reference.
local playerMoney = 0
-- Amount picked this session.
local pickedMoney = 0

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

  if ((event == "ADDON_LOADED" and playerClassName == "ROGUE") and StickyFingersLevelStarted == nil) then
    -- If no saved lifetime loot value exists, initialize at 0.
    StickyFingersLoot = 0
    StickyFingersLevelStarted = UnitLevel("player")
    StickyFingersDateStarted = date("%m/%d/%y")
    StickyFingersTimesPicked = 0
    StickyFingersTimesFailed = 0
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
        print("Player has "..GetCoinText(playerMoney,", ")..".")
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
      picked = false
      --print("Picked is false because the player looted money.")
      local newMoney = GetMoney()
      --print("Player now has "..GetCoinText(newMoney,", ")..".")
      local pocketchange = (newMoney - playerMoney)
      --print("Player looted "..GetCoinText(pocketchange).."!")
      pickedMoney = (pickedMoney + pocketchange)
      --print("Player has picked "..GetCoinText(pickedMoney,", ").." this session!")
      StickyFingersLoot = (StickyFingersLoot + pocketchange)
      --print("Player has picked "..GetCoinText(StickyFingersLoot,", ").." in their life!")
    end
    --print("Picked is actually "..(picked and 'true' or 'false')..".")
  end

  -- If the player changes targets while the picked pocket switch is ON.
  if event == "PLAYER_TARGET_CHANGED" then
    --print("Player target has changed...")
    if picked == true then
      picked = false
      --print("Picked is false because of a target change.")
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

-- Items looted test area.
local StickyFingersItemsLooted = {
  {5428, "[Homemade Cherry Pie]", 1, 1,}
}



local StickyFingers = CreateFrame("Frame")
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
