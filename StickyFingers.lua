-- Version 0.1    Prints all combat actions to chat.
-- Version 0.2    Only looks at successful casts made by the player.
-- Version 0.21   Also checks to see if the spell cast was Pick Pocket.
-- Version 0.3    Activate a switch when the player picks a pocket.
-- Version 0.31   Picked pocked switch is turned off when the player loots money
--                or changes targets.
-- Version 0.4    Start tracking the money looted from pickpocketing.
-- Version 0.41   Session and lifetime totals are now calculated.
-- Version 0.42   Added formatting for the money amounts when they are printed.
-- Version 0.5    Add a check to see if the player is a Rogue, and unregister events if not.

-- Save the player GUID for spell checking.
local playerGUID = UnitGUID("player")
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
    DEFAULT_CHAT_FRAME:AddMessage("Sticky fingers leave empty pockets.")
  end

  if (event == "ADDON_LOADED" and StickyFingersLoot == nil) then
    -- If no saved lifetime loot value exists, initialize at 0.
    StickyFingersLoot = 0
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    -- Load in the standard COMBAT_LOG_EVENT_UNFILTERED parameters.
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    -- Check that the action was made by the player, and that it was a successful spell cast.
    if (sourceGUID == playerGUID and subevent == "SPELL_CAST_SUCCESS") then
      -- Load in the additional parameters for SPELL_CAST_SUCCESS.
      local spellId, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo())

      -- Verification message to confirm that a spell cast was registered.
      print("You did "..spellName.." to "..destName.."!")

      -- Verify that the spell which was cast is Pick Pocket.
      if spellId == 921 then
        -- Check how much money the player has before looting.
        playerMoney = GetMoney()
        print("Player has "..GetCoinText(playerMoney,", ")..".")
        print("What has he got in HIS pocketses?")
        -- Set picked pocket switch to ON.
        picked = true
        print("Picked is true.")
      end

    end
  end

  -- If the player loots money while the picked pocket switch is ON.
  if (event == "PLAYER_MONEY" and picked == true) then
    -- Find out how much money the player has after looting.
    local newMoney = GetMoney()
    -- Subtract the old money amount to find the looted amount.
    local pocketchange = (newMoney - playerMoney)
    -- Add the looted amount to the session total.
    pickedMoney = (pickedMoney + pocketchange)
    -- Add the looted amount to the lifetime total.
    StickyFingersLoot = (StickyFingersLoot + pocketchange)
    -- Set picked pocket switch to OFF.
    picked = false
    print("Money has changed hands...")
    print("Player looted "..GetCoinTextureString(pocketchange).."!")
    print("Player now has "..GetCoinText(newMoney,", ")..".")
    print("Player has picked "..GetCoinText(pickedMoney,", ").." this session!")
    print("Player has picked "..GetCoinText(StickyFingersLoot,", ").." in their life!")
    -- Below is an over complicated way to get similar results, and it may be necessary if GetCoinText doesn't work in Classic.
    --print(("Player has picket %d Gold, %d Silver, %d Copper in their life!"):format(StickyFingersLoot / 100 / 100, (StickyFingersLoot / 100) % 100, StickyFingersLoot % 100))
    print("Picked is false.")
  end

  -- If the player changes targets or enters combat while the picked pocket switch is ON.
  if ((event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED") and picked == true) then
    -- Thanks to Jinst!
    -- Set picked pocket switch to OFF.
    picked = false
    print("Picked is false.")
  end

end

local StickyFingers = CreateFrame("Frame")
StickyFingers:RegisterEvent("PLAYER_LOGIN")
StickyFingers:RegisterEvent("ADDON_LOADED")
StickyFingers:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
StickyFingers:RegisterEvent("PLAYER_MONEY")
StickyFingers:RegisterEvent("PLAYER_TARGET_CHANGED")
StickyFingers:RegisterEvent("PLAYER_REGEN_DISABLED")
StickyFingers:SetScript("OnEvent", eventHandler)
